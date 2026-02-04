local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local GameConstants = require(ReplicatedStorage.Configs.GameConstants)

local NotificationController = {}

function NotificationController:Init()
    -- Init is for internal data only. Do NOT wait for UI here.
end

function NotificationController:Start()
    local player = Players.LocalPlayer
    local gui = player:WaitForChild("PlayerGui")
    self.MainUI = gui:WaitForChild("MainUI") -- Safe to wait here
    
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local eventRemote = remotes:WaitForChild(GameConstants.Events.MARKET_EVENT)
    
    eventRemote.OnClientEvent:Connect(function(status, buffData)
        if status == "Start" and buffData then
            self:ShowNotification(buffData.Message, Color3.fromRGB(255, 215, 0))
        elseif status == "End" then
            self:ShowNotification("Market Event Ended", Color3.fromRGB(200, 200, 200))
        end
    end)
    
    print("   -> NotificationController Started")
end

function NotificationController:ShowNotification(text, color)
    if not self.MainUI then return end
    
    local label = Instance.new("TextLabel")
    label.Text = text
    label.TextColor3 = color
    label.Font = Enum.Font.FredokaOne
    label.TextSize = 28
    label.Size = UDim2.new(0.8, 0, 0, 60)
    label.Position = UDim2.new(0.1, 0, 0.15, 0) -- Top area
    label.BackgroundTransparency = 1
    label.TextStrokeTransparency = 0
    label.Parent = self.MainUI
    
    -- Animation
    label.TextTransparency = 1
    local t1 = TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 0})
    t1:Play()
    
    task.delay(4, function()
        local t2 = TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 1})
        t2:Play()
        t2.Completed:Connect(function() label:Destroy() end)
    end)
end

return NotificationController