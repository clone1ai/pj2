local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- PATHS
local NetFolder = ReplicatedStorage:WaitForChild("Net")
local Remotes = require(NetFolder:WaitForChild("Remotes"))

local Assets = ReplicatedStorage:WaitForChild("Assets")
local BrainsFolder = Assets:WaitForChild("Brains")

local UI = script.Parent.Parent:WaitForChild("UI")
local InventoryUI = require(UI:WaitForChild("InventoryUI"))

local InventoryController = {}

-- State
local Items = {} 
local SelectedItem = nil
local RotationConnection = nil 

-- Remotes
local EquipRF = Remotes.GetRemoteFunction("EquipItem")
local QuickSellRF = Remotes.GetRemoteFunction("QuickSell")
local ListMarketRF = Remotes.GetRemoteFunction("ListOnMarket")
local GetInvRF = Remotes.GetRemoteFunction("GetInventoryData")

-- Helper: Render 3D Preview
local function UpdatePreview(viewport, itemName, modelName)
    viewport:ClearAllChildren()
    if RotationConnection then 
        RotationConnection:Disconnect() 
        RotationConnection = nil
    end
    
    local modelAsset = BrainsFolder:FindFirstChild(itemName) or BrainsFolder:FindFirstChild(modelName)
    if not modelAsset then return end 
    
    local clone = modelAsset:Clone()
    clone.Parent = viewport
    
    local cam = Instance.new("Camera")
    viewport.CurrentCamera = cam
    cam.Parent = viewport
    
    local cf, size = clone:GetBoundingBox()
    local maxDim = math.max(size.X, size.Y, size.Z)
    local distance = maxDim * 2.5 
    
    local angle = 0
    RotationConnection = RunService.RenderStepped:Connect(function(dt)
        angle = angle + dt 
        local rotCFrame = CFrame.Angles(0, angle, 0)
        cam.CFrame = CFrame.new(cf.Position + (rotCFrame.LookVector * distance) + Vector3.new(0, size.Y/2, 0), cf.Position)
    end)
end

function InventoryController.Start()
    print("[InventoryController] Started")
    local uiRef = InventoryUI.Create()
    
    -- [CRITICAL FIX] Initial Data Load with Retry
    uiRef.Buttons.Toggle.Text = "LOAD..." -- Visual indicator
    task.spawn(function()
        InventoryController.RefreshInventory(uiRef)
        uiRef.Buttons.Toggle.Text = "BAG" -- Reset text when done
    end)
    
    -- TOGGLE VISIBILITY LOGIC
    uiRef.Buttons.Toggle.MouseButton1Click:Connect(function()
        uiRef.MainFrame.Visible = not uiRef.MainFrame.Visible
        if uiRef.MainFrame.Visible then
            InventoryController.RefreshInventory(uiRef) 
        end
    end)

    -- CLOSE BUTTON LOGIC
    uiRef.Buttons.Close.MouseButton1Click:Connect(function()
        uiRef.MainFrame.Visible = false
    end)
    
    -- 1. ACTION: EQUIP / HOLD
    uiRef.Buttons.Equip.MouseButton1Click:Connect(function()
        if not SelectedItem then return end
        
        local status = EquipRF:InvokeServer(SelectedItem.Id)
        
        if status == "Equipped" then
            uiRef.Buttons.Equip.Text = "UNHOLD"
            uiRef.Buttons.Equip.BackgroundColor3 = Color3.fromRGB(230, 126, 34) 
        else
            uiRef.Buttons.Equip.Text = "HOLD"
            uiRef.Buttons.Equip.BackgroundColor3 = Color3.fromRGB(52, 152, 219) 
        end
    end)
    
    -- 2. ACTION: QUICK SELL
    uiRef.Buttons.QuickSell.MouseButton1Click:Connect(function()
        if not SelectedItem then return end
        local result = QuickSellRF:InvokeServer(SelectedItem.Id)
        if result.Success then
            print("Sold for $" .. result.Cash)
            InventoryController.RefreshInventory(uiRef)
            
            uiRef.Labels.Name.Text = "Select Item"
            uiRef.Labels.Price.Text = ""
            uiRef.Viewport:ClearAllChildren()
            SelectedItem = nil
        end
    end)

    -- 3. ACTION: MARKET POPUP
    uiRef.Buttons.Market.MouseButton1Click:Connect(function()
        if not SelectedItem then return end
        uiRef.Popup.Visible = true
        uiRef.Input.Text = tostring(SelectedItem.FloorPrice) 
    end)
    
    uiRef.ClosePopup.MouseButton1Click:Connect(function()
        uiRef.Popup.Visible = false
    end)

    -- 4. ACTION: CONFIRM LISTING
    uiRef.Buttons.ConfirmList.MouseButton1Click:Connect(function()
        if not SelectedItem then return end
        local price = tonumber(uiRef.Input.Text)
        if not price then return end
        
        local result = ListMarketRF:InvokeServer(SelectedItem.Id, price)
        if result.Success then
            print("Item Listed!")
            uiRef.Popup.Visible = false
            InventoryController.RefreshInventory(uiRef)
            SelectedItem = nil
        else
            warn(result.Msg)
        end
    end)
end

function InventoryController.RefreshInventory(uiRef)
    local data = nil
    
    -- [CRITICAL FIX] Retry Loop: Wait until server sends data
    -- If data is nil, it means ProfileService is still loading
    while data == nil do
        data = GetInvRF:InvokeServer()
        if data == nil then
            -- Wait 1 second before trying again
            task.wait(1)
        end
    end
    
    Items = data
    InventoryController.RenderGrid(uiRef)
end

function InventoryController.RenderGrid(uiRef)
    for _, child in pairs(uiRef.Grid:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    table.sort(Items, function(a, b) return a.Created > b.Created end)
    
    for _, item in ipairs(Items) do
        local btn = Instance.new("TextButton")
        btn.Parent = uiRef.Grid
        btn.Text = item.Name .. "\n$" .. item.FloorPrice
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        
        if item.Element == "Gold" then btn.BackgroundColor3 = Color3.fromRGB(241, 196, 15) end
        if item.Element == "Void" then btn.BackgroundColor3 = Color3.fromRGB(142, 68, 173) end
        if item.Element == "Glitch" then btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113) end

        btn.MouseButton1Click:Connect(function()
            SelectedItem = item
            uiRef.Labels.Name.Text = item.Name
            uiRef.Labels.Price.Text = "Floor: $" .. item.FloorPrice
            
            uiRef.Buttons.QuickSell.Text = "SELL: $" .. math.floor(item.FloorPrice * 0.5)
            
            UpdatePreview(uiRef.Viewport, item.Name, item.Model)
            
            uiRef.Buttons.Equip.Text = "HOLD"
            uiRef.Buttons.Equip.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
        end)
    end
end

return InventoryController