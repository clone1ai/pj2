local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

-- specific wait to ensure folder exists
local _folder = ReplicatedStorage:WaitForChild("Net", 10) 
if not _folder then
    -- Fallback for first run if folder missing
    _folder = Instance.new("Folder")
    _folder.Name = "Net"
    _folder.Parent = ReplicatedStorage
end

function Remotes.GetRemoteFunction(name)
    local rf = _folder:FindFirstChild(name)
    if not rf then
        rf = Instance.new("RemoteFunction")
        rf.Name = name
        rf.Parent = _folder
    end
    return rf
end

return Remotes