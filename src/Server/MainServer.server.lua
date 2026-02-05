local MainServer = {}

local function Initialize()
    local Services = script.Parent:WaitForChild("Services")
    for _, module in ipairs(Services:GetChildren()) do
        if module:IsA("ModuleScript") then
            task.spawn(function()
                require(module).Start()
            end)
        end
    end
end

Initialize()
return MainServer