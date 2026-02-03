local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Dependencies
local DataService = require(script.Parent.DataService)
local GameConstants = require(ReplicatedStorage.Configs.GameConstants)

-- Lazy Load EventService to prevent Circular Dependency loops
local EventService = nil 

local TycoonService = {}
TycoonService.ActivePlots = {} -- [Player] = PlotModel

-- Constants
local MAX_SHELVES = 6

function TycoonService:Init()
    local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
    
    -- Create PlaceItem Event (Client -> Server)
    local placeEvent = remotesFolder:FindFirstChild(GameConstants.Events.PLACE_ITEM)
    if not placeEvent then
        placeEvent = Instance.new("RemoteEvent")
        placeEvent.Name = GameConstants.Events.PLACE_ITEM
        placeEvent.Parent = remotesFolder
    end
    
    -- Bind Listener
    placeEvent.OnServerEvent:Connect(function(player, itemUUID, shelfIndex)
        self:PlaceItem(player, itemUUID, shelfIndex)
    end)

    -- Create RemoveItem Event (Client -> Server)
    local removeEvent = remotesFolder:FindFirstChild("RemoveItemFromShelf")
    if not removeEvent then
        removeEvent = Instance.new("RemoteEvent")
        removeEvent.Name = "RemoveItemFromShelf"
        removeEvent.Parent = remotesFolder
    end
    removeEvent.OnServerEvent:Connect(function(player, shelfIndex)
        self:RemoveItemFromShelf(player, shelfIndex)
    end)
end

