local Players = game:GetService("Players")
local IncomeHUD = {}

function IncomeHUD.Init()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StatsHUD" 
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Container (Scale based: 22% Width, 15% Height)
    local container = Instance.new("Frame")
    container.Name = "StatsContainer"
    container.Size = UDim2.new(0.22, 0, 0.15, 0) 
    container.Position = UDim2.new(0.02, 0, 0.83, 0) -- Bottom Left relative
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    container.BackgroundTransparency = 0.1
    container.Parent = screenGui
    
    -- Aspect Ratio Constraint (Keeps it rectangular, prevents squishing)
    local aspect = Instance.new("UIAspectRatioConstraint")
    aspect.AspectRatio = 1.8 -- Width / Height ratio
    aspect.Parent = container
    
    -- Styles
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0.1, 0)
    uiCorner.Parent = container
    
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.fromRGB(60, 60, 60)
    uiStroke.Thickness = 2
    uiStroke.Parent = container

    -- ============================
    -- SECTION 1: TOTAL MONEY
    -- ============================
    
    local moneyTitle = Instance.new("TextLabel")
    moneyTitle.Text = "RIZZ COINS"
    moneyTitle.Size = UDim2.new(0.9, 0, 0.15, 0)
    moneyTitle.Position = UDim2.new(0.05, 0, 0.05, 0)
    moneyTitle.BackgroundTransparency = 1
    moneyTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
    moneyTitle.Font = Enum.Font.GothamBold
    moneyTitle.TextScaled = true
    moneyTitle.TextXAlignment = Enum.TextXAlignment.Left
    moneyTitle.Parent = container

    local moneyValue = Instance.new("TextLabel")
    moneyValue.Text = "$0"
    moneyValue.Size = UDim2.new(0.9, 0, 0.25, 0)
    moneyValue.Position = UDim2.new(0.05, 0, 0.22, 0)
    moneyValue.BackgroundTransparency = 1
    moneyValue.TextColor3 = Color3.fromRGB(255, 215, 0) 
    moneyValue.Font = Enum.Font.GothamBlack
    moneyValue.TextScaled = true
    moneyValue.TextXAlignment = Enum.TextXAlignment.Left
    moneyValue.Parent = container
    
    -- Divider Line
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(0.9, 0, 0.01, 0)
    divider.Position = UDim2.new(0.05, 0, 0.5, 0)
    divider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    divider.BorderSizePixel = 0
    divider.Parent = container

    -- ============================
    -- SECTION 2: PASSIVE INCOME
    -- ============================

    local incomeTitle = Instance.new("TextLabel")
    incomeTitle.Text = "INCOME / SEC"
    incomeTitle.Size = UDim2.new(0.9, 0, 0.15, 0)
    incomeTitle.Position = UDim2.new(0.05, 0, 0.55, 0)
    incomeTitle.BackgroundTransparency = 1
    incomeTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
    incomeTitle.Font = Enum.Font.GothamBold
    incomeTitle.TextScaled = true
    incomeTitle.TextXAlignment = Enum.TextXAlignment.Left
    incomeTitle.Parent = container

    local incomeValue = Instance.new("TextLabel")
    incomeValue.Text = "$0/s"
    incomeValue.Size = UDim2.new(0.9, 0, 0.22, 0)
    incomeValue.Position = UDim2.new(0.05, 0, 0.72, 0)
    incomeValue.BackgroundTransparency = 1
    incomeValue.TextColor3 = Color3.fromRGB(46, 204, 113) 
    incomeValue.Font = Enum.Font.GothamBold
    incomeValue.TextScaled = true
    incomeValue.TextXAlignment = Enum.TextXAlignment.Left
    incomeValue.Parent = container

    -- ============================
    -- LOGIC & ANIMATION
    -- ============================
    local TweenService = game:GetService("TweenService")

    local function updateMoney()
        local amt = player:GetAttribute("RizzCoins") or 0
        moneyValue.Text = "$" .. string.format("%d", amt)
        
        -- Pop Animation (Scale based)
        local originalSize = UDim2.new(0.9, 0, 0.25, 0)
        local popSize = UDim2.new(0.95, 0, 0.28, 0)
        
        local t1 = TweenService:Create(moneyValue, TweenInfo.new(0.1), {Size = popSize})
        t1:Play()
        t1.Completed:Connect(function()
            TweenService:Create(moneyValue, TweenInfo.new(0.1), {Size = originalSize}):Play()
        end)
    end

    local function updateIncome()
        local amt = player:GetAttribute("IncomeRate") or 0
        incomeValue.Text = "+$" .. amt .. "/s"
    end

    player:GetAttributeChangedSignal("RizzCoins"):Connect(updateMoney)
    player:GetAttributeChangedSignal("IncomeRate"):Connect(updateIncome)
    
    updateMoney()
    updateIncome()
end

return IncomeHUD