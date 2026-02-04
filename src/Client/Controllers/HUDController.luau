local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local HUDController = {}

function HUDController:Init()
    local player = Players.LocalPlayer
    self.PlayerGui = player:WaitForChild("PlayerGui")
end

function HUDController:Start()
    local mainUI = self.PlayerGui:WaitForChild("MainUI")
    
    -- 1. Hook up Currency
    local player = Players.LocalPlayer
    player:GetAttributeChangedSignal("RizzCoins"):Connect(function()
        self:UpdateCurrency(mainUI, player:GetAttribute("RizzCoins"))
    end)
    self:UpdateCurrency(mainUI, player:GetAttribute("RizzCoins") or 0)

    -- 2. Hook up Menu Buttons (Inventory/Market toggles)
    local menuFrame = mainUI:WaitForChild("MenuFrame")
    
    -- Inventory Toggle
    local invBtn = menuFrame:FindFirstChild("InventoryButton")
    if invBtn then
        invBtn.MouseButton1Click:Connect(function()
            self:ToggleFrame("InventoryFrame")
        end)
    end

    -- Market Toggle
    local mktBtn = menuFrame:FindFirstChild("MarketButton")
    if mktBtn then
        mktBtn.MouseButton1Click:Connect(function()
            self:ToggleFrame("MarketFrame")
        end)
    end
    
    -- 3. Close Buttons logic
    for _, frameName in pairs({"InventoryFrame", "MarketFrame"}) do
        local frame = mainUI:FindFirstChild(frameName)
        if frame then
            local close = frame:FindFirstChild("CloseButton")
            if close then
                close.MouseButton1Click:Connect(function() frame.Visible = false end)
            end
        end
    end
    
    -- NOTE: "Buy Box" logic is now handled exclusively by InventoryController
    
    print("   -> HUDController Started")
end

function HUDController:ToggleFrame(frameName)
    local frame = self.PlayerGui.MainUI:FindFirstChild(frameName)
    if frame then
        frame.Visible = not frame.Visible
    end
end

function HUDController:UpdateCurrency(ui, amount)
    local label = ui:FindFirstChild("CurrencyLabel")
    if label then
        label.Text = "💰 $" .. tostring(amount)
    end
end

return HUDController