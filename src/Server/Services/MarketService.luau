local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local DataService = require(script.Parent.DataService)
local TycoonService = require(script.Parent.TycoonService)
local GameConstants = require(ReplicatedStorage.Configs.GameConstants)

local MarketService = {}
MarketService.ActiveListings = {} 

function MarketService:Init()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    
    local function createRemote(name, isFunction)
        if not remotes:FindFirstChild(name) then
            local r = isFunction and Instance.new("RemoteFunction") or Instance.new("RemoteEvent")
            r.Name = name
            r.Parent = remotes
        end
    end
    
    createRemote(GameConstants.Events.POST_LISTING, true)
    createRemote(GameConstants.Events.BUY_LISTING, true)
    createRemote(GameConstants.Events.REFRESH_MARKET, false)

    -- Bind Functions
    remotes[GameConstants.Events.POST_LISTING].OnServerInvoke = function(player, itemUUID, price)
        return self:PostListing(player, itemUUID, price)
    end
    
    remotes[GameConstants.Events.BUY_LISTING].OnServerInvoke = function(player, listingID)
        return self:BuyListing(player, listingID)
    end
end

function MarketService:Start()
    print("   -> MarketService Started")
    -- Broadcast loop
    task.spawn(function()
        while true do
            task.wait(5)
            self:BroadcastMarket()
        end
    end)
end

-- [[ POST A LISTING ]] --
function MarketService:PostListing(player, itemUUID, askPrice)
    -- 1. Sanitize Input
    if type(askPrice) ~= "number" or askPrice <= 0 then 
        return false, "Invalid Price" 
    end
    
    local profile = DataService:GetProfile(player)
    if not profile then 
        return false, "No Profile Loaded" 
    end
    
    -- 2. ROBUST SEARCH (Fixes Type Mismatch)
    local inventory = profile.Data.Inventory
    local foundItem = nil
    local foundIndex = nil
    local targetUUID = tostring(itemUUID) -- Force String for comparison
    
    for i, item in ipairs(inventory) do
        -- Compare as strings to prevent "123" vs 123 errors
        if tostring(item.UUID) == targetUUID then
            foundItem = item
            foundIndex = i
            break
        end
    end

    if not foundItem then 
        -- Debugging Output for you
        warn("❌ MarketService: Item Check Failed for " .. player.Name)
        print("   > Looking for UUID:", targetUUID)
        print("   > First 3 items in inventory:")
        for i = 1, math.min(3, #inventory) do
            print("     [" .. i .. "] " .. tostring(inventory[i].UUID))
        end
        return false, "Item not found" 
    end
    
    -- 3. Check if Placed (Tycoon Check)
    -- We pass the original item.UUID to be safe
    if TycoonService:IsItemPlaced(player, foundItem.UUID) then
        return false, "Item is currently on a shelf!"
    end
    
    -- 4. Execute Listing
    table.remove(inventory, foundIndex) -- Remove from player
    DataService:SyncClient(player)      -- Update player UI
    
    local listingID = HttpService:GenerateGUID(false)
    self.ActiveListings[listingID] = {
        ID = listingID,
        SellerUserId = player.UserId,
        SellerName = player.Name,
        Price = math.floor(askPrice),
        ItemData = foundItem,
        Timestamp = os.time()
    }
    
    print("✅ LISTING SUCCESS: " .. foundItem.Model .. " for $" .. askPrice)
    self:BroadcastMarket()
    return true, "Listed Successfully"
end

-- [[ BUY A LISTING ]] --
function MarketService:BuyListing(buyer, listingID)
    local listing = self.ActiveListings[listingID]
    if not listing then return false, "Listing no longer exists" end
    
    local buyerProfile = DataService:GetProfile(buyer)
    if not buyerProfile then return false, "Profile Error" end
    
    if listing.SellerUserId == buyer.UserId then
        return false, "You cannot buy your own item"
    end
    
    if buyerProfile.Data.RizzCoins < listing.Price then
        return false, "Insufficient Funds"
    end
    
    -- Transaction
    buyerProfile.Data.RizzCoins -= listing.Price
    buyer:SetAttribute("RizzCoins", buyerProfile.Data.RizzCoins)
    
    table.insert(buyerProfile.Data.Inventory, listing.ItemData)
    DataService:SyncClient(buyer)
    
    local sellerPlayer = Players:GetPlayerByUserId(listing.SellerUserId)
    if sellerPlayer then
        local sellerProfile = DataService:GetProfile(sellerPlayer)
        if sellerProfile then
            sellerProfile.Data.RizzCoins += listing.Price
            sellerPlayer:SetAttribute("RizzCoins", sellerProfile.Data.RizzCoins)
        end
    end
    
    self.ActiveListings[listingID] = nil
    self:BroadcastMarket()
    return true, "Purchase Successful"
end

function MarketService:BroadcastMarket()
    local list = {}
    for _, data in pairs(self.ActiveListings) do
        table.insert(list, data)
    end
    ReplicatedStorage.Remotes[GameConstants.Events.REFRESH_MARKET]:FireAllClients(list)
end

return MarketService