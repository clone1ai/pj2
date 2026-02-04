local Players = game:GetService("Players")
local UIBuilderController = {}

function UIBuilderController:Init()
    self:BuildAll()
end

function UIBuilderController:Start() end

function UIBuilderController:BuildAll()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Reset Old UI
    if playerGui:FindFirstChild("MainUI") then playerGui.MainUI:Destroy() end

    local mainUI = Instance.new("ScreenGui")
    mainUI.Name = "MainUI"
    mainUI.IgnoreGuiInset = true
    mainUI.ResetOnSpawn = false
    mainUI.Parent = playerGui

    -- 1. Create Icons (HUD)
    self:BuildHUD(mainUI)
    
    -- 2. Create Frames (Hidden by default)
    self:BuildInventoryFrame(mainUI)
    self:BuildMarketFrame(mainUI)
end

function UIBuilderController:BuildHUD(parent)
    -- Currency Label (Top Center)
    local currency = Instance.new("TextLabel")
    currency.Name = "CurrencyLabel"
    currency.Size = UDim2.new(0, 220, 0, 50)
    currency.Position = UDim2.new(0.5, -110, 0, 10)
    currency.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    currency.BackgroundTransparency = 0.3
    currency.Text = "$ Loading..."
    currency.TextColor3 = Color3.fromRGB(255, 215, 0)
    currency.Font = Enum.Font.FredokaOne
    currency.TextSize = 28
    currency.Parent = parent
    self:Round(currency, 12)

    -- Left Menu Container
    local menuFrame = Instance.new("Frame")
    menuFrame.Name = "MenuFrame"
    menuFrame.Size = UDim2.new(0, 70, 0, 200)
    menuFrame.Position = UDim2.new(0, 10, 0.5, -100)
    menuFrame.BackgroundTransparency = 1
    menuFrame.Parent = parent

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 10)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.Parent = menuFrame

    -- Inventory Button 🎒
    self:CreateIconButton(menuFrame, "InventoryButton", "🎒", Color3.fromRGB(0, 150, 255))
    
    -- Market Button 📈
    self:CreateIconButton(menuFrame, "MarketButton", "📈", Color3.fromRGB(0, 200, 100))

    -- BUY BOX BUTTON (Bottom Center)
    local buyBtn = Instance.new("TextButton")
    buyBtn.Name = "BuyBoxButton"
    buyBtn.Size = UDim2.new(0, 180, 0, 60)
    buyBtn.Position = UDim2.new(0.5, -90, 0.9, -10)
    buyBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
    buyBtn.Text = "📦 BUY BOX ($100)"
    buyBtn.Font = Enum.Font.FredokaOne
    buyBtn.TextSize = 20
    buyBtn.TextColor3 = Color3.new(1,1,1)
    buyBtn.Parent = parent
    self:Round(buyBtn, 16)
    
    -- Add subtle pulsing animation tag
    buyBtn:SetAttribute("IsAnimated", true) 
end

function UIBuilderController:BuildInventoryFrame(parent)
    local frame = Instance.new("Frame")
    frame.Name = "InventoryFrame"
    frame.Size = UDim2.new(0, 340, 0, 450)
    frame.Position = UDim2.new(0.5, -170, 0.5, -225)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    frame.Visible = false -- Hidden by default
    frame.Parent = parent
    self:Round(frame, 12)

    -- Header
    self:CreateHeader(frame, "MY BAG 🎒", Color3.fromRGB(60, 60, 70))

    -- Close Button
    self:CreateCloseButton(frame)

    -- Container
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "ScrollingFrame"
    scroll.Size = UDim2.new(0.9, 0, 0.7, 0)
    scroll.Position = UDim2.new(0.05, 0, 0.15, 0)
    scroll.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    scroll.Parent = frame
    self:Round(scroll, 8)

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 90, 0, 90)
    grid.Parent = scroll

    -- Action Area
    local input = Instance.new("TextBox")
    input.Name = "PriceInput"
    input.Size = UDim2.new(0.5, 0, 0, 35)
    input.Position = UDim2.new(0.05, 0, 0.88, 0)
    input.PlaceholderText = "Price..."
    input.Text = ""
    input.Parent = frame
    self:Round(input, 6)

    local listBtn = Instance.new("TextButton")
    listBtn.Name = "ListButton"
    listBtn.Size = UDim2.new(0.35, 0, 0, 35)
    listBtn.Position = UDim2.new(0.6, 0, 0.88, 0)
    listBtn.Text = "LIST ITEM"
    listBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
    listBtn.TextColor3 = Color3.new(1,1,1)
    listBtn.Font = Enum.Font.GothamBold
    listBtn.Parent = frame
    self:Round(listBtn, 6)
end

function UIBuilderController:BuildMarketFrame(parent)
    local frame = Instance.new("Frame")
    frame.Name = "MarketFrame"
    frame.Size = UDim2.new(0, 500, 0, 500)
    frame.Position = UDim2.new(0.5, -250, 0.5, -250)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    frame.Visible = false -- Hidden by default
    frame.Parent = parent
    self:Round(frame, 12)

    self:CreateHeader(frame, "GLOBAL MARKET 📈", Color3.fromRGB(50, 40, 80))
    self:CreateCloseButton(frame)

    local container = Instance.new("ScrollingFrame")
    container.Name = "Container"
    container.Size = UDim2.new(0.94, 0, 0.85, 0)
    container.Position = UDim2.new(0.03, 0, 0.12, 0)
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    container.Parent = frame
    self:Round(container, 8)

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 100, 0, 130)
    grid.Parent = container
end

-- [[ HELPERS ]] --
function UIBuilderController:CreateIconButton(parent, name, icon, color)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 60, 0, 60)
    btn.BackgroundColor3 = color
    btn.Text = icon
    btn.TextSize = 30
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Parent = parent
    self:Round(btn, 16)
    return btn
end

function UIBuilderController:CreateHeader(parent, text, color)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, 0, 0, 50)
    h.BackgroundColor3 = color
    h.Parent = parent
    self:Round(h, 12) -- This rounds all corners
    
    -- Fix bottom corners to be square
    local filler = Instance.new("Frame")
    filler.Size = UDim2.new(1, 0, 0.5, 0)
    filler.Position = UDim2.new(0, 0, 0.5, 0)
    filler.BackgroundColor3 = color
    filler.BorderSizePixel = 0
    filler.Parent = h

    local lbl = Instance.new("TextLabel")
    lbl.Text = text
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Font = Enum.Font.FredokaOne
    lbl.TextSize = 24
    lbl.Parent = h
end

function UIBuilderController:CreateCloseButton(parent)
    local btn = Instance.new("TextButton")
    btn.Name = "CloseButton"
    btn.Size = UDim2.new(0, 30, 0, 30)
    btn.Position = UDim2.new(1, -35, 0, 10)
    btn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    btn.Text = "X"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBlack
    btn.Parent = parent
    self:Round(btn, 8)
end

function UIBuilderController:Round(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = obj
end

return UIBuilderController