local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Dependencies
local DataService = require(script.Parent.DataService)
local GameConstants = require(ReplicatedStorage.Configs.GameConstants)
-- Point to Classes folder. Argon usually maps src/Server/Classes -> ServerScriptService.Classes
local BrainrotItem = require(script.Parent.Parent.Classes.BrainrotItem) 

-- Lazy Load
local TycoonService = nil 

local MarketService = {}
MarketService.ActiveListings = {} -- { ListingId = { SellerUserId = 123, Price = 100, Item = {...} } }

function MarketService:Init()
    local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
    
    -- 1. Quick Sell
    local sellFunc = remotesFolder:FindFirstChild(GameConstants.Events.QUICK_SELL)
    if not sellFunc then
        sellFunc = Instance.new("RemoteFunction")
        sellFunc.Name = GameConstants.Events.QUICK_SELL
        sellFunc.Parent = remotesFolder
    end
    sellFunc.OnServerInvoke = function(player, itemUUID) return self:QuickSell(player, itemUUID) end
    
    -- 2. Post Listing
    local postFunc = remotesFolder:FindFirstChild(GameConstants.Events.POST_LISTING)
    if not postFunc then
        postFunc = Instance.new("RemoteFunction")
        postFunc.Name = GameConstants.Events.POST_LISTING
        postFunc.Parent = remotesFolder
    end
    postFunc.OnServerInvoke = function(player, itemUUID, price) return self:PostListing(player, itemUUID, price) end
    
    -- 3. Buy Listing
    local buyFunc = remotesFolder:FindFirstChild(GameConstants.Events.BUY_LISTING)
    if not buyFunc then
        buyFunc = Instance.new("RemoteFunction")
        buyFunc.Name = GameConstants.Events.BUY_LISTING
        buyFunc.Parent = remotesFolder
    end
    buyFunc.OnServerInvoke = function(player, listingId) return self:BuyListing(player, listingId) end

    -- 4. Market Data Sync
    local refreshEvent = remotesFolder:FindFirstChild(GameConstants.Events.REFRESH_MARKET)
    if not refreshEvent then
        refreshEvent = Instance.new("RemoteEvent")
        refreshEvent.Name = GameConstants.Events.REFRESH_MARKET
        refreshEvent.Parent = remotesFolder
    end
end

function MarketService:Start()
    TycoonService = require(script.Parent.TycoonService)
    
    -- Sync market to new players
    Players.PlayerAdded:Connect(function(player)
        task.wait(2) -- Wait for load
        self:SyncMarket(player)
    end)
    
    -- [NEW] Start Server Injection Loop (Money Sink)
    task.spawn(function()
        while true do
            task.wait(GameConstants.INJECTION_INTERVAL or 300)
            self:InjectServerItem()
        end
    end)
    
    print("   -> MarketService Started (P2P + Injection Active)")
end

-- ==========================================
-- SERVER INJECTION (MONEY SINK)
-- ==========================================

function MarketService:InjectServerItem()
    -- 1. Generate High Tier Item
    local newItemObject = BrainrotItem.new() 
    local itemData = newItemObject.Data
    
    -- 2. Mark up the price (2x to 5x value)
    local markup = math.random(20, 50) / 10 
    local listingPrice = math.floor(itemData.FloorPrice * markup)
    
    -- 3. Create Fake Listing
    local listingId = HttpService:GenerateGUID(false)
    self.ActiveListings[listingId] = {
        Id = listingId,
        SellerUserId = GameConstants.SYSTEM_USER_ID or -1,
        SellerName = "SYSTEM (High Tier)",
        Price = listingPrice,
        Item = itemData,
        Timestamp = os.time()
    }
    
    self:SyncMarket()
    print(string.format("💉 INJECTION: System listed %s for $%d", itemData.Model, listingPrice))
end

-- ==========================================
-- P2P TRADING LOGIC
-- ==========================================

