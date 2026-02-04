local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConstants = require(ReplicatedStorage.Configs.GameConstants)

local EventService = {}
EventService.CurrentBuff = nil -- Stores the active buff data
EventService.NextEventTime = 0

function EventService:Init()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    
    -- Event to notify clients of market changes (for UI effects)
    local marketEvent = remotes:FindFirstChild(GameConstants.Events.MARKET_EVENT)
    if not marketEvent then
        marketEvent = Instance.new("RemoteEvent")
        marketEvent.Name = GameConstants.Events.MARKET_EVENT
        marketEvent.Parent = remotes
    end
end

function EventService:Start()
    print("   -> EventService Started")
    
    -- Start the Event Loop
    task.spawn(function()
        while true do
            -- 1. Wait for interval
            task.wait(GameConstants.INJECTION_INTERVAL or 1200) -- Default 20 mins
            
            -- 2. Trigger Event
            self:TriggerRandomEvent()
            
            -- 3. Wait for duration
            task.wait(GameConstants.EVENT_DURATION or 300) -- Default 5 mins
            
            -- 4. End Event
            self:EndEvent()
        end
    end)
end

function EventService:TriggerRandomEvent()
    local buffs = GameConstants.Buffs
    if not buffs or #buffs == 0 then return end
    
    -- Pick random buff
    local selectedBuff = buffs[math.random(1, #buffs)]
    self.CurrentBuff = selectedBuff
    
    print("🚨 MARKET EVENT: " .. selectedBuff.Message)
    
    -- Notify all clients (Pop up UI)
    ReplicatedStorage.Remotes[GameConstants.Events.MARKET_EVENT]:FireAllClients("Start", selectedBuff)
end

function EventService:EndEvent()
    if self.CurrentBuff then
        print("✅ MARKET EVENT ENDED")
        self.CurrentBuff = nil
        ReplicatedStorage.Remotes[GameConstants.Events.MARKET_EVENT]:FireAllClients("End", nil)
    end
end

-- Called by TycoonService to calculate income
function EventService:GetMultiplier(itemData)
    if not self.CurrentBuff then return 1 end
    
    local buff = self.CurrentBuff
    
    -- Check if item matches buff criteria
    if buff.Type == "Element" and itemData.Element == buff.Target then
        return buff.Multiplier
    elseif buff.Type == "Model" and itemData.Model == buff.Target then
        return buff.Multiplier
    end
    
    return 1
end

return EventService