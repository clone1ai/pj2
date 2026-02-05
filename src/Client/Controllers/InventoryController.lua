local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryController = {}

-- PATHS
local NetFolder = ReplicatedStorage:WaitForChild("Net")
local Remotes = require(NetFolder:WaitForChild("Remotes"))
local UI = script.Parent.Parent:WaitForChild("UI")
local InventoryUI = require(UI:WaitForChild("InventoryUI"))

local Assets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Brains")

-- State
local Items = {} 
local SelectedItem = nil

-- Remotes
local EquipRF = Remotes.GetRemoteFunction("EquipItem")
local QuickSellRF = Remotes.GetRemoteFunction("QuickSell")
local ListMarketRF = Remotes.GetRemoteFunction("ListOnMarket")
local GetInvRF = Remotes.GetRemoteFunction("GetInventoryData")

function InventoryController.Start()
    print("[InventoryController] Started")
    local uiRef = InventoryUI.Create()
    
    -- Helper: Reset Right Panel
    local function ClearSelection()
        SelectedItem = nil
        uiRef.Details.Name.Text = "Select an Item"
        uiRef.Details.Price.Text = "Value: ---"
        uiRef.Details.UID.Text = "UID: ---"
        uiRef.Details.Element.Text = "Element: ---"
        uiRef.Details.Model.Text = "Model: ---"
        uiRef.Details.Size.Text = "Size: ---"
        
        -- Reset Buttons
        uiRef.Details.Buttons.Equip.Text = "HOLD ITEM"
        uiRef.Details.Buttons.Equip.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
        uiRef.Details.Buttons.Sell.Text = "QUICK SELL"
        uiRef.Details.Buttons.List.Text = "LIST ON MARKET"
    end

    -- 1. Initial Load
    task.spawn(function()
        uiRef.Toggle.Text = "LOADING..."
        InventoryController.RefreshInventory(uiRef)
        uiRef.Toggle.Text = "BAG"
    end)
    
    -- 2. Toggle UI
    uiRef.Toggle.MouseButton1Click:Connect(function()
        uiRef.Frame.Visible = not uiRef.Frame.Visible
        if uiRef.Frame.Visible then
            InventoryController.RefreshInventory(uiRef) 
            ClearSelection()
        end
    end)

    -- 3. Close UI
    uiRef.Close.MouseButton1Click:Connect(function()
        uiRef.Frame.Visible = false
    end)
    
    -- 4. ACTION: EQUIP
    uiRef.Details.Buttons.Equip.MouseButton1Click:Connect(function()
        if not SelectedItem then return end
        
        local status = EquipRF:InvokeServer(SelectedItem.Id)
        
        if status == "Equipped" then
            uiRef.Details.Buttons.Equip.Text = "UNEQUIP"
            uiRef.Details.Buttons.Equip.BackgroundColor3 = Color3.fromRGB(230, 126, 34) -- Orange
        else
            uiRef.Details.Buttons.Equip.Text = "HOLD ITEM"
            uiRef.Details.Buttons.Equip.BackgroundColor3 = Color3.fromRGB(52, 152, 219) -- Blue
        end
    end)
    
    -- 5. ACTION: SELL
    uiRef.Details.Buttons.Sell.MouseButton1Click:Connect(function()
        if not SelectedItem then return end
        local result = QuickSellRF:InvokeServer(SelectedItem.Id)
        if result.Success then
            print("Sold for $" .. result.Cash)
            InventoryController.RefreshInventory(uiRef)
            ClearSelection()
        end
    end)

    -- 6. ACTION: MARKET POPUP
    uiRef.Details.Buttons.List.MouseButton1Click:Connect(function()
        if not SelectedItem then return end
        uiRef.Popup.Frame.Visible = true
        uiRef.Popup.Input.Text = tostring(SelectedItem.FloorPrice) 
    end)
    
    uiRef.Popup.Close.MouseButton1Click:Connect(function()
        uiRef.Popup.Frame.Visible = false
    end)

    -- 7. ACTION: CONFIRM LISTING
    uiRef.Popup.Confirm.MouseButton1Click:Connect(function()
        if not SelectedItem then return end
        local price = tonumber(uiRef.Popup.Input.Text)
        if not price then return end
        
        uiRef.Popup.Confirm.Text = "LISTING..."
        local result = ListMarketRF:InvokeServer(SelectedItem.Id, price)
        
        if result.Success then
            print("Item Listed!")
            uiRef.Popup.Frame.Visible = false
            InventoryController.RefreshInventory(uiRef)
            ClearSelection()
        else
            warn(result.Msg)
            uiRef.Popup.Confirm.Text = "FAILED"
            task.wait(1)
        end
        uiRef.Popup.Confirm.Text = "CONFIRM"
    end)
