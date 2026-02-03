local ItemConfig = {
    -- [cite: 3] Rarity Multipliers: Common x1, Rare x2, Legendary x10
    Models = {
        ["67"] = { Multiplier = 1, BaseCost = 100, Chance = 70 }, -- Common
        ["Admin Lucky Block"]  = { Multiplier = 2, BaseCost = 200, Chance = 25 }, -- Rare
        ["Agarrini la Palini"] = { Multiplier = 10, BaseCost = 500, Chance = 5 }, -- Legendary
    },
    
    -- [cite: 4] Elements: Plastic (x1), Gold (x3), Void (x5), Glitch (x10)
    Elements = {
        ["Plastic"] = { Multiplier = 1, Chance = 60 },
        ["Gold"]    = { Multiplier = 3, Chance = 30 },
        ["Void"]    = { Multiplier = 5, Chance = 9 },
        ["Glitch"]  = { Multiplier = 10, Chance = 1 },
    }
}

return ItemConfig