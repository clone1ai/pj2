local Brainrot = {}
Brainrot.__index = Brainrot

function Brainrot.new(data)
    local self = setmetatable({}, Brainrot)
    
    self.Id = data.Id or game:GetService("HttpService"):GenerateGUID(false)
    self.Model = data.Model or "Nugget"
    self.Element = data.Element or "Plastic"
    self.Size = data.Size or 1.0
    
    -- Floor Price Calculation (Intrinsic Value)
    -- This is calculated once and saved.
    self.FloorPrice = data.FloorPrice or 0 
    
    return self
end

function Brainrot.CalculateFloorPrice(baseCost, modelMult, elementMult, size)
    -- Floor Price = (Base Box Cost) * (Model Mult) * (Element Mult) * (Size Mult)
    -- Size Mult is direct 1:1 with size float in this logic
    return baseCost * modelMult * elementMult * size
end

return Brainrot