end

function InventoryController.RefreshInventory(uiRef)
    local data = GetInvRF:InvokeServer()
    if data then
        Items = data
        InventoryController.RenderGrid(uiRef)
    end
end

function InventoryController.RenderGrid(uiRef)
    -- Clear Grid
    for _, child in pairs(uiRef.Grid:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
    end
    
    table.sort(Items, function(a, b) return a.Created > b.Created end)
    
    for _, item in ipairs(Items) do
        -- 1. Create Card Container
        local card = Instance.new("TextButton")
        card.Text = ""
        card.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        card.ZIndex = 10 
        card.Parent = uiRef.Grid
        
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(70, 70, 70)
        stroke.Thickness = 1
        stroke.Parent = card
        
        -- 2. VIEWPORT FRAME (3D Model)
        local viewport = Instance.new("ViewportFrame")
        viewport.Size = UDim2.new(1, 0, 0.7, 0)
        viewport.Position = UDim2.new(0, 0, 0, 10)
        viewport.BackgroundTransparency = 1
        viewport.LightColor = Color3.fromRGB(255, 255, 255)
        viewport.Ambient = Color3.fromRGB(150, 150, 150)
        viewport.ZIndex = 11
        viewport.Parent = card
        
        -- Clone Asset
        local originalModel = Assets:FindFirstChild(item.Model)
        if originalModel then
            local clone = originalModel:Clone()
            clone.Parent = viewport
            
            -- Camera Setup
            local cam = Instance.new("Camera")
            viewport.CurrentCamera = cam
            cam.Parent = viewport
            
            local cf, size = clone:GetBoundingBox()
            local maxDim = math.max(size.X, size.Y, size.Z)
            local dist = maxDim * 1.5
            cam.CFrame = CFrame.new(cf.Position + Vector3.new(dist, dist*0.5, dist), cf.Position)
        end
        
        -- 3. Item Name Overlay
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Text = item.Name
        nameLbl.Size = UDim2.new(1, -10, 0, 20)
        nameLbl.Position = UDim2.new(0, 5, 0, 5)
        nameLbl.BackgroundTransparency = 1
        nameLbl.TextColor3 = Color3.new(1,1,1)
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 11
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.ZIndex = 12
        nameLbl.Parent = card
        
        -- 4. Price/Element Pill
        local pill = Instance.new("Frame")
        pill.Size = UDim2.new(0.9, 0, 0, 30)
        pill.Position = UDim2.new(0.05, 0, 0.8, -5)
        pill.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        pill.ZIndex = 11
        pill.Parent = card
        Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 6)
        
        local infoLbl = Instance.new("TextLabel")
        infoLbl.Text = item.Element
        infoLbl.Size = UDim2.new(1, 0, 1, 0)
        infoLbl.BackgroundTransparency = 1
        infoLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        
        -- Element Colors
        if item.Element == "Gold" then infoLbl.TextColor3 = Color3.fromRGB(241, 196, 15) end
        if item.Element == "Void" then infoLbl.TextColor3 = Color3.fromRGB(142, 68, 173) end
        if item.Element == "Glitch" then infoLbl.TextColor3 = Color3.fromRGB(46, 204, 113) end
        
        infoLbl.Font = Enum.Font.GothamBold
        infoLbl.TextSize = 14
        infoLbl.ZIndex = 12
        infoLbl.Parent = pill

        -- 5. Selection Logic
        card.MouseButton1Click:Connect(function()
            SelectedItem = item
            
            -- Populate Details
            uiRef.Details.Name.Text = item.Name
            uiRef.Details.Price.Text = "Value: $" .. item.FloorPrice
            uiRef.Details.UID.Text = "UID: " .. (item.Id:sub(1,8) .. "...") -- Shorten UID
            uiRef.Details.Element.Text = "Element: " .. item.Element
            uiRef.Details.Model.Text = "Model: " .. item.Model
            uiRef.Details.Size.Text = "Size: " .. string.format("%.1f", item.Size or 1)
            
            -- Update Sell Button Text
            uiRef.Details.Buttons.Sell.Text = "SELL: $" .. math.floor(item.FloorPrice * 0.5)
            uiRef.Details.Buttons.Equip.Text = "HOLD ITEM" -- Reset equip status visuals
            uiRef.Details.Buttons.Equip.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
        end)
    end
end

return InventoryController