function TycoonService:Start()
    -- Load EventService now that the server has booted
    EventService = require(script.Parent.EventService)

    -- 1. Handle Plot Assignment
    Players.PlayerAdded:Connect(function(player)
        self:AssignPlot(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:UnassignPlot(player)
    end)
    
    -- 2. Start Passive Income Loop (The Heartbeat)
    task.spawn(function()
        while true do
            self:ProcessIncome()
            task.wait(GameConstants.INCOME_TICK_RATE)
        end
    end)
    
    print("   -> TycoonService Started")
end

-- =============================================
-- PLOT MANAGEMENT
-- =============================================

function TycoonService:AssignPlot(player)
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then 
        warn("⚠️ No 'Plots' folder found in Workspace!") 
        return 
    end

    -- Find an empty plot
    for _, plot in ipairs(plotsFolder:GetChildren()) do
        if plot:GetAttribute("OwnerId") == nil then
            -- Claim it
            plot:SetAttribute("OwnerId", player.UserId)
            self.ActivePlots[player] = plot
            
            -- Set Visual Owner Sign (Optional)
            local sign = plot:FindFirstChild("OwnerSign")
            if sign and sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui:FindFirstChild("TextLabel") then
                sign.SurfaceGui.TextLabel.Text = player.Name .. "'s Market"
            end
            
            -- Load Saved Shelves from Data
            self:RestoreShelves(player, plot)
            
            print("✅ Assigned " .. plot.Name .. " to " .. player.Name)
            return
        end
    end
    warn("❌ No available plots for " .. player.Name)
end

function TycoonService:UnassignPlot(player)
    local plot = self.ActivePlots[player]
    if plot then
        plot:SetAttribute("OwnerId", nil)
        
        -- Clear Visuals
        local shelves = plot:FindFirstChild("Shelves")
        if shelves then
            for _, shelf in ipairs(shelves:GetChildren()) do
                shelf:ClearAllChildren() -- Removes the item models
            end
        end
        
        -- Reset Sign
        local sign = plot:FindFirstChild("OwnerSign")
        if sign and sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui:FindFirstChild("TextLabel") then
            sign.SurfaceGui.TextLabel.Text = "Vacant"
        end
        
        self.ActivePlots[player] = nil
    end
end
-- Helper: Check if item is already placed on any shelf
function TycoonService:IsItemPlaced(player, itemUUID)
    local profile = DataService:GetProfile(player)
    if not profile then return false end
    for _, uuid in pairs(profile.Data.ShelfLayout) do
        if uuid == itemUUID then return true end
    end
    return false
end

-- Remove item from shelf
function TycoonService:RemoveItemFromShelf(player, shelfIndex)
    local profile = DataService:GetProfile(player)
    if not profile then return end
    profile.Data.ShelfLayout[tostring(shelfIndex)] = nil
    -- Remove visual
    local plot = self.ActivePlots[player]
    if plot then
        self:RemoveItem(player, shelfIndex)
    end
end

-- =============================================
-- PLACEMENT & VISUALS
-- =============================================

function TycoonService:PlaceItem(player, itemUUID, shelfIndex)
    -- 1. Validate Input
    if type(shelfIndex) ~= "number" or shelfIndex < 1 or shelfIndex > MAX_SHELVES then return end
    
    local profile = DataService:GetProfile(player)
    if not profile then return end
    
    -- 2. Validate Ownership
    local itemData = self:FindItemInInventory(profile.Data.Inventory, itemUUID)
    if not itemData then 
        warn(player.Name .. " tried to place invalid item.")
        return 
    end

    -- Enforce: 1 brainrot per shelf, 1 shelf per brainrot
    if self:IsItemPlaced(player, itemUUID) then
        warn("[TycoonService] Item already placed on a shelf!")
        return
    end

    -- If shelf already has a brainrot, block placement (force remove first)
    local existingUUID = profile.Data.ShelfLayout[tostring(shelfIndex)]
    if existingUUID then
        warn("[TycoonService] Shelf already occupied. Remove first.")
        return
    end

    -- 3. Update Data
    profile.Data.ShelfLayout[tostring(shelfIndex)] = itemUUID

    -- 4. Update Visuals & Ownership Enforcement
    local plot = self.ActivePlots[player]
    if not plot then
        warn("[TycoonService] No plot assigned for " .. player.Name)
        return
    end
    local shelves = plot:FindFirstChild("Shelves")
    if not shelves then
        warn("[TycoonService] No shelves found in plot for " .. player.Name)
        return
    end
    local shelf = shelves:FindFirstChild("Shelf_" .. tostring(shelfIndex))
    if not shelf then
        warn("[TycoonService] Shelf " .. shelfIndex .. " not found for " .. player.Name)
        return
    end
    -- Security: Only allow owner to place items
    if plot:GetAttribute("OwnerId") ~= player.UserId then
        warn("[TycoonService] Player " .. player.Name .. " tried to place item in a plot they don't own!")
        return
    end
    -- Only allow placement if shelf is inside player's assigned plot
    self:RenderShelf(plot, shelfIndex, itemData)
    -- Debug
    -- print(player.Name .. " placed " .. itemData.Model .. " on Shelf " .. shelfIndex)
end

-- Called by MarketService when an item is Quick Sold
function TycoonService:RemoveItem(player, shelfIndex)
    local plot = self.ActivePlots[player]
    if plot then
        local shelves = plot:FindFirstChild("Shelves")
        if shelves then
            local shelfPart = shelves:FindFirstChild("Shelf_" .. shelfIndex)
            if shelfPart then
                shelfPart:ClearAllChildren() -- Visual removal
            end
        end
    end
end

function TycoonService:RenderShelf(plot, shelfIndex, itemData)
    local shelvesFolder = plot:FindFirstChild("Shelves")
    if not shelvesFolder then return end
    
    local shelfPart = shelvesFolder:FindFirstChild("Shelf_" .. shelfIndex)
    if shelfPart then
        shelfPart:ClearAllChildren() -- Remove old item
        
        -- Clone Model from ReplicatedStorage
        local assets = ReplicatedStorage:FindFirstChild("Assets")
        if assets and assets:FindFirstChild("Models") then
            local modelTemplate = assets.Models:FindFirstChild(itemData.Model)
            
            if modelTemplate then
                local clone = modelTemplate:Clone()
                -- Position it on top of the shelf part
                clone:PivotTo(shelfPart.CFrame + Vector3.new(0, itemData.Size/2, 0))
                
                -- Apply Scale (If model has ScaleTo)
                if clone:IsA("Model") then
                    clone:ScaleTo(itemData.Size)
                elseif clone:IsA("BasePart") then
                    clone.Size = clone.Size * itemData.Size
                end
                
                clone.Parent = shelfPart
                
                -- Apply Element Visuals (Color/Material)
                self:ApplyElementVisuals(clone, itemData.Element)
            end
        end
    end
end

function TycoonService:ApplyElementVisuals(model, element)
    local color = nil
    local material = nil
    
    if element == "Gold" then
        color = Color3.fromRGB(255, 215, 0)
        material = Enum.Material.Metal
    elseif element == "Void" then
        color = Color3.fromRGB(50, 0, 100)
        material = Enum.Material.Neon
    elseif element == "Glitch" then
        color = Color3.fromRGB(255, 0, 0)
        material = Enum.Material.ForceField
    end
    
    if color then
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Color = color
                if material then part.Material = material end
            end
        end
    end
end

function TycoonService:RestoreShelves(player, plot)
    local profile = DataService:GetProfile(player)
    if not profile then return end
    
    for indexStr, uuid in pairs(profile.Data.ShelfLayout) do
        local itemData = self:FindItemInInventory(profile.Data.Inventory, uuid)
        if itemData then
            self:RenderShelf(plot, tonumber(indexStr), itemData)
        end
    end
end

-- =============================================
-- INCOME LOGIC (Loop)
-- =============================================

function TycoonService:ProcessIncome()
    for player, plot in pairs(self.ActivePlots) do
        local profile = DataService:GetProfile(player)
        if profile then
            local totalIncome = 0
            
            -- Calculate Income for each shelf
            for _, uuid in pairs(profile.Data.ShelfLayout) do
                local item = self:FindItemInInventory(profile.Data.Inventory, uuid)
                if item then
                    -- 1. Base Income
                    local baseIncome = math.floor(item.FloorPrice * 0.1)
                    
                    -- 2. Apply Event Multiplier
                    local multiplier = 1
                    if EventService then
                        multiplier = EventService:GetMultiplier(item)
                    end
                    
                    totalIncome += (baseIncome * multiplier)
                end
            end
            
            -- Add to Player Data
            if totalIncome > 0 then
                -- Defensive checks
                if not profile.Data.TotalEarned then profile.Data.TotalEarned = 0 end
                
                profile.Data.RizzCoins += totalIncome
                profile.Data.TotalEarned += totalIncome
                
                -- Replicate via Attributes (Efficient)
                player:SetAttribute("RizzCoins", profile.Data.RizzCoins)
                player:SetAttribute("IncomeRate", totalIncome)
            else
                player:SetAttribute("IncomeRate", 0)
            end
        end
    end
end

-- Helper
function TycoonService:FindItemInInventory(inventoryList, uuid)
    for _, item in ipairs(inventoryList) do
        if item.UUID == uuid then return item end
    end
    return nil
end

return TycoonService