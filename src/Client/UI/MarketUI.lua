local Players = game:GetService("Players")
local MarketUI = {}

function MarketUI.Create()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MarketUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Toggle Button (Right Side)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 60, 0, 60)
    toggleBtn.Position = UDim2.new(1, -80, 0.5, -30)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182) -- Purple
    toggleBtn.Text = "SHOP"
    toggleBtn.Font = Enum.Font.GothamBlack
    toggleBtn.TextSize = 18
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    toggleBtn.Parent = screenGui
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,12)

    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 700, 0, 500)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    -- Tabs Container
    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1,0,0.1,0)
    tabFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    tabFrame.Parent = mainFrame
    
    local globalTab = Instance.new("TextButton")
    globalTab.Text = "GLOBAL MARKET"
    globalTab.Size = UDim2.new(0.5,0,1,0)
    globalTab.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    globalTab.TextColor3 = Color3.new(1,1,1)
    globalTab.Font = Enum.Font.GothamBold
    globalTab.Parent = tabFrame
    
    local personalTab = Instance.new("TextButton")
    personalTab.Text = "MY LISTINGS"
    personalTab.Size = UDim2.new(0.5,0,1,0)
    personalTab.Position = UDim2.new(0.5,0,0,0)
    personalTab.BackgroundColor3 = Color3.fromRGB(60,60,60)
    personalTab.TextColor3 = Color3.new(1,1,1)
    personalTab.Font = Enum.Font.GothamBold
    personalTab.Parent = tabFrame

    -- List Area
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(0.6, 0, 0.85, 0)
    scroll.Position = UDim2.new(0,0,0.15,0)
    scroll.BackgroundColor3 = Color3.fromRGB(40,40,40)
    scroll.Parent = mainFrame
    
    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 120, 0, 140)
    grid.Parent = scroll

    -- Details Panel
    local details = Instance.new("Frame")
    details.Size = UDim2.new(0.4, 0, 0.85, 0)
    details.Position = UDim2.new(0.6, 0, 0.15, 0)
    details.BackgroundColor3 = Color3.fromRGB(50,50,50)
    details.Parent = mainFrame
    
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Text = "Select Item"
    nameLbl.Size = UDim2.new(1,0,0.1,0)
    nameLbl.Position = UDim2.new(0,0,0.1,0)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextColor3 = Color3.new(1,1,1)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextScaled = true
    nameLbl.Parent = details
    
    local priceLbl = Instance.new("TextLabel")
    priceLbl.Text = ""
    priceLbl.Size = UDim2.new(1,0,0.1,0)
    priceLbl.Position = UDim2.new(0,0,0.25,0)
    priceLbl.TextColor3 = Color3.fromRGB(241, 196, 15)
    priceLbl.BackgroundTransparency = 1
    priceLbl.Font = Enum.Font.GothamBlack
    priceLbl.TextSize = 24
    priceLbl.Parent = details

    local actionBtn = Instance.new("TextButton")
    actionBtn.Text = "ACTION"
    actionBtn.Size = UDim2.new(0.8,0,0.15,0)
    actionBtn.Position = UDim2.new(0.1,0,0.8,0)
    actionBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
    actionBtn.Font = Enum.Font.GothamBold
    actionBtn.TextColor3 = Color3.new(1,1,1)
    actionBtn.Parent = details
    
    local refreshBtn = Instance.new("ImageButton")
    refreshBtn.Image = "rbxassetid://16866464875" -- Generic refresh icon
    refreshBtn.Size = UDim2.new(0,30,0,30)
    refreshBtn.Position = UDim2.new(1,-40,0,10)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    refreshBtn.Parent = mainFrame

    return {
        Screen = screenGui,
        Frame = mainFrame,
        Toggle = toggleBtn,
        GlobalTab = globalTab,
        PersonalTab = personalTab,
        Grid = scroll,
        Details = {
            Frame = details,
            Name = nameLbl,
            Price = priceLbl,
            Button = actionBtn
        },
        Refresh = refreshBtn
    }
end

return MarketUI