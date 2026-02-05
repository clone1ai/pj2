local Players = game:GetService("Players")
local MarketUI = {}

function MarketUI.Create()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MarketUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- 2. Toggle Button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleShop"
    toggleBtn.Size = UDim2.new(0.15, 0, 0.08, 0)
    toggleBtn.Position = UDim2.new(0.99, 0, 0.5, 0) -- Right Side
    toggleBtn.AnchorPoint = Vector2.new(1, 0.5)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    toggleBtn.Text = "MARKET"
    toggleBtn.Font = Enum.Font.GothamBlack
    toggleBtn.TextScaled = true
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    toggleBtn.ZIndex = 10
    toggleBtn.Parent = screenGui
    
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0.2, 0)
    local btnAspect = Instance.new("UIAspectRatioConstraint")
    btnAspect.AspectRatio = 2.8
    btnAspect.Parent = toggleBtn
    
    -- 3. Main Window
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.7, 0, 0.7, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.Visible = false 
    mainFrame.ZIndex = 5
    mainFrame.Parent = screenGui
    
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0.03, 0)
    local frameAspect = Instance.new("UIAspectRatioConstraint")
    frameAspect.AspectRatio = 1.6
    frameAspect.Parent = mainFrame
    
    -- Header
    local header = Instance.new("TextLabel")
    header.Text = "GLOBAL MARKET"
    header.Size = UDim2.new(0.5, 0, 0.1, 0)
    header.Position = UDim2.new(0.03, 0, 0, 0)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBlack
    header.TextScaled = true
    header.TextColor3 = Color3.new(1,1,1)
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.ZIndex = 6
    header.Parent = mainFrame
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Text = "X"
    closeBtn.Size = UDim2.new(0.08, 0, 0.08, 0)
    closeBtn.SizeConstraint = Enum.SizeConstraint.RelativeYY
    closeBtn.Position = UDim2.new(0.98, 0, 0.02, 0)
    closeBtn.AnchorPoint = Vector2.new(1,0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.Font = Enum.Font.GothamBlack
    closeBtn.TextScaled = true
    closeBtn.ZIndex = 10
    closeBtn.Parent = mainFrame
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0.2, 0)

    -- Refresh Button
    local refreshBtn = Instance.new("ImageButton")
    refreshBtn.Image = "rbxassetid://114496992333593" 
    refreshBtn.Size = UDim2.new(0.08, 0, 0.08, 0)
    refreshBtn.SizeConstraint = Enum.SizeConstraint.RelativeYY
    refreshBtn.Position = UDim2.new(0.90, 0, 0.02, 0)
    refreshBtn.AnchorPoint = Vector2.new(1,0)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    refreshBtn.ZIndex = 6
    refreshBtn.Parent = mainFrame
    Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0.2, 0)

    -- 4. Tabs
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(0.4, 0, 0.08, 0)
    tabContainer.Position = UDim2.new(0.5, 0, 0.02, 0)
    tabContainer.AnchorPoint = Vector2.new(0.5, 0)
    tabContainer.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    tabContainer.ZIndex = 6
    tabContainer.Parent = mainFrame
    Instance.new("UICorner", tabContainer).CornerRadius = UDim.new(0.3, 0)
    
    local globalTab = Instance.new("TextButton")
    globalTab.Text = "Global"
    globalTab.Size = UDim2.new(0.5, 0, 1, 0)
    globalTab.BackgroundTransparency = 1
    globalTab.Font = Enum.Font.GothamBold
    globalTab.TextColor3 = Color3.fromRGB(46, 204, 113)
    globalTab.TextScaled = true
    globalTab.ZIndex = 7
    globalTab.Parent = tabContainer
    
    local personalTab = Instance.new("TextButton")
    personalTab.Text = "My Listings"
    personalTab.Size = UDim2.new(0.5, 0, 1, 0)
    personalTab.Position = UDim2.new(0.5, 0, 0, 0)
    personalTab.BackgroundTransparency = 1
    personalTab.Font = Enum.Font.GothamBold
    personalTab.TextColor3 = Color3.fromRGB(150, 150, 150)
    personalTab.TextScaled = true
    personalTab.ZIndex = 7
    personalTab.Parent = tabContainer

    -- 5. Content
    
    -- GRID
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(0.65, 0, 0.85, 0)
    scroll.Position = UDim2.new(0.02, 0, 0.12, 0)
    scroll.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    scroll.BackgroundTransparency = 0.5
    scroll.BorderSizePixel = 0
    scroll.ZIndex = 6
    scroll.Parent = mainFrame
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.47, 0, 0.35, 0) -- 2 columns
    gridLayout.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
    gridLayout.Parent = scroll

    -- DETAILS FRAME
    local detailsFrame = Instance.new("Frame")
    detailsFrame.Size = UDim2.new(0.3, 0, 0.85, 0)
    detailsFrame.Position = UDim2.new(0.68, 0, 0.12, 0)
    detailsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    detailsFrame.ZIndex = 6
    detailsFrame.Parent = mainFrame
    Instance.new("UICorner", detailsFrame).CornerRadius = UDim.new(0.05, 0)

    -- Labels Container
    local infoContainer = Instance.new("Frame")
    infoContainer.Size = UDim2.new(0.9, 0, 0.7, 0)
    infoContainer.Position = UDim2.new(0.05, 0, 0.02, 0)
    infoContainer.BackgroundTransparency = 1
    infoContainer.ZIndex = 7
    infoContainer.Parent = detailsFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0.02, 0)
    listLayout.Parent = infoContainer

    local function createInfoLabel(name, defaultText, color, heightScale)
        local lbl = Instance.new("TextLabel")
        lbl.Name = name
        lbl.Text = defaultText
        lbl.Size = UDim2.new(1, 0, heightScale or 0.1, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = color or Color3.fromRGB(200, 200, 200)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextScaled = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 7
        lbl.Parent = infoContainer
        return lbl
    end

    local dTitle = createInfoLabel("Name", "Select Item", Color3.new(1,1,1), 0.15)
    dTitle.TextWrapped = true
    
    local dPriceVal = createInfoLabel("Price", "---", Color3.fromRGB(241, 196, 15), 0.12)
    local uidLbl = createInfoLabel("UID", "UID: ---")
    local elementLbl = createInfoLabel("Element", "Element: ---")
    local modelLbl = createInfoLabel("Model", "Model: ---")
    local sizeLbl = createInfoLabel("Size", "Size: ---")
    local sellerLbl = createInfoLabel("Seller", "Seller: ---", Color3.fromRGB(100, 200, 255))

    -- Action Button
    local dActionBtn = Instance.new("TextButton")
    dActionBtn.Text = "SELECT ITEM"
    dActionBtn.Size = UDim2.new(0.9, 0, 0.1, 0)
    dActionBtn.Position = UDim2.new(0.05, 0, 0.85, 0)
    dActionBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    dActionBtn.Font = Enum.Font.GothamBold
    dActionBtn.TextScaled = true
    dActionBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    dActionBtn.ZIndex = 7
    dActionBtn.Parent = detailsFrame
    Instance.new("UICorner", dActionBtn).CornerRadius = UDim.new(0.2, 0)
    
    return {
        Screen = screenGui,
        Frame = mainFrame,
        Toggle = toggleBtn,
        Close = closeBtn,
        Refresh = refreshBtn,
        Tabs = {Global = globalTab, Personal = personalTab},
        Grid = scroll,
        Details = {
            Frame = detailsFrame,
            ItemNameLabel = dTitle,
            PriceLabel = dPriceVal,
            UID = uidLbl,
            Element = elementLbl,
            Model = modelLbl,
            Size = sizeLbl,
            Seller = sellerLbl,
            Button = dActionBtn
        }
    }
end

return MarketUI