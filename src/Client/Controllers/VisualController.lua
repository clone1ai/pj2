local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local VisualController = {}

function VisualController.Start()
    print("[VisualController] Started - Watching for Floaters")

    -- Animation Logic
    local function setupAnimation(motor)
        if not motor:IsA("Motor6D") then return end
        
        -- Animation Config
        local BOB_SPEED = 3    -- How fast it moves up/down
        local BOB_HEIGHT = 0.5 -- How much it moves
        local SPIN_SPEED = 1.5 -- Rotation speed
        local BASE_HEIGHT = 4.5 -- Must match server offset
        
        local connection
        connection = RunService.RenderStepped:Connect(function()
            -- Stop if object is destroyed
            if not motor.Parent then 
                connection:Disconnect() 
                return 
            end
            
            local t = os.clock()
            
            -- Math: Sine Wave for Y-Axis, Rotation for Y-Angle
            local bobOffset = math.sin(t * BOB_SPEED) * BOB_HEIGHT
            local spinRotation = CFrame.Angles(0, t * SPIN_SPEED, 0)
            
            -- Apply transform
            motor.C0 = CFrame.new(0, BASE_HEIGHT + bobOffset, 0) * spinRotation
        end)
    end

    -- 1. Listen for new floaters
    CollectionService:GetInstanceAddedSignal("FloatingBrainrot"):Connect(setupAnimation)

    -- 2. Catch existing ones (if any)
    for _, obj in pairs(CollectionService:GetTagged("FloatingBrainrot")) do
        setupAnimation(obj)
    end
end

return VisualController