local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local GameConstants = require(ReplicatedStorage.Configs.GameConstants)

local TycoonController = {}

function TycoonController:Init()
    -- Get Reference to Inventory Controller (Dependency Injection Style)
    -- Since they are siblings, we can access them via the global `Controllers` if structured that way,
    -- but for safety in this loader style, we will just wait for it or require it if needed.
    -- However, ClientLoader loaded them. 
    -- To keep it decoupled, we'll access the module via the file path if needed, 
    -- OR better: We rely on the User Input logic here.
end

function TycoonController:Start()
    self.InventoryController = require(script.Parent.InventoryController)
    
    -- Input Listener (Mouse Click)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end -- Ignore clicks on UI buttons
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self:HandleClick()
        end
    end)
    
    print("   -> TycoonController Started")
end

function TycoonController:HandleClick()
    -- 1. Raycast to find what was clicked
    local mouse = Players.LocalPlayer:GetMouse()
    local target = mouse.Target
    
    if target and target.Name:match("Shelf_%d") then
        -- 2. Extract Shelf Number (e.g., "Shelf_1" -> 1)
        local shelfIndex = tonumber(target.Name:match("%d+"))
        
        -- 3. Get Selected Item from Inventory
        local selectedUUID = self.InventoryController:GetSelectedItem()
        
        if selectedUUID then
            print("Attempting to place item on Shelf " .. shelfIndex)
            
            -- 4. Fire Server
            local remotes = ReplicatedStorage:WaitForChild("Remotes")
            local placeEvent = remotes:WaitForChild(GameConstants.Events.PLACE_ITEM)
            placeEvent:FireServer(selectedUUID, shelfIndex)
            
            -- Optional: Play a sound effect here
        else
            warn("Select an item from Inventory first!")
        end
    end
end

return TycoonController