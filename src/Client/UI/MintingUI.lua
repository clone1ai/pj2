local Players = game:GetService("Players")
local MintingUI = {}

function MintingUI.Create()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MintingHUD"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    local openButton = Instance.new("TextButton")
    openButton.Name = "OpenBoxButton"
    openButton.Size = UDim2.new(0.3, 0, 0.1, 0) -- Scale: 30% Width
    openButton.AnchorPoint = Vector2.new(0.5, 1) 
    openButton.Position = UDim2.new(0.5, 0, 0.95, 0) -- Bottom Center with margin
    openButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113) 
    openButton.Text = "OPEN BOX ($100)"
    openButton.Font = Enum.Font.GothamBold
    openButton.TextScaled = true -- Responsive text
    openButton.Parent = screenGui
    
    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0.2, 0)
    uicorner.Parent = openButton
    
    -- Keep Button Aspect Ratio
    local aspect = Instance.new("UIAspectRatioConstraint")
    aspect.AspectRatio = 4.5 -- Long rectangular shape
    aspect.Parent = openButton
    
    return openButton
end

return MintingUI