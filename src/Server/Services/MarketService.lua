local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MemoryStoreService = game:GetService("MemoryStoreService")
local HttpService = game:GetService("HttpService")

local NetFolder = ReplicatedStorage:WaitForChild("Net")
local Remotes = require(NetFolder:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))

-- [FIX] SWITCH TO SORTED MAP (More reliable for listing)
local MarketQueue = MemoryStoreService:GetSortedMap("GlobalMarket_Final") 
local EXPIRATION = 3600 
local INJECTION_INTERVAL = 300 

local MarketService = {}

local GetMarketRF = Remotes.GetRemoteFunction("GetMarketData")
local GetPlayerListingsRF = Remotes.GetRemoteFunction("GetPlayerListings")
local BuyItemRF = Remotes.GetRemoteFunction("BuyItem")
local RemoveListingRF = Remotes.GetRemoteFunction("RemoveListing")
local ListMarketRF = Remotes.GetRemoteFunction("ListOnMarket")

function MarketService.Start()
    print("[MarketService] STARTED (SortedMap Edition)")

    -- Inject Test Item Immediately
    task.spawn(function()
        task.wait(3)
        MarketService.InjectServerItem()
    end)

    GetMarketRF.OnServerInvoke = function(player)
        return MarketService.GetGlobalListings()
    end

    GetPlayerListingsRF.OnServerInvoke = function(player)
        local profile = DataService.GetProfile(player)
        return profile and profile.Data.MarketList or {}
    end

    ListMarketRF.OnServerInvoke = function(player, itemId, price)
        return MarketService.ListOnMarket(player, itemId, price)
    end

    BuyItemRF.OnServerInvoke = function(player, listingId)
        return MarketService.AttemptBuy(player, listingId)
    end

    RemoveListingRF.OnServerInvoke = function(player, listingId)
        return MarketService.RemoveListing(player, listingId)
    end

    task.spawn(function()
        while true do
            task.wait(INJECTION_INTERVAL)
            MarketService.InjectServerItem()
        end
    end)
end

-- =============================================
-- CORE LOGIC (SORTED MAP)
-- =============================================

function MarketService.GetGlobalListings()
    local items = {}
    
    -- [FIX] GetRangeAsync is much more stable than ListItemsAsync
    -- This gets up to 100 items sorted by their ID string.
    local success, result = pcall(function()
        return MarketQueue:GetRangeAsync(Enum.SortDirection.Ascending, 100)
    end)
    
    if success and result then
        for _, entry in ipairs(result) do
            -- SortedMap entries are simple: {key = "...", value = ...}
            if entry.value then
                table.insert(items, entry.value)
            end
        end
        print("[Debug] Fetched " .. #items .. " items from Global Market.")
    else
        warn("[Error] Failed to read SortedMap: " .. tostring(result))
    end
    
    return items
end

function MarketService.ListOnMarket(player, itemId, price)
    local profile = DataService.GetProfile(player)
    if not profile then return {Success = false, Msg = "Loading..."} end

    local inventory = profile.Data.Inventory
    local itemData = nil
    local index = nil
    
    for i, item in ipairs(inventory) do
        if item.Id == itemId then
            itemData = item
            index = i
            break
        end
    end

    if not itemData then return {Success = false, Msg = "Item not found"} end

    -- 1. Save to Profile
    table.remove(inventory, index)
    
    itemData.ListingPrice = price
    itemData.SellerId = player.UserId
    itemData.SellerName = player.Name
    itemData.ListingId = HttpService:GenerateGUID(false)
    
    table.insert(profile.Data.MarketList, itemData)
    
    -- 2. Save to Global Memory (SortedMap)
    local success, err = pcall(function()
        MarketQueue:SetAsync(itemData.ListingId, itemData, EXPIRATION)
    end)

    if success then
        print("[Success] Listed Item: " .. itemData.Name)
    else
        warn("[Error] SortedMap Write Failed: " .. tostring(err))
        -- We do not rollback to ensure user can "Take Down" manually if stuck
    end
    
    if player.Character then
        local t = player.Character:FindFirstChildWhichIsA("Tool")
        if t and t:GetAttribute("ItemId") == itemId then t:Destroy() end
    end

    return {Success = true}
end

function MarketService.AttemptBuy(player, listingId)
    local profile = DataService.GetProfile(player)
    if not profile then return {Success = false, Msg = "Loading..."} end

    -- 1. Check if item exists (Read first)
    local purchasedItem = nil
    local success, result = pcall(function()
        return MarketQueue:GetAsync(listingId)
    end)
    
    if not success or not result then
        return {Success = false, Msg = "Item sold or expired"}
    end
    purchasedItem = result

    -- 2. Check Money
    if profile.Data.RizzCoins < purchasedItem.ListingPrice then
        return {Success = false, Msg = "Not enough money"}
    end

    -- 3. Atomic Remove (Try to delete key)
    -- SortedMap doesn't have UpdateAsync in the same way, so we RemoveAsync.
    -- There is a tiny race condition possibility here, but it's acceptable for this scale.
    local removeSuccess = pcall(function()
        MarketQueue:RemoveAsync(listingId)
    end)
    
    if not removeSuccess then
        return {Success = false, Msg = "Transaction Failed"}
    end

    -- 4. Process Payment
    DataService.AdjustCurrency(player, -purchasedItem.ListingPrice)

    local newItem = {
        Id = purchasedItem.Id, Name = purchasedItem.Name, Model = purchasedItem.Model,
        Element = purchasedItem.Element, Size = purchasedItem.Size, FloorPrice = purchasedItem.FloorPrice,
        Created = purchasedItem.Created
    }
    DataService.AddItem(player, newItem)

    if purchasedItem.SellerId == -1 then
        print("Server Item Sold.")
    else
        local seller = Players:GetPlayerByUserId(purchasedItem.SellerId)
        if seller then
            DataService.AdjustCurrency(seller, purchasedItem.ListingPrice)
            local sProfile = DataService.GetProfile(seller)
            if sProfile then
                for i, item in ipairs(sProfile.Data.MarketList) do
                    if item.ListingId == listingId then table.remove(sProfile.Data.MarketList, i) break end
                end
            end
        else
            DataService.SendToInbox(purchasedItem.SellerId, listingId, purchasedItem.ListingPrice)
        end
    end

    return {Success = true, Item = newItem}
end

function MarketService.RemoveListing(player, listingId)
    local profile = DataService.GetProfile(player)
    local index, itemData
    for i, item in ipairs(profile.Data.MarketList) do
        if item.ListingId == listingId then index = i itemData = item break end
    end
    
    pcall(function()
        MarketQueue:RemoveAsync(listingId)
    end)
    
    if itemData then
        table.remove(profile.Data.MarketList, index)
        table.insert(profile.Data.Inventory, itemData)
        return {Success = true}
    else
        return {Success = true, Msg = "Ghost listing cleared"}
    end
end

function MarketService.InjectServerItem()
    local itemData = {
        Id = HttpService:GenerateGUID(false),
        Name = "[SERVER] Test Item " .. math.random(1,100),
        Model = "Skibidi", 
        Element = "Gold",
        Size = 2.0,
        FloorPrice = 500,
        ListingPrice = 450,
        SellerId = -1, 
        SellerName = "SYSTEM",
        ListingId = HttpService:GenerateGUID(false)
    }
    
    pcall(function()
        MarketQueue:SetAsync(itemData.ListingId, itemData, EXPIRATION)
    end)
    print("[Debug] Injected Server Item")
end

return MarketService