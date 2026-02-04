local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)
-- Lazy load TycoonService inside functions to prevent circular dependency
local BrainrotItem = require(script.Parent.Parent.Classes.BrainrotItem)
local GameConstants = require(ReplicatedStorage.Configs.GameConstants)

local InventoryService = {}

function InventoryService:Init()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    
    local function createRemote(name, isFunction)
        if not remotes:FindFirstChild(name) then
            local r = isFunction and Instance.new("RemoteFunction") or Instance.new("RemoteEvent")
            r.Name = name
            r.Parent = remotes
        end
    end

    createRemote(GameConstants.Events.QUICK_SELL, false) -- Event
    createRemote(GameConstants.Events.REQUEST_MINT, true) -- Function [CHANGED TO FUNCTION]

    -- Bind Listeners
    remotes[GameConstants.Events.QUICK_SELL].OnServerEvent:Connect(function(p, uuid) 
        self:OnQuickSell(p, uuid) 
    end)
    
    -- Bind Invoke for Minting (Must return data)
    remotes[GameConstants.Events.REQUEST_MINT].OnServerInvoke = function(p) 
        return self:OnMintRequest(p) 
    end
end

function InventoryService:Start()
    print("   -> InventoryService Started")
end

-- [[ BUY BOX / MINTING LOGIC ]] --
function InventoryService:OnMintRequest(player)
    local profile = DataService:GetProfile(player)
    if not profile then return { Success = false, Message = "No Profile" } end
    
    -- 1. Check Funds
    if profile.Data.RizzCoins < GameConstants.BOX_COST then
        return { Success = false, Message = "Insufficient Funds" }
    end
    
    -- 2. Deduct Cost
    profile.Data.RizzCoins -= GameConstants.BOX_COST
    
    -- 3. Generate Item
    local newItemObject = BrainrotItem.new() 
    table.insert(profile.Data.Inventory, newItemObject.Data)
    
    -- 4. Sync Data
    player:SetAttribute("RizzCoins", profile.Data.RizzCoins)
    DataService:SyncClient(player)
    
    print("✅ MINT: " .. player.Name .. " got " .. newItemObject.Data.Model .. " [" .. newItemObject.Data.UUID .. "]")
    
    -- 5. RETURN SUCCESS DATA (Fixed Missing Return)
    return {
        Success = true,
        Item = newItemObject.Data
    }
end

-- [[ QUICK SELL LOGIC ]] --
function InventoryService:OnQuickSell(player, itemUUID)
    local TycoonService = require(script.Parent.TycoonService) -- Lazy Load
    
    local profile = DataService:GetProfile(player)
    if not profile then return end

    local inventory = profile.Data.Inventory
    local itemIndex, itemData = self:FindItem(inventory, itemUUID)

    if not itemData then return end
    
    -- Prevent selling placed items
    if TycoonService:IsItemPlaced(player, itemUUID) then 
        warn("Cannot sell placed item")
        return 
    end

    table.remove(inventory, itemIndex)
    
    local sellValue = math.floor(itemData.FloorPrice * GameConstants.QUICK_SELL_PERCENT)
    profile.Data.RizzCoins += sellValue
    
    player:SetAttribute("RizzCoins", profile.Data.RizzCoins)
    DataService:SyncClient(player)
    
    return { Success = true, SoldAmount = sellValue }
end

-- Helper
function InventoryService:FindItem(inventory, uuid)
    local target = tostring(uuid)
    for i, item in ipairs(inventory) do
        if tostring(item.UUID) == target then return i, item end
    end
    return nil, nil
end

return InventoryService