local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)
local GameConstants = require(ReplicatedStorage.Configs.GameConstants)
local EventService = nil 

local TycoonService = {}
TycoonService.ActivePlots = {}

-- [FIX] Use Constant
local MAX_SHELVES = GameConstants.MAX_SHELVES

function TycoonService:Init()
    local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
    
    local placeEvent = remotesFolder:FindFirstChild(GameConstants.Events.PLACE_ITEM)
    if not placeEvent then
        placeEvent = Instance.new("RemoteEvent")
        placeEvent.Name = GameConstants.Events.PLACE_ITEM
        placeEvent.Parent = remotesFolder
    end
    
    placeEvent.OnServerEvent:Connect(function(player, itemUUID, shelfIndex)
        self:PlaceItem(player, itemUUID, shelfIndex)
    end)

    local removeEvent = remotesFolder:FindFirstChild(GameConstants.Events.REMOVE_ITEM_FROM_SHELF)
    if not removeEvent then
        removeEvent = Instance.new("RemoteEvent")
        removeEvent.Name = GameConstants.Events.REMOVE_ITEM_FROM_SHELF
        removeEvent.Parent = remotesFolder
    end
    removeEvent.OnServerEvent:Connect(function(player, shelfIndex)
        self:RemoveItemFromShelf(player, shelfIndex)
    end)
end

function TycoonService:Start()
    EventService = require(script.Parent.EventService)

    Players.PlayerAdded:Connect(function(player) self:AssignPlot(player) end)
    Players.PlayerRemoving:Connect(function(player) self:UnassignPlot(player) end)
    
    task.spawn(function()
        while true do
            self:ProcessIncome()
            task.wait(GameConstants.INCOME_TICK_RATE)
        end
    end)
    
    print("   -> TycoonService Started")
end

function TycoonService:AssignPlot(player)
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then return end

    for _, plot in ipairs(plotsFolder:GetChildren()) do
        if plot:GetAttribute("OwnerId") == nil then
            plot:SetAttribute("OwnerId", player.UserId)
            self.ActivePlots[player] = plot
            
            local sign = plot:FindFirstChild("OwnerSign")
            if sign and sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui:FindFirstChild("TextLabel") then
                sign.SurfaceGui.TextLabel.Text = player.Name .. "'s Market"
            end
            
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
        
        local shelves = plot:FindFirstChild("Shelves")
        if shelves then
            for _, shelf in ipairs(shelves:GetChildren()) do
                shelf:ClearAllChildren()
            end
        end
        
        local sign = plot:FindFirstChild("OwnerSign")
        if sign and sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui:FindFirstChild("TextLabel") then
            sign.SurfaceGui.TextLabel.Text = "Vacant"
        end
        
        self.ActivePlots[player] = nil
    end
end

function TycoonService:IsItemPlaced(player, itemUUID)
    local profile = DataService:GetProfile(player)
    if not profile then return false end
    for _, uuid in pairs(profile.Data.ShelfLayout) do
        if uuid == itemUUID then return true end
    end
    return false
end

function TycoonService:RemoveItemFromShelf(player, shelfIndex)
    local profile = DataService:GetProfile(player)
    if not profile then return end
    
    -- Convert number to string key for dictionary
    profile.Data.ShelfLayout[tostring(shelfIndex)] = nil
    
    self:RemoveItem(player, shelfIndex)
end

function TycoonService:PlaceItem(player, itemUUID, shelfIndex)
    if type(shelfIndex) ~= "number" or shelfIndex < 1 or shelfIndex > MAX_SHELVES then return end
    
    local profile = DataService:GetProfile(player)
    if not profile then return end
    
    local itemData = self:FindItemInInventory(profile.Data.Inventory, itemUUID)
    if not itemData then return end

    if self:IsItemPlaced(player, itemUUID) then return end

    local existingUUID = profile.Data.ShelfLayout[tostring(shelfIndex)]
    if existingUUID then return end

    profile.Data.ShelfLayout[tostring(shelfIndex)] = itemUUID

    local plot = self.ActivePlots[player]
    if plot and plot:GetAttribute("OwnerId") == player.UserId then
        self:RenderShelf(plot, shelfIndex, itemData)
    end
end

function TycoonService:RemoveItem(player, shelfIndex)
    local plot = self.ActivePlots[player]
    if plot then
        local shelves = plot:FindFirstChild("Shelves")
        if shelves then
            local shelfPart = shelves:FindFirstChild("Shelf_" .. shelfIndex)
            if shelfPart then shelfPart:ClearAllChildren() end
        end
    end
end

function TycoonService:RenderShelf(plot, shelfIndex, itemData)
    local shelvesFolder = plot:FindFirstChild("Shelves")
    if not shelvesFolder then return end
    
    local shelfPart = shelvesFolder:FindFirstChild("Shelf_" .. shelfIndex)
    if shelfPart then
        shelfPart:ClearAllChildren()
        
        local assets = ReplicatedStorage:FindFirstChild("Assets")
        if assets and assets:FindFirstChild("Models") then
            local modelTemplate = assets.Models:FindFirstChild(itemData.Model)
            if modelTemplate then
                local clone = modelTemplate:Clone()
                clone:PivotTo(shelfPart.CFrame + Vector3.new(0, itemData.Size/2, 0))
                
                if clone:IsA("Model") then clone:ScaleTo(itemData.Size)
                elseif clone:IsA("BasePart") then clone.Size = clone.Size * itemData.Size end
                
                clone.Parent = shelfPart
                self:ApplyElementVisuals(clone, itemData.Element)
            end
        end
    end
end

function TycoonService:ApplyElementVisuals(model, element)
    local color, material
    if element == "Gold" then color, material = Color3.fromRGB(255, 215, 0), Enum.Material.Metal
    elseif element == "Void" then color, material = Color3.fromRGB(50, 0, 100), Enum.Material.Neon
    elseif element == "Glitch" then color, material = Color3.fromRGB(255, 0, 0), Enum.Material.ForceField end
    
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

function TycoonService:ProcessIncome()
    for player, plot in pairs(self.ActivePlots) do
        local profile = DataService:GetProfile(player)
        if profile then
            local totalIncome = 0
            
            for _, uuid in pairs(profile.Data.ShelfLayout) do
                local item = self:FindItemInInventory(profile.Data.Inventory, uuid)
                if item then
                    local baseIncome = math.floor(item.FloorPrice * 0.1)
                    local multiplier = EventService and EventService:GetMultiplier(item) or 1
                    totalIncome += (baseIncome * multiplier)
                end
            end
            
            if totalIncome > 0 then
                if not profile.Data.TotalEarned then profile.Data.TotalEarned = 0 end
                profile.Data.RizzCoins += totalIncome
                profile.Data.TotalEarned += totalIncome
                player:SetAttribute("RizzCoins", profile.Data.RizzCoins)
            end
            player:SetAttribute("IncomeRate", totalIncome)
        end
    end
end

function TycoonService:FindItemInInventory(inventoryList, uuid)
    for _, item in ipairs(inventoryList) do
        if item.UUID == uuid then return item end
    end
    return nil
end

return TycoonService