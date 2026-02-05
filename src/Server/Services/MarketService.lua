local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MemoryStoreService = game:GetService("MemoryStoreService")
local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService") -- [NEW] Required for Cross-Server

local NetFolder = ReplicatedStorage:WaitForChild("Net")
local Remotes = require(NetFolder:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))

-- CONFIG
local MarketQueue = MemoryStoreService:GetSortedMap("GlobalMarket_Final_V5") -- Bumped version to V4 for safety
local EXPIRATION = 3600 
local MARKET_TOPIC = "GlobalMarketTransaction" -- [NEW] Topic name

local MarketService = {}

local GetMarketRF = Remotes.GetRemoteFunction("GetMarketData")
local GetPlayerListingsRF = Remotes.GetRemoteFunction("GetPlayerListings")
local BuyItemRF = Remotes.GetRemoteFunction("BuyItem")
local RemoveListingRF = Remotes.GetRemoteFunction("RemoveListing")
local ListMarketRF = Remotes.GetRemoteFunction("ListOnMarket")

-- =============================================
-- 1. HELPER: HANDLE SELLER DATA (Local or Cross-Server)
-- =============================================
function MarketService.FinalizeSellerData(sellerId, listingId, price)
    local seller = Players:GetPlayerByUserId(sellerId)
    
    if seller then
        print("[Market] Seller found in this server. Updating data...")
        -- 1. Give Money
        DataService.AdjustCurrency(seller, price)
        
        -- 2. Remove Item from their 'My Listings' (The fix for the bug)
        local profile = DataService.GetProfile(seller)
        if profile then
            local foundIndex = nil
            for i, item in ipairs(profile.Data.MarketList) do
                if item.ListingId == listingId then
                    foundIndex = i
                    break
                end
            end
            
            if foundIndex then
                table.remove(profile.Data.MarketList, foundIndex)
                print("[Market] Item removed from Seller's MarketList.")
            end
        end
        
        -- Optional: Notification
        -- Remotes.Notify:FireClient(seller, "Item Sold!", "You earned $"..price)
        return true -- handled online
    end
    
    return false -- seller not in this server
end

-- =============================================
-- 2. CORE FUNCTIONS
-- =============================================

function MarketService.GetGlobalListings()
    local items = {}
    local success, result = pcall(function()
        return MarketQueue:GetRangeAsync(Enum.SortDirection.Ascending, 100)
    end)
    
    if success and result then
        for _, entry in ipairs(result) do
            if entry.value then table.insert(items, entry.value) end
        end
    end
    return items
end

function MarketService.ListOnMarket(player, itemId, price)
    local profile = DataService.GetProfile(player)
    if not profile then return {Success = false, Msg = "Loading..."} end
    if price <= 0 then return {Success = false, Msg = "Invalid Price"} end

    local inventory = profile.Data.Inventory
    local itemData, index
    for i, item in ipairs(inventory) do
        if item.Id == itemId then itemData = item; index = i; break end
    end

    if not itemData then return {Success = false, Msg = "Item not found"} end

    -- 1. Remove from Inventory
    table.remove(inventory, index)
    
    -- 2. Prepare Data
    itemData.ListingPrice = price
    itemData.SellerId = player.UserId
    itemData.SellerName = player.Name
    itemData.ListingId = HttpService:GenerateGUID(false)
    
    -- 3. Add to Personal Listings
    table.insert(profile.Data.MarketList, itemData)
    
    -- 4. Add to Global Market
    pcall(function() 
        MarketQueue:SetAsync(itemData.ListingId, itemData, EXPIRATION) 
    end)
    
    if player.Character then
        local t = player.Character:FindFirstChildWhichIsA("Tool")
        if t and t:GetAttribute("ItemId") == itemId then t:Destroy() end
    end
    
    return {Success = true}
end

