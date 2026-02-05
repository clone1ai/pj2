local Players = game:GetService("Players")
local InventoryUI = {}

function InventoryUI.Create()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- 1. ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "InventoryUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- 2. Toggle Button ("BAG")
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleBag"
    toggleBtn.Size = UDim2.new(0.12, 0, 0.08, 0) -- Scale
    toggleBtn.Position = UDim2.new(0.01, 0, 0.5, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    toggleBtn.Text = "BAG"
    toggleBtn.Font = Enum.Font.GothamBlack
    toggleBtn.TextScaled = true -- Responsive Text
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    toggleBtn.ZIndex = 10
    toggleBtn.Parent = screenGui
    
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0.2, 0)
    Instance.new("UIStroke", toggleBtn).Thickness = 2
    
    -- Aspect Ratio for Button
    local btnAspect = Instance.new("UIAspectRatioConstraint")
    btnAspect.AspectRatio = 2.5
    btnAspect.Parent = toggleBtn
    
    -- 3. Main Window (Scale Based)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.7, 0, 0.7, 0) -- 70% of screen
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.Visible = false
    mainFrame.ZIndex = 5
    mainFrame.Parent = screenGui
    
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0.03, 0)
    
    -- Aspect Ratio for MainFrame (Prevents stretching)
    local frameAspect = Instance.new("UIAspectRatioConstraint")
    frameAspect.AspectRatio = 1.6 -- Maintains landscape shape
    frameAspect.Parent = mainFrame
    
    -- Header
    local header = Instance.new("TextLabel")
    header.Text = "INVENTORY"
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
    closeBtn.Text = "X"
    closeBtn.Size = UDim2.new(0.08, 0, 0.08, 0) -- Relative size
    closeBtn.SizeConstraint = Enum.SizeConstraint.RelativeYY -- Keep square based on height
    closeBtn.Position = UDim2.new(0.98, 0, 0.02, 0)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.Font = Enum.Font.GothamBlack
    closeBtn.TextScaled = true
    closeBtn.ZIndex = 10
    closeBtn.Parent = mainFrame
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0.2, 0)

    -- 4. Content Area
    
    -- GRID (Left)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(0.65, 0, 0.85, 0)
    scroll.Position = UDim2.new(0.02, 0, 0.12, 0)
    scroll.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    scroll.BackgroundTransparency = 0.5
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.ZIndex = 6
    scroll.Parent = mainFrame
    
    local gridLayout = Instance.new("UIGridLayout")
    -- Scale: Approx 47% width per item (2 columns with padding)
    gridLayout.CellSize = UDim2.new(0.47, 0, 0.35, 0) 
    gridLayout.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
    gridLayout.Parent = scroll

    -- DETAILS (Right)
    local detailsFrame = Instance.new("Frame")
    detailsFrame.Size = UDim2.new(0.3, 0, 0.85, 0)
    detailsFrame.Position = UDim2.new(0.68, 0, 0.12, 0)
    detailsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    detailsFrame.ZIndex = 6
    detailsFrame.Parent = mainFrame
    Instance.new("UICorner", detailsFrame).CornerRadius = UDim.new(0.05, 0)

    -- Detail Labels Container
    local infoContainer = Instance.new("Frame")
    infoContainer.Size = UDim2.new(0.9, 0, 0.6, 0)
    infoContainer.Position = UDim2.new(0.05, 0, 0.02, 0)
    infoContainer.BackgroundTransparency = 1
    infoContainer.ZIndex = 7
    infoContainer.Parent = detailsFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0.02, 0)
    listLayout.Parent = infoContainer

    -- Helper to create Detail Labels
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

    local nameLbl = createInfoLabel("Name", "Select Item", Color3.new(1,1,1), 0.15)
    nameLbl.TextWrapped = true
    
    local priceLbl = createInfoLabel("Price", "---", Color3.fromRGB(241, 196, 15), 0.12)
    local uidLbl = createInfoLabel("UID", "UID: ---")
    local elementLbl = createInfoLabel("Element", "Element: ---")
    local modelLbl = createInfoLabel("Model", "Model: ---")
    local sizeLbl = createInfoLabel("Size", "Size: ---")

    -- Buttons Container (Bottom of Details)
    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(0.9, 0, 0.35, 0)
    btnContainer.Position = UDim2.new(0.05, 0, 0.62, 0)
    btnContainer.BackgroundTransparency = 1
    btnContainer.ZIndex = 7
    btnContainer.Parent = detailsFrame
    
    local btnLayout = Instance.new("UIListLayout")
    btnLayout.Padding = UDim.new(0.05, 0)
    btnLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    btnLayout.Parent = btnContainer

    -- Helper for Buttons
    local function createActionBtn(text, color)
        local btn = Instance.new("TextButton")
        btn.Text = text
        btn.Size = UDim2.new(1, 0, 0.28, 0)
        btn.BackgroundColor3 = color
        btn.Font = Enum.Font.GothamBold
        btn.TextScaled = true
        btn.TextColor3 = Color3.new(1,1,1)
        btn.ZIndex = 8
        btn.Parent = btnContainer
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0.2, 0)
        return btn
    end

    local equipBtn = createActionBtn("HOLD ITEM", Color3.fromRGB(52, 152, 219))
    local sellBtn = createActionBtn("QUICK SELL", Color3.fromRGB(231, 76, 60))
    local listBtn = createActionBtn("LIST ON MARKET", Color3.fromRGB(46, 204, 113))

    -- 5. Market Listing Popup
    local popup = Instance.new("Frame")
    popup.Name = "MarketPopup"
    popup.Size = UDim2.new(1, 0, 1, 0)
    popup.BackgroundColor3 = Color3.new(0,0,0)
    popup.BackgroundTransparency = 0.3
    popup.Visible = false
    popup.ZIndex = 20
    popup.Parent = mainFrame 
    
    local popupFrame = Instance.new("Frame")
    popupFrame.Size = UDim2.new(0.5, 0, 0.4, 0)
    popupFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    popupFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    popupFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    popupFrame.ZIndex = 21
    popupFrame.Parent = popup
    Instance.new("UICorner", popupFrame).CornerRadius = UDim.new(0.1, 0)
    
    -- Popup Aspect Ratio
    local popupAspect = Instance.new("UIAspectRatioConstraint")
    popupAspect.AspectRatio = 1.8
    popupAspect.Parent = popupFrame

    local popupTitle = Instance.new("TextLabel")
    popupTitle.Text = "SET LISTING PRICE"
    popupTitle.Size = UDim2.new(1, 0, 0.25, 0)
    popupTitle.BackgroundTransparency = 1
    popupTitle.TextColor3 = Color3.new(1,1,1)
    popupTitle.Font = Enum.Font.GothamBlack
    popupTitle.TextScaled = true
    popupTitle.ZIndex = 22
    popupTitle.Parent = popupFrame

    local input = Instance.new("TextBox")
    input.Text = ""
    input.PlaceholderText = "Enter Price..."
    input.Size = UDim2.new(0.8, 0, 0.25, 0)
    input.Position = UDim2.new(0.1, 0, 0.3, 0)
    input.BackgroundColor3 = Color3.fromRGB(30,30,30)
    input.TextColor3 = Color3.new(1,1,1)
    input.Font = Enum.Font.GothamBold
    input.TextScaled = true
    input.ZIndex = 22
    input.Parent = popupFrame
    Instance.new("UICorner", input).CornerRadius = UDim.new(0.2, 0)
    
    local confirmListBtn = Instance.new("TextButton")
    confirmListBtn.Text = "CONFIRM"
    confirmListBtn.Size = UDim2.new(0.8, 0, 0.25, 0)
    confirmListBtn.Position = UDim2.new(0.1, 0, 0.65, 0)
    confirmListBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    confirmListBtn.TextColor3 = Color3.new(1,1,1)
    confirmListBtn.Font = Enum.Font.GothamBlack
    confirmListBtn.TextScaled = true
    confirmListBtn.ZIndex = 22
    confirmListBtn.Parent = popupFrame
    Instance.new("UICorner", confirmListBtn).CornerRadius = UDim.new(0.2, 0)

    local closePopupBtn = Instance.new("TextButton")
    closePopupBtn.Text = "X"
    closePopupBtn.Size = UDim2.new(0.1, 0, 0.2, 0)
    closePopupBtn.SizeConstraint = Enum.SizeConstraint.RelativeYY
    closePopupBtn.Position = UDim2.new(0.98, 0, 0.02, 0)
    closePopupBtn.AnchorPoint = Vector2.new(1,0)
    closePopupBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    closePopupBtn.TextColor3 = Color3.new(1,1,1)
    closePopupBtn.TextScaled = true
    closePopupBtn.ZIndex = 22
    closePopupBtn.Parent = popupFrame
    Instance.new("UICorner", closePopupBtn).CornerRadius = UDim.new(0.2, 0)

    return {
        Screen = screenGui,
        Frame = mainFrame,
        Toggle = toggleBtn,
        Close = closeBtn,
        Grid = scroll,
        Details = {
            Name = nameLbl,
            Price = priceLbl,
            UID = uidLbl,
            Element = elementLbl,
            Model = modelLbl,
            Size = sizeLbl,
            Buttons = { Equip = equipBtn, Sell = sellBtn, List = listBtn }
        },
        Popup = {
            Frame = popup,
            Input = input,
            Confirm = confirmListBtn,
            Close = closePopupBtn
        }
    }
end

return InventoryUI