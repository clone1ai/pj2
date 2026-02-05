local MainClient = {}

local function Initialize()
    local Controllers = script.Parent:WaitForChild("Controllers")
    for _, module in ipairs(Controllers:GetChildren()) do
        if module:IsA("ModuleScript") then
            task.spawn(function()
                require(module).Start()
            end)
        end
    end
end

Initialize()
return MainClient