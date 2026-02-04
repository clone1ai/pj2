local GameConstants = {
    INCOME_TICK_RATE = 1,
    QUICK_SELL_PERCENT = 0.5,
    BOX_COST = 100,       -- Cost to open a box
    MAX_SHELVES = 6,      -- Max shelves per plot
    EVENT_INTERVAL = 60,
    EVENT_DURATION = 30,
    INJECTION_INTERVAL = 300, -- Every 5 minutes (300s)
    SYSTEM_USER_ID = -1, -- The ID used for Server listings
    
    Events = {
        REQUEST_MINT = "RequestMint",
        PLACE_ITEM = "PlaceItem",
        QUICK_SELL = "QuickSell",
        SYNC_DATA = "SyncData",
		MARKET_EVENT = "MarketEvent",
        
        -- [NEW] Marketplace Events
        POST_LISTING = "PostListing", -- Player -> Server (List Item)
        BUY_LISTING = "BuyListing",   -- Player -> Server (Buy Item)
        REFRESH_MARKET = "RefreshMarket", -- Server -> All Clients (Sync Listings)
        REMOVE_ITEM_FROM_SHELF = "RemoveItemFromShelf", -- Server <-> Client (Remove Item)
        GET_RIZZ_COIN_BALANCE = "GetRizzCoinBalance" -- Server <-> Client (Get RizzCoin Balance)
    },
    
    Buffs = {
        -- (Keep your existing buffs here)
        { Type = "Element", Target = "Gold", Multiplier = 5, Message = "🌟 GOLD RUSH: All [GOLD] items earn 5x Cash!" },
        { Type = "Element", Target = "Void", Multiplier = 5, Message = "⚫ VOID SPIKE: All [VOID] items earn 5x Cash!" },
        { Type = "Model", Target = "Grimace", Multiplier = 10, Message = "🟣 SHAKE IT: All [GRIMACE] items earn 10x Cash!" }
    }
}

return GameConstants