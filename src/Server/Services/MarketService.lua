local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MemoryStoreService = game:GetService("MemoryStoreService")
local HttpService = game:GetService("HttpService")

local NetFolder = ReplicatedStorage:WaitForChild("Net")
local Remotes = require(NetFolder:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))

-- CONFIG
-- [NOTE] If you want to wipe the market, change this key (e.g., "GlobalMarket_Final_V4")
local MarketQueue = MemoryStoreService:GetSortedMap("GlobalMarket_Final_V2") 
local EXPIRATION = 3600 

local MarketService = {}

local GetMarketRF = Remotes.GetRemoteFunction("GetMarketData")
local GetPlayerListingsRF = Remotes.GetRemoteFunction("GetPlayerListings")
local BuyItemRF = Remotes.GetRemoteFunction("BuyItem")
local RemoveListingRF = Remotes.GetRemoteFunction("RemoveListing")
local ListMarketRF = Remotes.GetRemoteFunction("ListOnMarket")

-- =============================================
-- 1. DEFINE LOGIC FUNCTIONS
-- =============================================

function MarketService.GetGlobalListings()
    local items = {}
    -- Fetch up to 100 items sorted by ID
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
    
    -- 2. Prepare Market Data
    itemData.ListingPrice = price
    itemData.SellerId = player.UserId
    itemData.SellerName = player.Name
    itemData.ListingId = HttpService:GenerateGUID(false)
    
    -- 3. Add to Personal Listings (DataStore)
    table.insert(profile.Data.MarketList, itemData)
    
    -- 4. Add to Global Market (MemoryStore)
    pcall(function() 
        MarketQueue:SetAsync(itemData.ListingId, itemData, EXPIRATION) 
    end)
    
    -- 5. Visual Cleanup
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

    -- 3. Remove from Market (Atomic-ish)
    pcall(function() MarketQueue:RemoveAsync(listingId) end) 

    -- 4. Deduct Money & Add Item
    DataService.AdjustCurrency(player, -purchasedItem.ListingPrice)

    local newItem = {
        Id = purchasedItem.Id, Name = purchasedItem.Name, Model = purchasedItem.Model,
        Element = purchasedItem.Element, Size = purchasedItem.Size, FloorPrice = purchasedItem.FloorPrice,
        Created = purchasedItem.Created
    }
    DataService.AddItem(player, newItem)

    -- 5. Pay Seller
    if purchasedItem.SellerId ~= -1 then
        local seller = Players:GetPlayerByUserId(purchasedItem.SellerId)
        if seller then
            -- Seller is Online
            DataService.AdjustCurrency(seller, purchasedItem.ListingPrice)
            local sProfile = DataService.GetProfile(seller)
            if sProfile then
                for i, item in ipairs(sProfile.Data.MarketList) do
                    if item.ListingId == listingId then table.remove(sProfile.Data.MarketList, i) break end
                end
            end
        else
            -- Seller is Offline -> Inbox
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
    
    -- Try to remove from global
    pcall(function() MarketQueue:RemoveAsync(listingId) end)
    
    -- Restore to inventory
    if itemData then
        table.remove(profile.Data.MarketList, index)
        table.insert(profile.Data.Inventory, itemData)
        return {Success = true}
    else
        return {Success = true, Msg = "Ghost listing cleared"}
    end
end

-- =============================================
-- 2. START
-- =============================================

function MarketService.Start()
    print("[MarketService] STARTED (Player-Only Economy)")

    GetMarketRF.OnServerInvoke = function(_) return MarketService.GetGlobalListings() end
    
    GetPlayerListingsRF.OnServerInvoke = function(p) 
        local profile = DataService.GetProfile(p)
        return profile and profile.Data.MarketList or {}
    end
    
    ListMarketRF.OnServerInvoke = function(p, id, price) return MarketService.ListOnMarket(p, id, price) end
    BuyItemRF.OnServerInvoke = function(p, id) return MarketService.AttemptBuy(p, id) end
    RemoveListingRF.OnServerInvoke = function(p, id) return MarketService.RemoveListing(p, id) end
    
    -- No loops, no injections. Pure player economy.
end

return MarketService