local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetFolder = ReplicatedStorage:WaitForChild("Net")
local Remotes = require(NetFolder:WaitForChild("Remotes"))

local PlacementController = {}

local PlaceRF = Remotes.GetRemoteFunction("PlaceItem")
local PickupRF = Remotes.GetRemoteFunction("PickupItem")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

function PlacementController.Start()
    print("[PlacementController] Started")

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            PlacementController.HandleClick()
        end
    end)
end

function PlacementController.HandleClick()
    local char = Player.Character
    if not char then return end
    
    local tool = char:FindFirstChildWhichIsA("Tool")
    local target = Mouse.Target
    
    if not target then return end

    -- 1. PLACEMENT LOGIC (Holding Tool -> Click Farm)
    if tool then
        local itemId = tool:GetAttribute("ItemId")
        if not itemId then return end -- Not a valid game item
        
        -- Check if clicked a Farm Bounds
        if target.Name == "Bounds" and target.Parent.Name:match("Farm") then
            local farm = target.Parent
            
            -- Invoke Server
            local result = PlaceRF:InvokeServer(itemId, farm)
            
            if result.Success then
                print("Placed item!")
            else
                warn(result.Msg)
            end
        end

    -- 2. PICKUP LOGIC (Empty Hand -> Click Brainrot)
    else
        -- [FIXED TYPO HERE]
        local model = target:FindFirstAncestorWhichIsA("Model")
        
        if model and model:GetAttribute("IsBrainrot") then
            -- Invoke Server
            local result = PickupRF:InvokeServer(model)
            
            if result.Success then
                print("Picked up item!")
            else
                warn(result.Msg)
            end
        end
    end
end

return PlacementController