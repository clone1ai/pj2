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
    openButton.Size = UDim2.new(0, 200, 0, 60)
    openButton.AnchorPoint = Vector2.new(0.5, 1) 
    openButton.Position = UDim2.new(0.5, 0, 1, -20)
    openButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113) 
    openButton.Text = "OPEN BOX ($100)"
    openButton.Font = Enum.Font.GothamBold
    openButton.TextSize = 24
    openButton.Parent = screenGui
    
    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 12)
    uicorner.Parent = openButton
    
    return openButton
end

return MintingUI