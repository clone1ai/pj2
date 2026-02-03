local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 🛑 FIX: Ensure this looks for "Controllers", not "Source.Client.Controllers"
local ControllersFolder = script.Parent:WaitForChild("Controllers")
local Controllers = {}

print("🟠 CLIENT: Loading Controllers...")

for _, module in ipairs(ControllersFolder:GetChildren()) do
    if module:IsA("ModuleScript") then
        local success, result = pcall(function()
            return require(module)
        end)
        
        if success then
            Controllers[module.Name] = result
            print("   ✅ Loaded: " .. module.Name)
        else
            warn("   ❌ FAILED: " .. module.Name .. " | Error: " .. result)
        end
    end
end

print("🟠 CLIENT: Initializing...")
for name, controller in pairs(Controllers) do
    if controller.Init then controller:Init() end
end

print("🟠 CLIENT: Starting...")
for name, controller in pairs(Controllers) do
    if controller.Start then task.spawn(function() controller:Start() end) end
end

print("🟢 CLIENT: Boot Complete")