local GameConfigs = {}

-- Economy
GameConfigs.BOX_COST = 100 
GameConfigs.MAX_INVENTORY_SLOTS = 50 -- 

-- Rarity Layers: Models
GameConfigs.MODELS = {
    { Name = "67", Weight = 60, Multiplier = 1 },   -- Common (x1)
    { Name = "Admin Lucky Block",  Weight = 30, Multiplier = 2 },   -- Rare (x2)
    { Name = "Agarrini la Palini", Weight = 10, Multiplier = 10 },  -- Legendary (x10)
}

-- Rarity Layers: Elements
GameConfigs.ELEMENTS = {
    { Name = "Plastic", Weight = 70, Multiplier = 1 },   -- x1
    { Name = "Gold",    Weight = 20, Multiplier = 3 },   -- x3
    { Name = "Void",    Weight = 8,  Multiplier = 5 },   -- x5
    { Name = "Glitch",  Weight = 2,  Multiplier = 10 },  -- x10
}

-- Size Range
GameConfigs.SIZE_MIN = 0.5
GameConfigs.SIZE_MAX = 3.0

return GameConfigs