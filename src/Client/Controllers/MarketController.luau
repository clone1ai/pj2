local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConstants = require(ReplicatedStorage.Configs.GameConstants)
-- Lazy load sibling controller
local InventoryController = nil 

local MarketController = {}
MarketController.Listings = {}

function MarketController:Init()
    local player = Players.LocalPlayer
    local gui = player:WaitForChild("PlayerGui")
    self.MainUI = gui:WaitForChild("MainUI", 10)
    
    if self.MainUI then
        self:SetupUI()
    end
end

function MarketController:Start()
    -- Load Sibling
    InventoryController = require(script.Parent.InventoryController)
    
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    
    -- Listen for Market Updates
    local refreshEvent = remotes:WaitForChild(GameConstants.Events.REFRESH_MARKET)
    refreshEvent.OnClientEvent:Connect(function(listings)
        self.Listings = listings
        self:RenderMarket()
    end)
    
    print("   -> MarketController Started")
end

function MarketController:SetupUI()
    -- 1. Setup List Button (In Inventory Frame)
    local invFrame = self.MainUI:FindFirstChild("InventoryFrame")
    if invFrame then
        local listBtn = invFrame:FindFirstChild("ListButton")
        local priceInput = invFrame:FindFirstChild("PriceInput")
        
        if listBtn and priceInput then
            -- Connect Click
            listBtn.MouseButton1Click:Connect(function()
                local price = tonumber(priceInput.Text)
                if price then
                    self:RequestList(price)
                else
                    warn("Please enter a valid number")
                    priceInput.Text = "Invalid!"
                    task.wait(1)
                    priceInput.Text = ""
                end
            end)
            
            -- Visibility Loop (Only show when item selected)
            -- We poll InventoryController for selection state
            task.spawn(function()
                while true do
                    if InventoryController and InventoryController:GetSelectedItem() then
                        listBtn.Visible = true
                        priceInput.Visible = true
                    else
                        listBtn.Visible = false
                        priceInput.Visible = false
                    end
                    task.wait(0.2)
                end
            end)
        end
    end
end

-- ==========================================
-- LOGIC: BUYING
-- ==========================================

function MarketController:RenderMarket()
    local frame = self.MainUI:FindFirstChild("MarketFrame")
    if not frame then return end
    
    local container = frame:FindFirstChild("Container")
    if not container then return end
    
    -- Clear Old
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    
    -- Render New
    for _, listing in ipairs(self.Listings) do
        local card = Instance.new("ImageButton") -- clickable card
        card.Name = listing.Id
        card.Parent = container
        card.BackgroundColor3 = self:GetRarityColor(listing.Item.Element)
        card.AutoButtonColor = true
        
        -- Text: Model Name
        local title = Instance.new("TextLabel")
        title.Text = listing.Item.Model
        title.Font = Enum.Font.FredokaOne
        title.TextSize = 14
        title.TextColor3 = Color3.new(1,1,1)
        title.BackgroundTransparency = 1
        title.Size = UDim2.new(1,0,0.3,0)
        title.Parent = card
        
        -- Text: Price
        local price = Instance.new("TextLabel")
        price.Text = "$" .. listing.Price
        price.Font = Enum.Font.FredokaOne
        price.TextSize = 18
        price.TextColor3 = Color3.fromRGB(100, 255, 100)
        price.BackgroundTransparency = 1
        price.Size = UDim2.new(1,0,0.3,0)
        price.Position = UDim2.new(0,0,0.3,0)
        price.Parent = card
        
        -- Text: Seller
        local seller = Instance.new("TextLabel")
        seller.Text = "Seller:\n" .. listing.SellerName
        seller.Font = Enum.Font.Code
        seller.TextSize = 10
        seller.TextColor3 = Color3.new(0.8,0.8,0.8)
        seller.BackgroundTransparency = 1
        seller.Size = UDim2.new(1,0,0.3,0)
        seller.Position = UDim2.new(0,0,0.65,0)
        seller.Parent = card
        
        -- Click to Buy
        card.MouseButton1Click:Connect(function()
            self:RequestBuy(listing)
        end)
    end
end

function MarketController:RequestBuy(listing)
    -- Sanity check: Don't buy own item
    if listing.SellerUserId == Players.LocalPlayer.UserId then
        warn("You cannot buy your own item!")
        return
    end
    
    print("Attempting to buy...")
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local buyFunc = remotes:WaitForChild(GameConstants.Events.BUY_LISTING)
    
    local success, result = pcall(function()
        return buyFunc:InvokeServer(listing.Id)
    end)
    
    if success and result.Success then
        print("✅ Purchase Successful!")
    else
        warn("Purchase Failed: " .. tostring(result.Msg))
    end
end

-- ==========================================
-- LOGIC: LISTING
-- ==========================================

function MarketController:RequestList(price)
    if not InventoryController then return end
    
    local uuid = InventoryController:GetSelectedItem()
    if not uuid then return end
    
    print("Listing item for $" .. price)
    
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local postFunc = remotes:WaitForChild(GameConstants.Events.POST_LISTING)
    
    local success, result = pcall(function()
        return postFunc:InvokeServer(uuid, price)
    end)
    
    if success and result.Success then
        print("✅ Item Listed!")
        -- Clear input and selection
        local input = self.MainUI.InventoryFrame.PriceInput
        input.Text = ""
        
        -- Deselect item in inventory controller (Hack: simulate click or manual reset)
        InventoryController.SelectedUUID = nil 
        InventoryController:UpdateDisplay()
    else
        warn("Listing Failed: " .. tostring(result.Msg))
    end
end

-- Helper (Duplicated from InventoryController for visual consistency)
function MarketController:GetRarityColor(element)
    if element == "Gold" then return Color3.fromRGB(255, 215, 0) end
    if element == "Void" then return Color3.fromRGB(80, 0, 150) end
    if element == "Glitch" then return Color3.fromRGB(255, 0, 0) end
    return Color3.fromRGB(100, 100, 100)
end

return MarketController