local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui") -- [NEW]

local MainClient = {}

local function Initialize()
    print("[Client] Initializing Systems...")
    
    pcall(function()
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    end)

    local Controllers = script.Parent:WaitForChild("Controllers")
    for _, module in ipairs(Controllers:GetChildren()) do
        if module:IsA("ModuleScript") then
            -- This line will now automatically load VisualController
            task.spawn(function() require(module).Start() end)
        end
    end
end

Initialize()
return MainClient