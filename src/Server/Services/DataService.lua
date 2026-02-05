local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService") -- [NEW]

local Packages = ReplicatedStorage:WaitForChild("Packages")
local ProfileService = require(Packages.ProfileService) 

local DataService = {}

local InboxStore = DataStoreService:GetDataStore("PlayerInbox_V1") -- [NEW] Dedicated Store

local ProfileTemplate = {
    RizzCoins = 1000,
    Inventory = {},   
    MarketList = {}, 
    Farm = {},
}

local ProfileStore = ProfileService.GetProfileStore("PlayerData_Dev_02", ProfileTemplate)
local Profiles = {}

function DataService.Start()
    print("[DataService] Started")

    Players.PlayerAdded:Connect(function(player)
        local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
        
        if profile ~= nil then
            profile:AddUserId(player.UserId)
            profile:Reconcile()
            
            profile:ListenToRelease(function()
                Profiles[player] = nil
                player:Kick("Data loaded elsewhere.")
            end)
            
            if player:IsDescendantOf(Players) then
                Profiles[player] = profile
                
                -- Init Attributes
                player:SetAttribute("RizzCoins", profile.Data.RizzCoins)
                
                -- [CRITICAL] Process Offline Inbox
                DataService.ProcessInbox(player, profile)
            else
                profile:Release()
            end
        else
            player:Kick("Data unavailable.")
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        local profile = Profiles[player]
        if profile then profile:Release() end
    end)
end

-- ==========================================
-- [NEW] INBOX LOGIC (OFFLINE HANDLING)
-- ==========================================

-- Called by MarketService when seller is offline
function DataService.SendToInbox(userId, listingId, amount)
    local key = "Inbox_" .. userId
    
    local success, err = pcall(function()
        InboxStore:UpdateAsync(key, function(oldData)
            local data = oldData or {}
            -- Add new message
            table.insert(data, {
                Type = "Sale",
                ListingId = listingId,
                Amount = amount,
                Time = os.time()
            })
            return data
        end)
    end)
    
    if success then
        print("Sent $" .. amount .. " to offline inbox of " .. userId)
    else
        warn("Failed to send to inbox: " .. tostring(err))
    end
end

-- Called when player Joins
function DataService.ProcessInbox(player, profile)
    local key = "Inbox_" .. player.UserId
    
    local success, inboxData = pcall(function()
        return InboxStore:GetAsync(key)
    end)
    
    if success and inboxData and #inboxData > 0 then
        print(player.Name .. " has " .. #inboxData .. " unread inbox messages.")
        
        local totalEarned = 0
        local itemsSold = 0
        
        for _, msg in ipairs(inboxData) do
            if msg.Type == "Sale" then
                totalEarned += msg.Amount
                
                -- [CRITICAL] Remove the SOLD item from their local list
                -- This prevents them from "Taking Down" an item that was already sold (Duplication Glitch)
                for i = #profile.Data.MarketList, 1, -1 do
                    if profile.Data.MarketList[i].ListingId == msg.ListingId then
                        table.remove(profile.Data.MarketList, i)
                        itemsSold += 1
                        break
                    end
                end
            end
        end
        
        -- Give Money
        if totalEarned > 0 then
            profile.Data.RizzCoins += totalEarned
            player:SetAttribute("RizzCoins", profile.Data.RizzCoins)
            print("Claimed $" .. totalEarned .. " from offline sales.")
            
            -- Ideally show a UI notification here: "You earned $X while asleep!"
        end
        
        -- Clear Inbox after processing
        InboxStore:RemoveAsync(key)
    end
end

-- ==========================================
-- STANDARD API
-- ==========================================

function DataService.GetProfile(player)
    return Profiles[player]
end

function DataService.AdjustCurrency(player, amount)
    local profile = Profiles[player]
    if profile then
        profile.Data.RizzCoins += amount
        player:SetAttribute("RizzCoins", profile.Data.RizzCoins)
    end
end

function DataService.AddItem(player, itemData)
    local profile = Profiles[player]
    if profile then
        table.insert(profile.Data.Inventory, itemData)
    end
end

return DataService