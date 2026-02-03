local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConstants = require(ReplicatedStorage.Configs.GameConstants)

local EventService = {}
EventService.CurrentBuff = nil -- Stores the active buff table

function EventService:Init()
    local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
    
    local eventRemote = remotesFolder:FindFirstChild(GameConstants.Events.MARKET_EVENT)
    if not eventRemote then
        eventRemote = Instance.new("RemoteEvent")
        eventRemote.Name = GameConstants.Events.MARKET_EVENT
        eventRemote.Parent = remotesFolder
    end
end

function EventService:Start()
    print("   -> EventService Started")
    
    -- Event Loop
    task.spawn(function()
        while true do
            -- 1. Wait for next event
            task.wait(GameConstants.EVENT_INTERVAL)
            
            -- 2. Trigger Event
            self:TriggerRandomEvent()
            
            -- 3. Wait for duration
            task.wait(GameConstants.EVENT_DURATION)
            
            -- 4. End Event
            self:EndEvent()
        end
    end)
end

function EventService:TriggerRandomEvent()
    local buffs = GameConstants.Buffs
    -- Pick random buff
    local randomBuff = buffs[math.random(1, #buffs)]
    
    self.CurrentBuff = randomBuff
    
    print("🚨 MARKET EVENT: " .. randomBuff.Message)
    
    -- Notify all clients (for UI)
    local remote = ReplicatedStorage.Remotes:FindFirstChild(GameConstants.Events.MARKET_EVENT)
    if remote then
        remote:FireAllClients({ Active = true, Buff = randomBuff })
    end
end

function EventService:EndEvent()
    self.CurrentBuff = nil
    print("🚨 MARKET EVENT ENDED")
    
    local remote = ReplicatedStorage.Remotes:FindFirstChild(GameConstants.Events.MARKET_EVENT)
    if remote then
        remote:FireAllClients({ Active = false })
    end
end

-- API for TycoonService to check buffs
function EventService:GetMultiplier(itemData)
    if not self.CurrentBuff then return 1 end
    
    local buff = self.CurrentBuff
    
    -- Check Element Buff (e.g., Gold x5)
    if buff.Type == "Element" and itemData.Element == buff.Target then
        return buff.Multiplier
    end
    
    -- Check Model Buff (e.g., Grimace x10)
    if buff.Type == "Model" and itemData.Model == buff.Target then
        return buff.Multiplier
    end
    
    return 1
end

return EventService