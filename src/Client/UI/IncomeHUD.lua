local Players = game:GetService("Players")
local IncomeHUD = {}

function IncomeHUD.Init()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StatsHUD" -- Renamed since it holds both
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Container (Taller to fit both)
    local container = Instance.new("Frame")
    container.Name = "StatsContainer"
    container.Size = UDim2.new(0, 240, 0, 140) -- Increased Height
    container.Position = UDim2.new(0, 20, 1, -160) -- Moved up slightly
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    container.BackgroundTransparency = 0.1
    container.Parent = screenGui
    
    -- Styles
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 12)
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
    moneyTitle.Size = UDim2.new(1, -20, 0, 20)
    moneyTitle.Position = UDim2.new(0, 15, 0, 10)
    moneyTitle.BackgroundTransparency = 1
    moneyTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
    moneyTitle.Font = Enum.Font.GothamBold
    moneyTitle.TextSize = 12
    moneyTitle.TextXAlignment = Enum.TextXAlignment.Left
    moneyTitle.Parent = container

    local moneyValue = Instance.new("TextLabel")
    moneyValue.Text = "$0"
    moneyValue.Size = UDim2.new(1, -20, 0, 35)
    moneyValue.Position = UDim2.new(0, 15, 0, 30)
    moneyValue.BackgroundTransparency = 1
    moneyValue.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    moneyValue.Font = Enum.Font.GothamBlack
    moneyValue.TextSize = 34
    moneyValue.TextXAlignment = Enum.TextXAlignment.Left
    moneyValue.Parent = container
    
    -- Divider Line
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -30, 0, 1)
    divider.Position = UDim2.new(0, 15, 0, 70)
    divider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    divider.BorderSizePixel = 0
    divider.Parent = container

    -- ============================
    -- SECTION 2: PASSIVE INCOME
    -- ============================

    local incomeTitle = Instance.new("TextLabel")
    incomeTitle.Text = "INCOME / SEC"
    incomeTitle.Size = UDim2.new(1, -20, 0, 20)
    incomeTitle.Position = UDim2.new(0, 15, 0, 80)
    incomeTitle.BackgroundTransparency = 1
    incomeTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
    incomeTitle.Font = Enum.Font.GothamBold
    incomeTitle.TextSize = 12
    incomeTitle.TextXAlignment = Enum.TextXAlignment.Left
    incomeTitle.Parent = container

    local incomeValue = Instance.new("TextLabel")
    incomeValue.Text = "$0/s"
    incomeValue.Size = UDim2.new(1, -20, 0, 30)
    incomeValue.Position = UDim2.new(0, 15, 0, 100)
    incomeValue.BackgroundTransparency = 1
    incomeValue.TextColor3 = Color3.fromRGB(46, 204, 113) -- Green
    incomeValue.Font = Enum.Font.GothamBold
    incomeValue.TextSize = 24
    incomeValue.TextXAlignment = Enum.TextXAlignment.Left
    incomeValue.Parent = container

    -- ============================
    -- LOGIC & ANIMATION
    -- ============================
    local TweenService = game:GetService("TweenService")

    local function updateMoney()
        local amt = player:GetAttribute("RizzCoins") or 0
        moneyValue.Text = "$" .. string.format("%d", amt) -- Formats nicely
        
        -- Pop Animation
        local t1 = TweenService:Create(moneyValue, TweenInfo.new(0.1), {TextSize = 40})
        t1:Play()
        t1.Completed:Connect(function()
            TweenService:Create(moneyValue, TweenInfo.new(0.1), {TextSize = 34}):Play()
        end)
    end

    local function updateIncome()
        local amt = player:GetAttribute("IncomeRate") or 0
        incomeValue.Text = "+$" .. amt .. "/s"
    end

    -- Connect Listeners
    player:GetAttributeChangedSignal("RizzCoins"):Connect(updateMoney)
    player:GetAttributeChangedSignal("IncomeRate"):Connect(updateIncome)
    
    -- Init
    updateMoney()
    updateIncome()
end

return IncomeHUD