function MarketService:PostListing(player, itemUUID, price)
    -- Validation
    if type(price) ~= "number" or price <= 0 then return { Success = false, Msg = "Invalid Price" } end
    
    local profile = DataService:GetProfile(player)
    if not profile then return false end
    
    -- Find Item
    local itemIndex, itemData = self:FindItem(profile.Data.Inventory, itemUUID)
    if not itemData then return { Success = false, Msg = "Item not found" } end
    
    -- Check Shelves (Remove if placed)
    for shelfIndex, placedUUID in pairs(profile.Data.ShelfLayout) do
        if placedUUID == itemUUID then
            if TycoonService then TycoonService:RemoveItem(player, tonumber(shelfIndex)) end
            profile.Data.ShelfLayout[shelfIndex] = nil
            break
        end
    end
    
    -- ESCROW: Remove from Inventory
    table.remove(profile.Data.Inventory, itemIndex)
    
    -- Create Listing
    local listingId = HttpService:GenerateGUID(false)
    self.ActiveListings[listingId] = {
        Id = listingId,
        SellerUserId = player.UserId,
        SellerName = player.Name,
        Price = price,
        Item = itemData,
        Timestamp = os.time()
    }
    
    print(player.Name .. " listed " .. itemData.Model .. " for $" .. price)
    self:SyncMarket()
    
    return { Success = true }
end

function MarketService:BuyListing(buyer, listingId)
    local listing = self.ActiveListings[listingId]
    if not listing then return { Success = false, Msg = "Listing no longer available" } end
    
    -- Prevent buying own item
    if listing.SellerUserId == buyer.UserId then return { Success = false, Msg = "Cannot buy your own item" } end
    
    local buyerProfile = DataService:GetProfile(buyer)
    if not buyerProfile then return false end
    
    -- 1. Check Funds
    if buyerProfile.Data.RizzCoins < listing.Price then
        return { Success = false, Msg = "Not enough Rizz Coins" }
    end
    
    -- 2. Handle Seller (Real Player vs System)
    local isSystem = (listing.SellerUserId == (GameConstants.SYSTEM_USER_ID or -1))
    local seller = nil
    
    if not isSystem then
        seller = Players:GetPlayerByUserId(listing.SellerUserId)
        if not seller then
            return { Success = false, Msg = "Seller is offline (Transaction cancelled)" }
        end
    end
    
    -- 3. EXECUTE TRANSACTION
    
    -- A. Deduct from Buyer
    buyerProfile.Data.RizzCoins -= listing.Price
    table.insert(buyerProfile.Data.Inventory, listing.Item)
    
    -- B. Pay Seller (Only if Real Player)
    if not isSystem and seller then
        local sellerProfile = DataService:GetProfile(seller)
        if sellerProfile then
            sellerProfile.Data.RizzCoins += listing.Price
            seller:SetAttribute("RizzCoins", sellerProfile.Data.RizzCoins)
            print("💰 " .. buyer.Name .. " paid $" .. listing.Price .. " to " .. seller.Name)
        end
    else
        print("🔥 MONEY SINK: " .. buyer.Name .. " paid $" .. listing.Price .. " to Server. Money destroyed.")
    end
    
    -- 4. Clean Up
    self.ActiveListings[listingId] = nil
    self:SyncMarket()
    
    return { Success = true }
end

function MarketService:SyncMarket(specificPlayer)
    -- Convert dictionary to array for Network
    local marketArray = {}
    for _, listing in pairs(self.ActiveListings) do
        table.insert(marketArray, listing)
    end
    
    local remote = ReplicatedStorage.Remotes:FindFirstChild(GameConstants.Events.REFRESH_MARKET)
    if remote then
        if specificPlayer then
            remote:FireClient(specificPlayer, marketArray)
        else
            remote:FireAllClients(marketArray)
        end
    end
end

-- ==========================================
-- QUICK SELL LOGIC
-- ==========================================

function MarketService:QuickSell(player, itemUUID)
    local profile = DataService:GetProfile(player)
    if not profile then return false end
    
    local itemIndex, itemData = self:FindItem(profile.Data.Inventory, itemUUID)
    if not itemData then return false end
    
    -- Remove from Shelf if active
    for shelfIndex, placedUUID in pairs(profile.Data.ShelfLayout) do
        if placedUUID == itemUUID then
            if TycoonService then TycoonService:RemoveItem(player, tonumber(shelfIndex)) end
            profile.Data.ShelfLayout[shelfIndex] = nil
            break
        end
    end
    
    -- Transaction
    local sellValue = math.floor(itemData.FloorPrice * GameConstants.QUICK_SELL_PERCENT)
    profile.Data.RizzCoins += sellValue
    table.remove(profile.Data.Inventory, itemIndex)
    
    -- Update Client
    player:SetAttribute("RizzCoins", profile.Data.RizzCoins)
    
    return { Success = true, SoldAmount = sellValue }
end

-- Helper
function MarketService:FindItem(inventory, uuid)
    for i, item in ipairs(inventory) do
        if item.UUID == uuid then return i, item end
    end
    return nil, nil
end

return MarketService