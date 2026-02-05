local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

-- PATHS
local NetFolder = ReplicatedStorage:WaitForChild("Net")
local Remotes = require(NetFolder:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local SynergyService = require(script.Parent:WaitForChild("SynergyService")) -- [NEW]

local Assets = ReplicatedStorage:WaitForChild("Assets")
local BrainsFolder = Assets:WaitForChild("Brains")

local FarmService = {}

-- STATE
local FarmsFolder = nil
local PlayerFarms = {} 
local FarmOwnership = {} 

-- CONSTANTS
local MAX_SLOTS = 6
local INCOME_RATE = 0.1 

-- REMOTES
local PlaceRF = Remotes.GetRemoteFunction("PlaceItem")
local PickupRF = Remotes.GetRemoteFunction("PickupItem")

function FarmService.Start()
    print("[FarmService] Started")
    
    -- 1. Generate Map INSTANTLY
    FarmService.SetupMap()

    -- 2. Handle Joins
    Players.PlayerAdded:Connect(function(player)
        FarmService.AssignFarm(player)
    end)
    
    for _, player in ipairs(Players:GetPlayers()) do
        FarmService.AssignFarm(player)
    end

    Players.PlayerRemoving:Connect(function(player)
        FarmService.ReleaseFarm(player)
    end)

    -- 3. Income Loop
    task.spawn(function()
        while true do
            task.wait(1)
            FarmService.DistributeIncome()
        end
    end)

    -- 4. Remotes
    PlaceRF.OnServerInvoke = function(player, itemId, targetFarm)
        return FarmService.AttemptPlace(player, itemId, targetFarm)
    end

    PickupRF.OnServerInvoke = function(player, targetModel)
        return FarmService.AttemptPickup(player, targetModel)
    end
end

-- =============================================
-- MAP GENERATION
-- =============================================
function FarmService.SetupMap()
    FarmsFolder = Workspace:FindFirstChild("Farms")
    
    if not FarmsFolder then
        FarmsFolder = Instance.new("Folder")
        FarmsFolder.Name = "Farms"
        FarmsFolder.Parent = Workspace
        
        for i = 1, 8 do
            local farm = Instance.new("Model")
            farm.Name = "Farm" .. i
            
            local bounds = Instance.new("Part")
            bounds.Name = "Bounds"
            bounds.Size = Vector3.new(25, 1, 25)
            bounds.Position = Vector3.new((i * 35), 0.5, 0) 
            bounds.Anchored = true
            bounds.CanCollide = true
            bounds.Material = Enum.Material.Grass
            bounds.Color = Color3.fromRGB(46, 204, 113) 
            bounds.Parent = farm
            
            -- Label
            local bb = Instance.new("BillboardGui")
            bb.Name = "InfoParams"
            bb.Size = UDim2.new(0,100,0,50)
            bb.StudsOffset = Vector3.new(0, 5, 0)
            bb.AlwaysOnTop = true
            bb.Parent = bounds
            
            local txt = Instance.new("TextLabel", bb)
            txt.Size = UDim2.fromScale(1,1)
            txt.BackgroundTransparency = 1
            txt.TextColor3 = Color3.new(1,1,1)
            txt.TextStrokeTransparency = 0
            txt.TextSize = 20
            txt.Font = Enum.Font.GothamBlack
            txt.Text = "Farm #" .. i
            
            farm.Parent = FarmsFolder
        end
    end
end

-- =============================================
-- FARM MANAGEMENT
-- =============================================

function FarmService.AssignFarm(player)
    if PlayerFarms[player] then return end

    while not FarmsFolder or #FarmsFolder:GetChildren() < 8 do task.wait(0.1) end

    for _, farm in ipairs(FarmsFolder:GetChildren()) do
        if not FarmOwnership[farm] then
            FarmOwnership[farm] = player
            PlayerFarms[player] = farm
            
            farm:SetAttribute("OwnerName", player.Name)
            
            local bounds = farm:FindFirstChild("Bounds")
            if bounds then
                local bb = bounds:FindFirstChild("InfoParams")
                if bb then bb.TextLabel.Text = player.Name .. "'s Farm" bb.TextLabel.TextColor3 = Color3.fromRGB(52, 152, 219) end
                bounds.Color = Color3.fromRGB(52, 152, 219)
            end
            
            FarmService.LoadFarmData(player)
            return
        end
    end
end

function FarmService.ReleaseFarm(player)
    local farm = PlayerFarms[player]
    if farm then
        -- Destroy Carriers (which contain the models)
        for _, child in pairs(farm:GetChildren()) do
            if child.Name == "Carrier" then child:Destroy() end
        end
        
        farm:SetAttribute("OwnerName", nil)
        
        local bounds = farm:FindFirstChild("Bounds")
        if bounds then
            local bb = bounds:FindFirstChild("InfoParams")
            if bb then bb.TextLabel.Text = "Vacant Farm" bb.TextLabel.TextColor3 = Color3.new(1,1,1) end
            bounds.Color = Color3.fromRGB(46, 204, 113)
        end
        
        FarmOwnership[farm] = nil
        PlayerFarms[player] = nil
    end
end

function FarmService.LoadFarmData(player)
    local profile = DataService.GetProfile(player)
    local attempts = 0
    while not profile and attempts < 10 do task.wait(0.5) profile = DataService.GetProfile(player) attempts += 1 end
    
    if not profile then return end
    local farm = PlayerFarms[player]
    if not farm then return end

    if profile.Data.Farm then
        for _, itemData in ipairs(profile.Data.Farm) do
            FarmService.SpawnVisual(farm, itemData)
        end
    end
end

-- =============================================
-- LOGIC: PLACEMENT & PICKUP
-- =============================================

function FarmService.AttemptPlace(player, itemId, targetFarm)
    local profile = DataService.GetProfile(player)
    local myFarm = PlayerFarms[player]
    
    if not profile or not profile.Data then return {Success = false, Msg = "Loading..."} end
    if targetFarm ~= myFarm then return {Success = false, Msg = "Not your farm!"} end
    
    local currentCount = 0
    for _, _ in pairs(profile.Data.Farm) do currentCount += 1 end
    if currentCount >= MAX_SLOTS then return {Success = false, Msg = "Farm Full (Max 6)"} end

    local invIndex, itemData
    for i, item in ipairs(profile.Data.Inventory) do
        if item.Id == itemId then invIndex = i itemData = item break end
    end

    if not itemData then return {Success = false, Msg = "Item not found"} end

    table.remove(profile.Data.Inventory, invIndex)
    table.insert(profile.Data.Farm, itemData)
    
    FarmService.SpawnVisual(myFarm, itemData)
    
    local char = player.Character
    if char then
        local tool = char:FindFirstChildWhichIsA("Tool")
        if tool and tool:GetAttribute("ItemId") == itemId then tool:Destroy() end
    end

    return {Success = true}
end

function FarmService.AttemptPickup(player, targetModel)
    local profile = DataService.GetProfile(player)
    local myFarm = PlayerFarms[player]
    
    if not profile or not profile.Data then return {Success = false, Msg = "Loading..."} end
    
    -- Target is usually the Brainrot Model, but we need to destroy the Carrier
    local carrier = targetModel:FindFirstAncestor("Carrier")
    if not carrier or not carrier:IsDescendantOf(myFarm) then
        return {Success = false, Msg = "Invalid Target"}
    end

    local char = player.Character
    if char:FindFirstChildWhichIsA("Tool") then return {Success = false, Msg = "Hand must be empty!"} end

    local guid = targetModel:GetAttribute("GUID")
    local farmIndex, itemData

    for i, item in ipairs(profile.Data.Farm) do
        if item.Id == guid then farmIndex = i itemData = item break end
    end

    if not itemData then return {Success = false, Msg = "Data Sync Error"} end

    table.remove(profile.Data.Farm, farmIndex)
    table.insert(profile.Data.Inventory, itemData)
    
    carrier:Destroy() -- Destroy the invisible carrier (removes model too)

    return {Success = true}
end

-- =============================================
-- SPAWNING & AI (FLOATING VERSION)
-- =============================================

function FarmService.SpawnVisual(farm, itemData)
    local asset = BrainsFolder:FindFirstChild(itemData.Name) or BrainsFolder:FindFirstChild(itemData.Model)
    if not asset then return end

    -- 1. Create the Invisible Walker (Carrier)
    local carrier = Instance.new("Part")
    carrier.Name = "Carrier"
    carrier.Size = Vector3.new(2, 2, 2)
    carrier.Transparency = 1 -- Invisible
    
    -- [CRITICAL FIX] Must be TRUE so it stands on the floor
    carrier.CanCollide = true 
    carrier.Anchored = false
    carrier.Parent = farm
    
    -- Physics Settings for Carrier
    local hum = Instance.new("Humanoid")
    hum.HipHeight = 1.5 -- Levitate slightly so it doesn't scrape the floor
    hum.Parent = carrier

    -- Random Start Position
    local bounds = farm:FindFirstChild("Bounds")
    local startPos = bounds.Position + Vector3.new(math.random(-10,10), 5, math.random(-10,10)) -- Spawn 5 studs up
    carrier.CFrame = CFrame.new(startPos)

    -- 2. Create the Visual Brainrot
    local clone = asset:Clone()
    clone.Name = "Visual"
    clone:SetAttribute("IsBrainrot", true) 
    clone:SetAttribute("GUID", itemData.Id) 
    
    if not clone.PrimaryPart then
        clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart") or clone:GetChildren()[1]
    end
    
    if clone:IsA("Model") then clone:ScaleTo(itemData.Size or 1.0) end

    -- Visual Physics (Must NOT collide)
    for _, part in pairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            part.CanCollide = false -- Visuals pass through players
            part.Massless = true    -- Don't weigh down the carrier
        end
    end
    
    clone.Parent = carrier 

    -- 3. Connect via Motor6D
    local motor = Instance.new("Motor6D")
    motor.Name = "FloaterMotor"
    motor.Part0 = carrier
    motor.Part1 = clone.PrimaryPart
    motor.C0 = CFrame.new(0, 3.5, 0) 
    motor.Parent = clone.PrimaryPart
    
    -- 4. Tag for Client Animation
    CollectionService:AddTag(motor, "FloatingBrainrot")

    -- 5. Start Walking AI
    FarmService.InjectAI(carrier, bounds)
end

function FarmService.InjectAI(carrier, boundsPart)
    local hum = carrier:FindFirstChild("Humanoid")
    
    task.spawn(function()
        while carrier.Parent do
            local rX = math.random(-10, 10)
            local rZ = math.random(-10, 10)
            local targetPos = boundsPart.Position + Vector3.new(rX, 0, rZ)
            
            hum:MoveTo(targetPos)
            hum.MoveToFinished:Wait()
            task.wait(math.random(2, 5))
        end
    end)
end

function FarmService.DistributeIncome()
    -- Get Active Event Info
    local buff = SynergyService.GetCurrentBuffs()
    
    for player, farm in pairs(PlayerFarms) do
        local profile = DataService.GetProfile(player)
        if profile and profile.Data then
            local totalIncome = 0
            local inventory = profile.Data.Farm
            
            -- CHECK COMBO REQUIREMENTS (Pre-scan)
            local hasComboModel = false
            local hasComboElem = false
            
            if buff and buff.Type == "Combo" then
                for _, item in ipairs(inventory) do
                    if item.Model == buff.Target1 then hasComboModel = true end
                    if item.Element == buff.Target2 then hasComboElem = true end
                end
            end
            
            local isComboActive = (hasComboModel and hasComboElem)
            
            -- CALCULATE INCOME PER ITEM
            for _, item in ipairs(inventory) do
                local baseIncome = math.floor(item.FloorPrice * INCOME_RATE)
                local finalIncome = baseIncome
                
                if buff then
                    if buff.Type == "Single" then
                        -- Single Element Check
                        if item.Element == buff.Target1 then
                            finalIncome = baseIncome * buff.Multiplier
                        end
                        
                    elseif buff.Type == "Combo" and isComboActive then
                        -- Combo Check: Apply only to items contributing to the synergy
                        -- (Rules said: "both generate x20". We apply to the matching types.)
                        if item.Model == buff.Target1 or item.Element == buff.Target2 then
                            finalIncome = baseIncome * buff.Multiplier
                        end
                    end
                end
                
                totalIncome += finalIncome
            end
            
            if totalIncome > 0 then
                DataService.AdjustCurrency(player, totalIncome)
            end
            
            -- Sync Rate to Client (for HUD)
            player:SetAttribute("IncomeRate", totalIncome)
        end
    end
end

return FarmService