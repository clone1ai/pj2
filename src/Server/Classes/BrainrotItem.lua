local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Connect to Config
local ItemConfig = require(ReplicatedStorage.Configs.ItemConfig)

local BrainrotItem = {}
BrainrotItem.__index = BrainrotItem

-- Constructor
-- data: Optional table. If provided, loads existing item. If nil, mints new item.
function BrainrotItem.new(data)
    local self = setmetatable({}, BrainrotItem)
    
    if data then
        self.Data = data
    else
        self.Data = self:_generateNew()
    end
    
    return self
end

-- [cite: 2] Minting Logic: Calculates Intrinsic Value based on RNG stats
function BrainrotItem:_generateNew()
    -- 1. Roll RNG for Stats
    local modelName = self:_rollWeighted(ItemConfig.Models)
    local elementName = self:_rollWeighted(ItemConfig.Elements)
    
    -- [cite: 4] Size: Randomized float from 0.5 to 3.0
    local sizeRaw = (math.random() * (3.0 - 0.5)) + 0.5
    local size = math.floor(sizeRaw * 100) / 100 -- Round to 2 decimals
    
    -- 2. Fetch Multipliers
    local modelData = ItemConfig.Models[modelName]
    local elementData = ItemConfig.Elements[elementName]
    
    -- [cite: 6] Floor Price = (Base Box Cost) * (Model Mult) * (Element Mult) * (Size Mult)
    -- Note: We use modelData.BaseCost as the base.
    local floorPrice = modelData.BaseCost * modelData.Multiplier * elementData.Multiplier * size
    
    -- 3. Return Plain Data Table (for saving to DataStore)
    return {
        UUID = HttpService:GenerateGUID(false),
        Model = modelName,
        Element = elementName,
        Size = size,
        FloorPrice = math.floor(floorPrice), -- [cite: 7] Saved permanently
        CreationTime = os.time()
    }
end

-- Helper: Weighted RNG Selector
function BrainrotItem:_rollWeighted(tableData)
    local totalWeight = 0
    
    -- Calculate total weight
    for _, data in pairs(tableData) do
        totalWeight += data.Chance
    end
    
    local randomValue = math.random(1, totalWeight)
    local counter = 0
    
    for name, data in pairs(tableData) do
        counter += data.Chance
        if randomValue <= counter then
            return name
        end
    end
    
    return nil -- Should not happen if weights are correct
end

-- [cite: 11] Income Formula: Income/sec = (Item Floor Price) * 0.1
function BrainrotItem:GetIncomeRate()
    return math.floor(self.Data.FloorPrice * 0.1)
end

return BrainrotItem