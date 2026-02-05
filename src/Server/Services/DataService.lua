local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- SAFETY: Wait for Packages to load
local Packages = ReplicatedStorage:WaitForChild("Packages", 30)
if not Packages then error("Packages folder missing in ReplicatedStorage!") end

local ProfileService = require(Packages:WaitForChild("ProfileService"))

local DataService = {}

-- Default Data Structure
local ProfileTemplate = {
    RizzCoins = 1000,
    Inventory = {},   
    MarketList = {},
    Farm = {}, -- Format: { {Id="...", Name="...", FloorPrice=..., Position={x,y,z}} }
}

-- Store Key (Change "Dev_01" to wipe data)
local ProfileStore = ProfileService.GetProfileStore("PlayerData_Dev_01", ProfileTemplate)
local Profiles = {}

function DataService.Start()
    print("[DataService] Started")

    Players.PlayerAdded:Connect(function(player)
        local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
        player:SetAttribute("RizzCoins", profile.Data.RizzCoins)
        if profile ~= nil then
            profile:AddUserId(player.UserId)
            profile:Reconcile()
            
            profile:ListenToRelease(function()
                Profiles[player] = nil
                player:Kick("Data loaded elsewhere.")
            end)
            
            if player:IsDescendantOf(Players) then
                Profiles[player] = profile
                print(player.Name .. " data loaded. Coins: " .. profile.Data.RizzCoins)
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

function DataService.GetProfile(player)
    return Profiles[player]
end

function DataService.AdjustCurrency(player, amount)
    local profile = Profiles[player]
    if profile then
        profile.Data.RizzCoins += amount
        
        -- [NEW] Sync to Client via Attribute
        player:SetAttribute("RizzCoins", profile.Data.RizzCoins)
        
        -- (Optional) Update legacy leaderstats if you use them
        local ls = player:FindFirstChild("leaderstats")
        if ls then ls.Coins.Value = profile.Data.RizzCoins end
    end
end

function DataService.AddItem(player, itemData)
    local profile = Profiles[player]
    if profile then
        table.insert(profile.Data.Inventory, itemData)
    end
end

return DataService