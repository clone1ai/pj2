local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- [NEW] Added this

local ServicesFolder = ServerScriptService:WaitForChild("Services")
local Services = {}

print("🔵 SERVER: Booting...")

-- [[ CRITICAL FIX: Create Remotes Folder HERE first ]] --
-- This prevents MarketService from waiting for something that doesn't exist yet.
if not ReplicatedStorage:FindFirstChild("Remotes") then
    local folder = Instance.new("Folder")
    folder.Name = "Remotes"
    folder.Parent = ReplicatedStorage
    print("   ✅ Created Remotes Folder")
end

-- 1. Load Modules
print("🔵 SERVER: Loading Services...")
for _, module in ipairs(ServicesFolder:GetChildren()) do
    if module:IsA("ModuleScript") then
        local success, result = pcall(function()
            return require(module)
        end)
        
        if success then
            Services[module.Name] = result
            print("   ✅ Loaded: " .. module.Name)
        else
            warn("   ❌ FAILED: " .. module.Name .. " | Error: " .. result)
        end
    end
end

-- 2. Initialize
print("🔵 SERVER: Initializing...")
for name, service in pairs(Services) do
    if service.Init then service:Init() end
end

-- 3. Start
print("🔵 SERVER: Starting...")
for name, service in pairs(Services) do
    if service.Start then task.spawn(function() service:Start() end) end
end

print("🟢 SERVER: Boot Complete")