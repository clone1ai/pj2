local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Dependencies
local ProfileService = require(ReplicatedStorage.Utils.ProfileService)
local GameConstants = require(ReplicatedStorage.Configs.GameConstants)

local DataService = {}
DataService.Profiles = {}

-- [[ 1. THE DATA TEMPLATE ]] --
local ProfileTemplate = {
    RizzCoins = 1000,
    TotalEarned = 0, -- << FIX: This was missing before!
    Inventory = {},
    ShelfLayout = {}
}

-- [[ 2. DATA STORE KEY ]] --
-- I changed this to "02". This will WIPE your current data so you get the new Template.
local ProfileStore = ProfileService.GetProfileStore("Brainrot_Dev_02", ProfileTemplate)

function DataService:Init()
    -- Create Remotes Folder if missing
    if not ReplicatedStorage:FindFirstChild("Remotes") then
        local folder = Instance.new("Folder")
        folder.Name = "Remotes"
        folder.Parent = ReplicatedStorage
    end
    
    -- Create Sync Event
    local syncEvent = ReplicatedStorage.Remotes:FindFirstChild(GameConstants.Events.SYNC_DATA)
    if not syncEvent then
        syncEvent = Instance.new("RemoteEvent")
        syncEvent.Name = GameConstants.Events.SYNC_DATA
        syncEvent.Parent = ReplicatedStorage.Remotes
    end
end

function DataService:Start()
    Players.PlayerAdded:Connect(function(player)
        local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
        if profile then
            profile:AddUserId(player.UserId)
            profile:Reconcile() -- Fills in missing values from Template

            profile:ListenToRelease(function()
                self.Profiles[player] = nil
                player:Kick()
            end)

            if player:IsDescendantOf(Players) then
                self.Profiles[player] = profile
                print("      [Data] Loaded profile for " .. player.Name)

                -- Set RizzCoins attribute for HUD
                if player and player.SetAttribute then
                    player:SetAttribute("RizzCoins", profile.Data.RizzCoins or 0)
                end

                -- Sync immediately on load
                self:SyncClient(player)
            else
                profile:Release()
            end
        else
            player:Kick("Could not load data")
        end
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        local profile = self.Profiles[player]
        if profile then profile:Release() end
    end)
end

function DataService:GetProfile(player)
    return self.Profiles[player]
end

function DataService:SyncClient(player)
    local profile = self:GetProfile(player)
    if profile then
        ReplicatedStorage.Remotes[GameConstants.Events.SYNC_DATA]:FireClient(player, profile.Data)
    end
end

return DataService