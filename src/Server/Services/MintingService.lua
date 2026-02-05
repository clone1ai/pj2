local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- SAFETY: Explicit WaitForChild for everything
local ConfigsFolder = ReplicatedStorage:WaitForChild("Configs")
local NetFolder = ReplicatedStorage:WaitForChild("Net")

local GameConfigs = require(ConfigsFolder:WaitForChild("GameConfigs"))
local Remotes = require(NetFolder:WaitForChild("Remotes"))

-- Require Sibling Service
local DataService = require(script.Parent:WaitForChild("DataService"))

local MintingService = {}
local OpenBoxRF = Remotes.GetRemoteFunction("OpenBox")

-- Helper: Weighted Random
local function SelectFromWeightedTable(tbl)
    local totalWeight = 0
    for _, item in ipairs(tbl) do totalWeight += item.Weight end
    
    local randomValue = math.random() * totalWeight
    local currentWeight = 0
    for _, item in ipairs(tbl) do
        currentWeight += item.Weight
        if randomValue <= currentWeight then return item end
    end
    return tbl[1]
end

function MintingService.Start()
    print("[MintingService] Started")
    
    OpenBoxRF.OnServerInvoke = function(player)
        return MintingService.AttemptOpenBox(player)
    end
end

function MintingService.AttemptOpenBox(player)
    local profile = DataService.GetProfile(player)
    if not profile then return {Success = false, Msg = "Loading Data..."} end
    
    -- Check Cost
    if profile.Data.RizzCoins < GameConfigs.BOX_COST then
        return {Success = false, Msg = "NOT ENOUGH COINS"}
    end
    
    -- Check Inventory
    if #profile.Data.Inventory >= GameConfigs.MAX_INVENTORY_SLOTS then
        return {Success = false, Msg = "INVENTORY FULL"}
    end

    -- Transaction
    DataService.AdjustCurrency(player, -GameConfigs.BOX_COST)
    
    -- RNG Layers
    local selectedModel = SelectFromWeightedTable(GameConfigs.MODELS)
    local selectedElement = SelectFromWeightedTable(GameConfigs.ELEMENTS)
    local randomSize = GameConfigs.SIZE_MIN + (math.random() * (GameConfigs.SIZE_MAX - GameConfigs.SIZE_MIN))
    randomSize = math.round(randomSize * 100) / 100

    -- Price Calculation
    local floorPrice = GameConfigs.BOX_COST * selectedModel.Multiplier * selectedElement.Multiplier * randomSize
    floorPrice = math.floor(floorPrice)

    -- Create Item
    local newItem = {
        Id = HttpService:GenerateGUID(false),
        Name = selectedElement.Name .. " " .. selectedModel.Name,
        Model = selectedModel.Name,
        Element = selectedElement.Name,
        Size = randomSize,
        FloorPrice = floorPrice, -- Permanent Value
        Created = os.time()
    }

    DataService.AddItem(player, newItem)
    print("Minted: " .. newItem.Name)

    return { Success = true, Data = newItem }
end

return MintingService