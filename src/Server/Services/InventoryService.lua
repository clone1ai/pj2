local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataService = require(script.Parent.DataService)
-- Ensure this path matches your Argon structure (usually ServerScriptService.Classes)
local BrainrotItem = require(script.Parent.Parent.Classes.BrainrotItem) 
local GameConstants = require(ReplicatedStorage.Configs.GameConstants)

local InventoryService = {}

function InventoryService:Init()
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotesFolder then
        remotesFolder = Instance.new("Folder")
        remotesFolder.Name = "Remotes"
        remotesFolder.Parent = ReplicatedStorage
    end

    local mintFunc = remotesFolder:FindFirstChild(GameConstants.Events.REQUEST_MINT)
    if not mintFunc then
        mintFunc = Instance.new("RemoteFunction")
        mintFunc.Name = GameConstants.Events.REQUEST_MINT
        mintFunc.Parent = remotesFolder
    end

    local getBalanceFunc = remotesFolder:FindFirstChild(GameConstants.Events.GET_RIZZ_COIN_BALANCE)
    if not getBalanceFunc then
        getBalanceFunc = Instance.new("RemoteFunction")
        getBalanceFunc.Name = GameConstants.Events.GET_RIZZ_COIN_BALANCE
        getBalanceFunc.Parent = remotesFolder
    end

    mintFunc.OnServerInvoke = function(player)
        return self:MintItem(player)
    end
    
    getBalanceFunc.OnServerInvoke = function(player)
        local profile = DataService:GetProfile(player)
        return profile and profile.Data.RizzCoins or 0
    end
end

function InventoryService:Start()
    print("   -> InventoryService Started")
end

function InventoryService:MintItem(player)
    -- [FIX] Use Constant instead of hardcoded number
    local boxCost = GameConstants.BOX_COST 
    
    local profile = DataService:GetProfile(player)
    if not profile then 
        warn("[InventoryService] No profile found for " .. player.Name)
        return { Success = false, Message = "Data not loaded" } 
    end

    if profile.Data.RizzCoins >= boxCost then
        profile.Data.RizzCoins -= boxCost

        if player and player.SetAttribute then
            player:SetAttribute("RizzCoins", profile.Data.RizzCoins)
        end

        local newItemObject = BrainrotItem.new() 
        local itemData = newItemObject.Data

        table.insert(profile.Data.Inventory, itemData)

        -- Sync client
        DataService:SyncClient(player)

        print(string.format("📦 %s Minted: %s | Floor: $%s", player.Name, itemData.Model, itemData.FloorPrice))

        return { 
            Success = true, 
            Item = itemData,
            NewBalance = profile.Data.RizzCoins
        }
    else
        return { Success = false, Message = "Not enough Funds" }
    end
end

return InventoryService