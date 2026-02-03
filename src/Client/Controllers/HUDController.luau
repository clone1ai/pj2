local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local HUDController = {}

function HUDController:Init()
    local player = Players.LocalPlayer
    local gui = player:WaitForChild("PlayerGui")
    self.MainUI = gui:WaitForChild("MainUI", 10)
end

function HUDController:Start()
    local player = Players.LocalPlayer
    local currentCoins = player:GetAttribute("RizzCoins")
    if currentCoins == nil then
        -- Fallback: fetch from server
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local remotes = ReplicatedStorage:WaitForChild("Remotes")
        local getBalanceFunc = remotes:FindFirstChild("GetRizzCoinBalance")
        if getBalanceFunc then
            local ok, result = pcall(function()
                return getBalanceFunc:InvokeServer()
            end)
            if ok and result then
                currentCoins = result
            else
                currentCoins = 0
            end
        else
            currentCoins = 0
        end
    end
    self:UpdateMoney(currentCoins)

    -- 2. Listen for fast updates (Tycoon ticks)
    player:GetAttributeChangedSignal("RizzCoins"):Connect(function()
        local newValue = player:GetAttribute("RizzCoins")
        self:UpdateMoney(newValue)
    end)

    print("   -> HUDController Started")
end

function HUDController:UpdateMoney(amount)
    if not self.MainUI then return end
    local label = self.MainUI:FindFirstChild("AmountLabel", true) -- Recursive find
    
    if label then
        -- Format with commas (e.g., 1,000,000)
        label.Text = "$" .. self:FormatNumber(amount)
        
        -- Simple "Pop" animation
        local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true)
        TweenService:Create(label, tweenInfo, {TextSize = 32}):Play()
    end
end

-- Helper: Adds commas to numbers
function HUDController:FormatNumber(n)
    return tostring(n):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

return HUDController