function MarketService.AttemptBuy(player, listingId)
    local profile = DataService.GetProfile(player)
    if not profile then return {Success = false, Msg = "Loading..."} end

    -- 1. Read Item
    local success, purchasedItem = pcall(function() return MarketQueue:GetAsync(listingId) end)
    if not success or not purchasedItem then return {Success = false, Msg = "Item sold or expired"} end

    -- 2. Check Money
    if profile.Data.RizzCoins < purchasedItem.ListingPrice then
        return {Success = false, Msg = "Not enough money"}
    end

    -- 3. Atomic Remove from Global Market
    -- We remove it first to prevent double buying
    pcall(function() MarketQueue:RemoveAsync(listingId) end) 

    -- 4. Process BUYER (Local Server)
    DataService.AdjustCurrency(player, -purchasedItem.ListingPrice)

    local newItem = {
        Id = purchasedItem.Id, Name = purchasedItem.Name, Model = purchasedItem.Model,
        Element = purchasedItem.Element, Size = purchasedItem.Size, FloorPrice = purchasedItem.FloorPrice,
        Created = purchasedItem.Created
    }
    DataService.AddItem(player, newItem)

    -- 5. Process SELLER (Cross-Server Handling)
    if purchasedItem.SellerId ~= -1 then
        
        -- A. Try to find seller in CURRENT server first
        local isLocal = MarketService.FinalizeSellerData(purchasedItem.SellerId, listingId, purchasedItem.ListingPrice)
        
        -- B. If seller is NOT here, broadcast to other servers
        if not isLocal then
            print("[Market] Seller is remote. Broadcasting sale...")
            
            -- [NEW] MessagingService Broadcast
            local messageData = {
                SellerId = purchasedItem.SellerId,
                ListingId = listingId,
                Price = purchasedItem.ListingPrice
            }
            
            pcall(function()
                MessagingService:PublishAsync(MARKET_TOPIC, messageData)
            end)
            
            -- C. Fallback: If player is totally offline (not in any server)
            -- We assume SendToInbox handles Offline Data (GlobalUpdates)
            DataService.SendToInbox(purchasedItem.SellerId, listingId, purchasedItem.ListingPrice)
        end
    end
    
    return {Success = true, Item = newItem}
end

function MarketService.RemoveListing(player, listingId)
    local profile = DataService.GetProfile(player)
    local index, itemData
    for i, item in ipairs(profile.Data.MarketList) do
        if item.ListingId == listingId then index = i; itemData = item; break end
    end
    
    pcall(function() MarketQueue:RemoveAsync(listingId) end)
    
    if itemData then
        table.remove(profile.Data.MarketList, index)
        table.insert(profile.Data.Inventory, itemData)
        return {Success = true}
    else
        return {Success = true, Msg = "Ghost listing cleared"}
    end
end

-- =============================================
-- 3. START & SUBSCRIPTION
-- =============================================

function MarketService.Start()
    print("[MarketService] STARTED V4 (Cross-Server Enabled)")

    GetMarketRF.OnServerInvoke = function(_) return MarketService.GetGlobalListings() end
    GetPlayerListingsRF.OnServerInvoke = function(p) 
        local profile = DataService.GetProfile(p)
        return profile and profile.Data.MarketList or {}
    end
    ListMarketRF.OnServerInvoke = function(p, id, price) return MarketService.ListOnMarket(p, id, price) end
    BuyItemRF.OnServerInvoke = function(p, id) return MarketService.AttemptBuy(p, id) end
    RemoveListingRF.OnServerInvoke = function(p, id) return MarketService.RemoveListing(p, id) end
    
    -- [NEW] LISTEN FOR SALES FROM OTHER SERVERS
    task.spawn(function()
        local success, err = pcall(function()
            MessagingService:SubscribeAsync(MARKET_TOPIC, function(message)
                local data = message.Data
                if data and data.SellerId then
                    -- Check if the seller is in THIS server
                    MarketService.FinalizeSellerData(data.SellerId, data.ListingId, data.Price)
                end
            end)
        end)
        
        if not success then warn("[MarketService] MessagingService Error: " .. tostring(err)) end
    end)
end

return MarketService