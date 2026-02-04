local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConstants = require(ReplicatedStorage.Configs.GameConstants)

local InventoryController = {}
InventoryController.LocalInventory = {}
InventoryController.SelectedUUID = nil 

function InventoryController:Init()
    -- Grab UI later in Start to prevent deadlocks
end

function InventoryController:Start()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    self.MainUI = playerGui:WaitForChild("MainUI", 10)
    
    if self.MainUI then
        self:SetupUI()
    end

    -- Listen for Data from Server
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
    if not self.MainUI then return end

    -- 1. Mint Button (Buy Box)
    local mintBtn = self.MainUI:FindFirstChild("BuyBoxButton", true) -- Search recursively
    if mintBtn then
        mintBtn.MouseButton1Click:Connect(function() self:RequestMint() end)
    end

    -- 2. Sell Button
    local sellBtn = self.MainUI:FindFirstChild("SellButton", true)
    if sellBtn then
        sellBtn.MouseButton1Click:Connect(function() self:RequestQuickSell() end)
        self.SellButton = sellBtn
        self.SellButton.Visible = false 
    end
    
    -- 3. [RESTORED] List Button logic
    local invFrame = self.MainUI:FindFirstChild("InventoryFrame")
    if invFrame then
        local listBtn = invFrame:FindFirstChild("ListButton")
        if listBtn then
            listBtn.MouseButton1Click:Connect(function() 
                self:OnListButtonPressed() -- Call the missing function
            end)
        end
    end
end

-- [[ INTERACTION LOGIC ]] --

function InventoryController:OnListButtonPressed()
    if not self.SelectedUUID then
        warn("No item selected to list!") 
        return 
    end
    
    local invFrame = self.MainUI:FindFirstChild("InventoryFrame")
    local priceInput = invFrame and invFrame:FindFirstChild("PriceInput")
    local price = tonumber(priceInput.Text)
    
    if not price or price <= 0 then
        if priceInput then
            priceInput.Text = "Invalid Price!"
            task.wait(1)
            priceInput.Text = ""
        end
        return
    end
    
    -- Delegate to MarketController (Lazy load to avoid cycles)
    local MarketController = require(script.Parent.MarketController)
    MarketController:RequestList(price)
end

function InventoryController:RequestQuickSell()
    local uuid = self.SelectedUUID
    if not uuid then return end
    
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local sellFunc = remotes:WaitForChild(GameConstants.Events.QUICK_SELL)
    
    if self.SellButton then self.SellButton.Active = false end
    
    local success, result = pcall(function()
        return sellFunc:InvokeServer(uuid)
    end)
    
    if success and result and result.Success then
        print("💰 Sold for $" .. result.SoldAmount)
        
        -- Remove locally for instant feedback
        for i, item in ipairs(self.LocalInventory) do
            if item.UUID == uuid then
                table.remove(self.LocalInventory, i)
                break
            end
        end
        
        self.SelectedUUID = nil 
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

function InventoryController:GetSelectedItem()
    return self.SelectedUUID
end

function InventoryController:RequestMint()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local mintFunc = remotes:WaitForChild(GameConstants.Events.REQUEST_MINT)
    
    local success, result = pcall(function() return mintFunc:InvokeServer() end)
    
    if success and result and result.Success then
        -- Add new item to local list
        table.insert(self.LocalInventory, result.Item)
        self:UpdateDisplay()
    else
        warn("Mint Failed")
    end
end

function InventoryController:UpdateDisplay()
    if not self.MainUI then return end
    
    -- 1. Find Container safely
    local invFrame = self.MainUI:FindFirstChild("InventoryFrame")
    local container = invFrame and invFrame:FindFirstChild("ScrollingFrame")
    
    if not container then return end
    
    -- 2. Clear Old
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("GuiButton") then child:Destroy() end
    end
    
    -- 3. Sort
    table.sort(self.LocalInventory, function(a, b) return a.FloorPrice > b.FloorPrice end)
    
    -- 4. Render
    for _, item in ipairs(self.LocalInventory) do
        local btn = Instance.new("TextButton")
        btn.Name = item.UUID
        btn.Parent = container
        btn.BackgroundColor3 = self:GetRarityColor(item.Element)
        btn.Text = ""
        btn.Size = UDim2.new(0, 90, 0, 90)
        
        -- Highlight Logic
        if self.SelectedUUID == item.UUID then
            btn.BorderSizePixel = 3
            btn.BorderColor3 = Color3.new(1,1,1)
        else
            btn.BorderSizePixel = 0
        end
        
        -- Labels
        local label = Instance.new("TextLabel")
        label.Text = item.Model .. "\n$" .. item.FloorPrice
        label.Size = UDim2.new(1,0,1,0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1,1,1)
        label.Font = Enum.Font.FredokaOne
        label.Parent = btn
        
        -- Click Logic (Select/Deselect)
        btn.MouseButton1Click:Connect(function()
            if self.SelectedUUID == item.UUID then
                self.SelectedUUID = nil -- Deselect
            else
                self.SelectedUUID = item.UUID -- Select
            end
            self:UpdateDisplay()
        end)
    end
    
    -- 5. Update Sell Button Visibility
    if self.SellButton then
        if self.SelectedUUID then
            -- Recalculate sell price for display
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
end

function InventoryController:GetRarityColor(element)
    if element == "Gold" then return Color3.fromRGB(255, 215, 0) end
    if element == "Void" then return Color3.fromRGB(80, 0, 150) end
    if element == "Glitch" then return Color3.fromRGB(255, 0, 0) end
    return Color3.fromRGB(100, 100, 100)
end

return InventoryController