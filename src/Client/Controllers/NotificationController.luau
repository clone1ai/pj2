local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local GameConstants = require(ReplicatedStorage.Configs.GameConstants)

local NotificationController = {}

function NotificationController:Init()
    local player = Players.LocalPlayer
    local gui = player:WaitForChild("PlayerGui")
    self.MainUI = gui:WaitForChild("MainUI", 10)
end

function NotificationController:Start()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local eventRemote = remotes:WaitForChild(GameConstants.Events.MARKET_EVENT)
    
    eventRemote.OnClientEvent:Connect(function(data)
        if data.Active then
            self:ShowNotification(data.Buff.Message, Color3.fromRGB(255, 215, 0))
        else
            -- Optional: Show "Event Ended"
            self:ShowNotification("Event Ended", Color3.fromRGB(200, 200, 200))
        end
    end)
    
    print("   -> NotificationController Started")
end

function NotificationController:ShowNotification(text, color)
    if not self.MainUI then return end
    
    -- Create a label on the fly
    local label = Instance.new("TextLabel")
    label.Text = text
    label.TextColor3 = color
    label.Font = Enum.Font.FredokaOne
    label.TextSize = 24
    label.Size = UDim2.new(1, 0, 0, 50)
    label.Position = UDim2.new(0, 0, 0.1, 0) -- Top Center
    label.BackgroundTransparency = 1
    label.TextStrokeTransparency = 0.5
    label.Parent = self.MainUI
    
    -- Animation: Fade In -> Wait -> Fade Out
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    -- Pop in
    label.TextTransparency = 1
    TweenService:Create(label, tweenInfo, {TextTransparency = 0}):Play()
    
    task.delay(4, function()
        -- Pop out
        local fadeOut = TweenService:Create(label, tweenInfo, {TextTransparency = 1})
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            label:Destroy()
        end)
    end)
end

return NotificationController