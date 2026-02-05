local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

-- PATHS
local NetFolder = ReplicatedStorage:WaitForChild("Net")
local Remotes = require(NetFolder:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local Assets = ReplicatedStorage:WaitForChild("Assets")
local BrainsFolder = Assets:WaitForChild("Brains")

local InventoryService = {}

-- Remotes
local EquipRF = Remotes.GetRemoteFunction("EquipItem")
local QuickSellRF = Remotes.GetRemoteFunction("QuickSell")
local ListMarketRF = Remotes.GetRemoteFunction("ListOnMarket")
local GetInvRF = Remotes.GetRemoteFunction("GetInventoryData")

-- Helper: Find Asset
local function FindModelAsset(itemName, modelName)
    local exact = BrainsFolder:FindFirstChild(itemName)
    if exact then return exact end
    local base = BrainsFolder:FindFirstChild(modelName)
    if base then return base end
    return nil
end

function InventoryService.Start()
    print("[InventoryService] Started")
    
    -- [CRITICAL FIX] Data Loading State
    GetInvRF.OnServerInvoke = function(player)
        local profile = DataService.GetProfile(player)
        
        -- If profile is missing, return NIL (Signal for "Loading")
        if not profile or not profile.Data then 
            return nil 
        end
        
        return profile.Data.Inventory
    end

    EquipRF.OnServerInvoke = function(player, itemId)
        return InventoryService.ToggleEquipItem(player, itemId)
    end

    QuickSellRF.OnServerInvoke = function(player, itemId)
        return InventoryService.QuickSell(player, itemId)
    end

    ListMarketRF.OnServerInvoke = function(player, itemId, price)
        return InventoryService.ListOnMarket(player, itemId, price)
    end
end

-- Floating & Animation Setup
function InventoryService.ToggleEquipItem(player, itemId)
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local head = character:FindFirstChild("Head") 
    
    if not humanoid or not head then return false end

    -- 1. Unequip existing
    local currentTool = character:FindFirstChildWhichIsA("Tool")
    if currentTool and currentTool:GetAttribute("ItemId") == itemId then
        currentTool:Destroy()
        humanoid:UnequipTools()
        return "Unequipped"
    end

    -- 2. Cleanup
    for _, t in pairs(character:GetChildren()) do if t:IsA("Tool") then t:Destroy() end end
    for _, t in pairs(player.Backpack:GetChildren()) do if t:IsA("Tool") then t:Destroy() end end

    -- 3. Validate
    local profile = DataService.GetProfile(player)
    if not profile then return false end
    
    local targetItem = nil
    for _, item in ipairs(profile.Data.Inventory) do
        if item.Id == itemId then targetItem = item break end
    end
    if not targetItem then return "Item Not Found" end

    -- 4. Create Tool
    local modelAsset = FindModelAsset(targetItem.Name, targetItem.Model)
    if not modelAsset then return "Asset Missing" end
    
    local tool = Instance.new("Tool")
    tool.Name = targetItem.Name
    tool:SetAttribute("ItemId", itemId)
    tool.RequiresHandle = false 
    tool.CanBeDropped = false   
    
    -- 5. Physics Setup
    local clonedModel = modelAsset:Clone()
    if not clonedModel.PrimaryPart then
        clonedModel.PrimaryPart = clonedModel:FindFirstChildWhichIsA("BasePart") or clonedModel:GetChildren()[1]
    end

    for _, part in pairs(clonedModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false      
            part.CanCollide = false
            part.Massless = true       
            part.CastShadow = false
        end
    end

    if clonedModel:IsA("Model") then
        clonedModel:ScaleTo(targetItem.Size or 1.0)
    end
    
    clonedModel.Parent = tool
    tool.Parent = character 

    -- 6. Motor6D Connection (Animation Ready)
    task.spawn(function()
        task.wait() 
        if clonedModel.PrimaryPart and head then
            local motor = Instance.new("Motor6D")
            motor.Name = "FloaterMotor"
            motor.Part0 = head
            motor.Part1 = clonedModel.PrimaryPart
            
            -- Height Offset (4.5 Studs High)
            motor.C0 = CFrame.new(0, 4.5, 0) 
            
            motor.Parent = clonedModel.PrimaryPart
            
            -- Tag for Animation
            CollectionService:AddTag(motor, "FloatingBrainrot")
        end
    end)
    
    return "Equipped"
end

function InventoryService.QuickSell(player, itemId)
    local profile = DataService.GetProfile(player)
    -- Safety Check
    if not profile or not profile.Data then return {Success = false, Msg = "Loading..."} end

    local inventory = profile.Data.Inventory
    for i, item in ipairs(inventory) do
        if item.Id == itemId then
            local sellValue = math.floor(item.FloorPrice * 0.5)
            table.remove(inventory, i)
            DataService.AdjustCurrency(player, sellValue)
            if player.Character then
                local t = player.Character:FindFirstChildWhichIsA("Tool")
                if t and t:GetAttribute("ItemId") == itemId then t:Destroy() end
            end
            return {Success = true, Cash = sellValue}
        end
    end
    return {Success = false, Msg = "Item not found"}
end

function InventoryService.ListOnMarket(player, itemId, price)
    local profile = DataService.GetProfile(player)
    -- Safety Check
    if not profile or not profile.Data then return {Success = false, Msg = "Loading..."} end
    
    if price <= 0 then return {Success = false, Msg = "Invalid Price"} end
    local inventory = profile.Data.Inventory
    for i, item in ipairs(inventory) do
        if item.Id == itemId then
            local itemToSell = table.remove(inventory, i)
            itemToSell.ListingPrice = price
            itemToSell.SellerId = player.UserId
            table.insert(profile.Data.MarketList, itemToSell)
            if player.Character then
                local t = player.Character:FindFirstChildWhichIsA("Tool")
                if t and t:GetAttribute("ItemId") == itemId then t:Destroy() end
            end
            return {Success = true}
        end
    end
    return {Success = false, Msg = "Item not found"}
end

return InventoryService