local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConstants = require(ReplicatedStorage.Configs.GameConstants)

local InventoryController = {}
InventoryController.LocalInventory = {}
InventoryController.SelectedUUID = nil -- [NEW] Tracks selected item

function InventoryController:Init()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    self.MainUI = playerGui:WaitForChild("MainUI", 10)
    
    if self.MainUI then
        self:SetupUI()
    end
end

function InventoryController:Start()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local syncEvent = remotes:WaitForChild(GameConstants.Events.SYNC_DATA)
    
    syncEvent.OnClientEvent:Connect(function(profileData)
        if profileData and profileData.Inventory then
            self.LocalInventory = profileData.Inventory
            self:UpdateDisplay()
        end
    end)
    
    print("   -> InventoryController Started")
end

function InventoryController:SetupUI()
    local mintBtn = self.MainUI:FindFirstChild("MintButton", true)
    if mintBtn then
        mintBtn.MouseButton1Click:Connect(function() self:RequestMint() end)
    end

    local sellBtn = self.MainUI:FindFirstChild("SellButton", true)
    if sellBtn then
        sellBtn.MouseButton1Click:Connect(function()
            self:RequestQuickSell()
        end)
        self.SellButton = sellBtn
        self.SellButton.Visible = false -- Hide until selected
    end
end
function InventoryController:RequestQuickSell()
    local uuid = self.SelectedUUID
    if not uuid then return end
    
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local sellFunc = remotes:WaitForChild(GameConstants.Events.QUICK_SELL)
    
    -- Disable button to prevent double clicks
    if self.SellButton then self.SellButton.Active = false end
    
    local success, result = pcall(function()
        return sellFunc:InvokeServer(uuid)
    end)
    
    if success and result and result.Success then
        print("💰 Sold for $" .. result.SoldAmount)
        
        -- Remove from local inventory array instantly for snappiness
        for i, item in ipairs(self.LocalInventory) do
            if item.UUID == uuid then
                table.remove(self.LocalInventory, i)
                break
            end
        end
        
        self.SelectedUUID = nil -- Deselect
        if self.SellButton then 
            self.SellButton.Visible = false 
            self.SellButton.Active = true
        end
        self:UpdateDisplay()
    else
        warn("Sell Failed")
        if self.SellButton then self.SellButton.Active = true end
    end
end
-- [NEW] Helper for other Controllers to get data
function InventoryController:GetSelectedItem()
    return self.SelectedUUID
end

function InventoryController:RequestMint()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local mintFunc = remotes:WaitForChild(GameConstants.Events.REQUEST_MINT)
    
    local success, result = pcall(function() return mintFunc:InvokeServer() end)
    
    if success and result and result.Success then
        table.insert(self.LocalInventory, result.Item)
        self:UpdateDisplay()
    else
        warn("Mint Failed")
    end
end

function InventoryController:UpdateDisplay()
    local container = self.MainUI:FindFirstChild("Container", true)
    if not container then return end
    
    -- Clear old
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("GuiButton") then child:Destroy() end
    end
    
    -- Sort (Highest Value first)
    table.sort(self.LocalInventory, function(a, b) return a.FloorPrice > b.FloorPrice end)
    
    if self.SellButton then
        if self.SelectedUUID then
            -- Find the item data to calculate 50%
            local selectedItem = nil
            for _, item in ipairs(self.LocalInventory) do
                if item.UUID == self.SelectedUUID then selectedItem = item break end
            end
            
            if selectedItem then
                local sellPrice = math.floor(selectedItem.FloorPrice * GameConstants.QUICK_SELL_PERCENT)
                self.SellButton.Text = "QUICK SELL ($" .. sellPrice .. ")"
                self.SellButton.Visible = true
            end
        else
            self.SellButton.Visible = false
        end
    end
    -- Render
    for _, item in ipairs(self.LocalInventory) do
        local btn = Instance.new("TextButton")
        btn.Name = item.UUID
        btn.Parent = container
        btn.BackgroundColor3 = self:GetRarityColor(item.Element)
        btn.Text = ""
        btn.Font = Enum.Font.FredokaOne
        btn.TextSize = 14
        
        -- Highlighting Logic [NEW]
        if self.SelectedUUID == item.UUID then
            btn.BorderSizePixel = 3
            btn.BorderColor3 = Color3.new(1,1,1) -- White border for selected
        else
            btn.BorderSizePixel = 0
        end
        
        -- Item Info
        local label = Instance.new("TextLabel")
        label.Text = item.Model .. "\n$" .. item.FloorPrice
        label.Size = UDim2.new(1,0,1,0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1,1,1)
        label.Font = Enum.Font.FredokaOne
        label.Parent = btn
        
        -- Selection Click [NEW]
        btn.MouseButton1Click:Connect(function()
            self.SelectedUUID = item.UUID
            self:UpdateDisplay() -- Refresh to show border
            print("Selected: " .. item.Model)
        end)
    end
end

function InventoryController:GetRarityColor(element)
    if element == "Gold" then return Color3.fromRGB(255, 215, 0) end
    if element == "Void" then return Color3.fromRGB(80, 0, 150) end
    if element == "Glitch" then return Color3.fromRGB(255, 0, 0) end
    return Color3.fromRGB(100, 100, 100)
end

return InventoryController