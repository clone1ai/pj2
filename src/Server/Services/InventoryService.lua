local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Dependencies
local DataService = require(script.Parent.DataService)
-- Argon syncs 'src/Server/Classes' -> 'ServerScriptService.Classes'
local BrainrotItem = require(ServerScriptService.Classes.BrainrotItem) 
local GameConstants = require(ReplicatedStorage.Configs.GameConstants)

local InventoryService = {}

function InventoryService:Init()
    -- Ensure Remotes Folder Exists
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotesFolder then
        remotesFolder = Instance.new("Folder")
        remotesFolder.Name = "Remotes"
        remotesFolder.Parent = ReplicatedStorage
    end

    -- Create Mint RemoteFunction (Two-way communication)
    local mintFunc = remotesFolder:FindFirstChild(GameConstants.Events.REQUEST_MINT)
    if not mintFunc then
        mintFunc = Instance.new("RemoteFunction")
        mintFunc.Name = GameConstants.Events.REQUEST_MINT
        mintFunc.Parent = remotesFolder
    end

    -- Create GetBalance RemoteFunction
    local getBalanceFunc = remotesFolder:FindFirstChild("GetRizzCoinBalance")
    if not getBalanceFunc then
        getBalanceFunc = Instance.new("RemoteFunction")
        getBalanceFunc.Name = "GetRizzCoinBalance"
        getBalanceFunc.Parent = remotesFolder
    end

    -- Bind Logic
    mintFunc.OnServerInvoke = function(player)
        return self:MintItem(player)
    end
    getBalanceFunc.OnServerInvoke = function(player)
        local profile = require(script.Parent.DataService):GetProfile(player)
        if profile then
            return profile.Data.RizzCoins or 0
        end
        return 0
    end
end

function InventoryService:Start()
    print("   -> InventoryService Started")
end

-- Core Logic
function InventoryService:MintItem(player)
    local BOX_COST = 100 -- Constant for now
    
    local profile = DataService:GetProfile(player)
    if not profile then 
        warn("[InventoryService] No profile found for " .. player.Name)
        return { Success = false, Message = "Data not loaded" } 
    end

    -- Transaction
    if profile.Data.RizzCoins >= BOX_COST then
        profile.Data.RizzCoins -= BOX_COST

        -- Update player attribute for client HUD
        if player and player.SetAttribute then
            player:SetAttribute("RizzCoins", profile.Data.RizzCoins)
        end

        -- Generate Item
        local newItemObject = BrainrotItem.new() 
        local itemData = newItemObject.Data

        -- Save to Inventory
        table.insert(profile.Data.Inventory, itemData)

        -- Sync client with new data
        local DataService = require(script.Parent.DataService)
        DataService:SyncClient(player)

        -- Logging
        print(string.format("📦 %s Minted: %s | Floor: $%s", 
            player.Name, 
            itemData.Model, 
            itemData.FloorPrice
        ))

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