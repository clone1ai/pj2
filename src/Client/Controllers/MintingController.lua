local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetFolder = ReplicatedStorage:WaitForChild("Net")
local Remotes = require(NetFolder:WaitForChild("Remotes"))

-- Access sibling UI folder
local UI = script.Parent.Parent:WaitForChild("UI")
local MintingUI = require(UI:WaitForChild("MintingUI"))

local MintingController = {}
local OpenBoxRF = Remotes.GetRemoteFunction("OpenBox")

function MintingController.Start()
    print("[MintingController] Started")
    local button = MintingUI.Create()
    local debounce = false
    
    button.MouseButton1Click:Connect(function()
        if debounce then return end
        debounce = true
        
        button.Text = "..."
        button.BackgroundColor3 = Color3.fromRGB(120, 120, 120) 
        
        local result = OpenBoxRF:InvokeServer()
        
        if result.Success then
            button.Text = "GOT: " .. result.Data.Name .. " ($" .. result.Data.FloorPrice .. ")"
            button.BackgroundColor3 = Color3.fromRGB(241, 196, 15) 
            task.wait(1.5)
        else
            button.Text = result.Msg
            button.BackgroundColor3 = Color3.fromRGB(231, 76, 60) 
            task.wait(1)
        end
        
        button.Text = "OPEN BOX ($100)"
        button.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        debounce = false
    end)
end

return MintingController