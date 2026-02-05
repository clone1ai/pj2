local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SynergyService = {}

-- CONFIG
local EVENT_INTERVAL = 20 * 60 -- 20 Minutes (Set to 60 seconds for testing)
local EVENT_DURATION = 5 * 60  -- 5 Minutes (Set to 30 seconds for testing)

-- DATA LISTS (Must match your GameConfigs)
local ELEMENTS = {"Gold", "Void", "Glitch", "Fire", "Ice"}
local MODELS = {"Skibidi", "Nugget", "Sigma", "Camera", "Toilet"}

-- STATE
-- We store the current event in ReplicatedStorage Attributes so everyone can see it instantly
local StatusObj = ReplicatedStorage

function SynergyService.Start()
    print("[SynergyService] Started")
    
    -- Initialize Attributes
    StatusObj:SetAttribute("EventName", "None")
    StatusObj:SetAttribute("EventMultiplier", 1)
    StatusObj:SetAttribute("EventEndTime", 0)
    StatusObj:SetAttribute("EventType", "None") -- "Single" or "Combo"
    StatusObj:SetAttribute("EventTarget1", "")
    StatusObj:SetAttribute("EventTarget2", "")

    -- Main Loop
    task.spawn(function()
        while true do
            -- Wait for next event
            -- (Change EVENT_INTERVAL to 30 for quick testing)
            task.wait(EVENT_INTERVAL) 
            
            SynergyService.TriggerRandomEvent()
        end
    end)
end

function SynergyService.TriggerRandomEvent()
    local duration = math.random(5 * 60, 10 * 60) -- 5-10 mins
    local endTime = os.time() + duration
    
    local roll = math.random(1, 2)
    
    if roll == 1 then
        -- TYPE 1: SINGLE BUFF (Element)
        local elem = ELEMENTS[math.random(1, #ELEMENTS)]
        local mult = math.random(3, 8) -- x3 to x8
        
        StatusObj:SetAttribute("EventType", "Single")
        StatusObj:SetAttribute("EventName", "ELEMENT SURGE: " .. elem)
        StatusObj:SetAttribute("EventTarget1", elem)
        StatusObj:SetAttribute("EventMultiplier", mult)
        StatusObj:SetAttribute("EventEndTime", endTime)
        
        print("EVENT STARTED: " .. elem .. " x" .. mult)
        
    else
        -- TYPE 2: COMBO BUFF (Model + Element)
        local model = MODELS[math.random(1, #MODELS)]
        local elem = ELEMENTS[math.random(1, #ELEMENTS)]
        local mult = math.random(15, 25) -- x15 to x25!
        
        StatusObj:SetAttribute("EventType", "Combo")
        StatusObj:SetAttribute("EventName", "SYNERGY: " .. model .. " + " .. elem)
        StatusObj:SetAttribute("EventTarget1", model)
        StatusObj:SetAttribute("EventTarget2", elem)
        StatusObj:SetAttribute("EventMultiplier", mult)
        StatusObj:SetAttribute("EventEndTime", endTime)
        
        print("EVENT STARTED: Combo " .. model .. "+" .. elem .. " x" .. mult)
    end
    
    -- End Event logic
    task.delay(duration, function()
        StatusObj:SetAttribute("EventName", "None")
        StatusObj:SetAttribute("EventMultiplier", 1)
        StatusObj:SetAttribute("EventType", "None")
        print("EVENT ENDED")
    end)
end

-- Helper for FarmService to read current state
function SynergyService.GetCurrentBuffs()
    local now = os.time()
    local endT = StatusObj:GetAttribute("EventEndTime") or 0
    
    if now > endT then return nil end -- No active event
    
    return {
        Type = StatusObj:GetAttribute("EventType"),
        Target1 = StatusObj:GetAttribute("EventTarget1"),
        Target2 = StatusObj:GetAttribute("EventTarget2"),
        Multiplier = StatusObj:GetAttribute("EventMultiplier")
    }
end

return SynergyService