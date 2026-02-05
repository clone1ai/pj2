local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local MainClient = {}

local function Initialize()
    print("[Client] Initializing Systems...")

    -- Disable default backpack
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    end)

    -- 1. Initialize Controllers (Inventory, Minting, etc.)
    local Controllers = script.Parent:WaitForChild("Controllers")
    for _, module in ipairs(Controllers:GetChildren()) do
        if module:IsA("ModuleScript") then
            task.spawn(function()
                require(module).Start()
            end)
        end
    end

    -- 2. Initialize UI (The new HUDs)
    local UI = script.Parent:WaitForChild("UI")
    
    -- Load the Pro HUD (Money + Income)
    local IncomeHUD = require(UI:WaitForChild("IncomeHUD"))
    IncomeHUD.Init()
    
    -- (Do NOT require HUD.lua anymore)
end

Initialize()
return MainClient