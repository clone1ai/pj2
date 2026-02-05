local Players = game:GetService("Players")
local InventoryUI = {}

function InventoryUI.Create()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "InventoryGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- [NEW] HUD Toggle Button (Always Visible)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleInventory"
    toggleBtn.Size = UDim2.new(0, 100, 0, 50)
    toggleBtn.Position = UDim2.new(0, 20, 0.5, -25) -- Left Center
    toggleBtn.BackgroundColor3 = Color3.fromRGB(41, 128, 185) -- Blue
    toggleBtn.Text = "BAG"
    toggleBtn.Font = Enum.Font.GothamBlack
    toggleBtn.TextSize = 20
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    toggleBtn.Parent = screenGui
    
    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 8)
    uicorner.Parent = toggleBtn

    -- 1. Main Background (Hidden by Default)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 600, 0, 400)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false -- [CHANGE] Hidden by default
    mainFrame.Parent = screenGui
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Text = "INVENTORY"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 20
    title.TextColor3 = Color3.new(1,1,1)
    title.Size = UDim2.new(1,0,0.1,0)
    title.BackgroundTransparency = 1
    title.Parent = mainFrame
    
    -- Close Button (Top Right)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "X"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.Parent = mainFrame
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

    -- 2. Scrolling Grid
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "Grid"
    scrollFrame.Size = UDim2.new(0.6, 0, 0.8, 0)
    scrollFrame.Position = UDim2.new(0.05, 0, 0.12, 0)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.Parent = mainFrame
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 80, 0, 80)
    gridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
    gridLayout.Parent = scrollFrame

    -- 3. Detail Panel (Right Side)
    local detailsFrame = Instance.new("Frame")
    detailsFrame.Name = "Details"
    detailsFrame.Size = UDim2.new(0.3, 0, 0.8, 0)
    detailsFrame.Position = UDim2.new(0.67, 0, 0.12, 0)
    detailsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    detailsFrame.BorderSizePixel = 0
    detailsFrame.Parent = mainFrame
    
    -- 3D Preview Window
    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "PreviewViewport"
    viewport.Size = UDim2.new(0.9, 0, 0.35, 0)
    viewport.Position = UDim2.new(0.05, 0, 0.02, 0)
    viewport.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    viewport.BorderSizePixel = 0
    viewport.Parent = detailsFrame
    
    -- Info Labels
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "ItemName"
    nameLabel.Size = UDim2.new(1, 0, 0.1, 0)
    nameLabel.Position = UDim2.new(0, 0, 0.4, 0)
    nameLabel.Text = "Select Item"
    nameLabel.TextColor3 = Color3.new(1,1,1)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.Parent = detailsFrame
    
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "FloorPrice"
    priceLabel.Position = UDim2.new(0,0,0.5,0)
    priceLabel.Size = UDim2.new(1, 0, 0.08, 0)
    priceLabel.Text = ""
    priceLabel.TextColor3 = Color3.fromRGB(241, 196, 15)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Font = Enum.Font.Gotham
    priceLabel.Parent = detailsFrame

    -- 4. Action Buttons
    local function createBtn(name, text, color, yPos)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Text = text
        btn.BackgroundColor3 = color
        btn.Size = UDim2.new(0.9, 0, 0.12, 0)
        btn.Position = UDim2.new(0.05, 0, yPos, 0)
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Parent = detailsFrame
        return btn
    end

    local equipBtn = createBtn("EquipBtn", "HOLD", Color3.fromRGB(52, 152, 219), 0.60)
    local quickSellBtn = createBtn("QuickSellBtn", "QUICK SELL", Color3.fromRGB(231, 76, 60), 0.73)
    local marketBtn = createBtn("MarketBtn", "ADD TO MARKET", Color3.fromRGB(46, 204, 113), 0.86)

    -- 5. Market Input Popup
    local popup = Instance.new("Frame")
    popup.Name = "MarketPopup"
    popup.Size = UDim2.new(1, 0, 1, 0)
    popup.BackgroundColor3 = Color3.new(0,0,0)
    popup.BackgroundTransparency = 0.2
    popup.Visible = false
    popup.ZIndex = 5
    popup.Parent = mainFrame
    
    local popupFrame = Instance.new("Frame")
    popupFrame.Size = UDim2.new(0.6, 0, 0.5, 0)
    popupFrame.Position = UDim2.new(0.2, 0, 0.25, 0)
    popupFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
    popupFrame.Parent = popup

    local input = Instance.new("TextBox")
    input.Name = "PriceInput"
    input.Size = UDim2.new(0.8, 0, 0.3, 0)
    input.Position = UDim2.new(0.1, 0, 0.2, 0)
    input.PlaceholderText = "Set Price..."
    input.Text = "" 
    input.Parent = popupFrame
    
    local confirmBtn = Instance.new("TextButton")
    confirmBtn.Name = "ConfirmList"
    confirmBtn.Text = "CONFIRM LISTING"
    confirmBtn.Size = UDim2.new(0.8, 0, 0.3, 0)
    confirmBtn.Position = UDim2.new(0.1, 0, 0.6, 0)
    confirmBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    confirmBtn.Parent = popupFrame
    
    local closePopup = Instance.new("TextButton")
    closePopup.Text = "X"
    closePopup.Size = UDim2.new(0,30,0,30)
    closePopup.Position = UDim2.new(1,-30,0,0)
    closePopup.BackgroundColor3 = Color3.fromRGB(200,50,50)
    closePopup.Parent = popupFrame

    return {
        Screen = screenGui,
        MainFrame = mainFrame, -- [EXPORTED]
        Grid = scrollFrame,
        Details = detailsFrame,
        Viewport = viewport,
        Popup = popup,
        ClosePopup = closePopup,
        Buttons = {
            Toggle = toggleBtn, -- [EXPORTED]
            Close = closeBtn,   -- [EXPORTED]
            Equip = equipBtn,
            QuickSell = quickSellBtn,
            Market = marketBtn,
            ConfirmList = confirmBtn
        },
        Labels = {
            Name = nameLabel,
            Price = priceLabel
        },
        Input = input
    }
end

return InventoryUI