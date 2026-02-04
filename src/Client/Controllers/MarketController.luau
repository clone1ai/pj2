local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConstants = require(ReplicatedStorage.Configs.GameConstants)
local InventoryController = nil -- Lazy load

local MarketController = {}
MarketController.Listings = {}
MarketController.IsProcessing = false

function MarketController:Init()
    -- Internal setup only
end

function MarketController:Start()
    -- 1. Get InventoryController reference
    InventoryController = require(script.Parent.InventoryController)
    
    local player = Players.LocalPlayer
    local gui = player:WaitForChild("PlayerGui")
    self.MainUI = gui:WaitForChild("MainUI") 
    
    self:SetupUI()
    
    -- Networking
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local refreshEvent = remotes:WaitForChild(GameConstants.Events.REFRESH_MARKET)
    
    refreshEvent.OnClientEvent:Connect(function(listings)
        self.Listings = listings
        self:RenderMarket()
    end)
    
    print("   -> MarketController Started")
end

function MarketController:SetupUI()
    -- The list button is handled inside InventoryController for better modularity
end

-- [[ RENDER LOGIC ]] --
function MarketController:RenderMarket()
    if not self.MainUI then return end
    local frame = self.MainUI:FindFirstChild("MarketFrame")
    if not frame then return end
    
    local container = frame:FindFirstChild("Container")
    if not container then return end
    
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    
    for _, listing in ipairs(self.Listings) do
        self:CreateListingCard(listing, container)
    end
end

function MarketController:CreateListingCard(listing, container)
    local card = Instance.new("ImageButton")
    card.Name = listing.ID
    card.BackgroundColor3 = self:GetRarityColor(listing.ItemData.Element)
    card.Size = UDim2.new(0, 100, 0, 120)
    card.Parent = container
    
    local uiList = Instance.new("UIListLayout")
    uiList.Parent = card
    uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    uiList.Padding = UDim.new(0, 5)
    
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Text = listing.ItemData.Model
    nameLbl.Size = UDim2.new(1,0,0.3,0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = Enum.Font.FredokaOne
    nameLbl.Parent = card
    
    local priceLbl = Instance.new("TextLabel")
    priceLbl.Text = "$" .. listing.Price
    priceLbl.TextColor3 = Color3.fromRGB(100, 255, 100)
    priceLbl.Size = UDim2.new(1,0,0.3,0)
    priceLbl.BackgroundTransparency = 1
    priceLbl.Font = Enum.Font.FredokaOne
    priceLbl.Parent = card

    card.MouseButton1Click:Connect(function()
        self:RequestBuy(listing)
    end)
end

-- [[ INTERACTION LOGIC ]] --
function MarketController:RequestBuy(listing)
    if self.IsProcessing then return end
    
    if listing.SellerUserId == Players.LocalPlayer.UserId then
        warn("Cannot buy your own item.")
        return
    end
    
    self.IsProcessing = true
    
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local buyFunc = remotes:WaitForChild(GameConstants.Events.BUY_LISTING)
    
    local success, resultBool, resultMsg = pcall(function()
        return buyFunc:InvokeServer(listing.ID)
    end)
    
    self.IsProcessing = false
    
    if success and resultBool then
        print("✅ Purchase Successful!")
    else
        warn("Purchase Failed: " .. tostring(resultMsg))
    end
end

function MarketController:RequestList(price)
    if not InventoryController then 
        warn("⚠️ MarketController: InventoryController not found!")
        return 
    end
    
    -- [[ FIX: use GetSelectedItem() instead of .SelectedItemID ]] --
    local uuid = InventoryController:GetSelectedItem()
    
    if not uuid then 
        warn("⚠️ MarketController: No Item UUID selected!")
        return 
    end
    
    if self.IsProcessing then return end
    self.IsProcessing = true 
    
    print("📤 Requesting List for Item: " .. uuid .. " at $" .. price)

    -- Visual Feedback
    local listBtn = self.MainUI.InventoryFrame:FindFirstChild("ListButton")
    local originalText = listBtn and listBtn.Text or "LIST"
    if listBtn then listBtn.Text = "..." end
    
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local postFunc = remotes:WaitForChild(GameConstants.Events.POST_LISTING)
    
    local success, resultBool, resultMsg = pcall(function()
        return postFunc:InvokeServer(uuid, price)
    end)
    
    self.IsProcessing = false
    if listBtn then listBtn.Text = originalText end
    
    if success and resultBool then
        print("✅ Item Listed!")
        if self.MainUI.InventoryFrame:FindFirstChild("PriceInput") then
            self.MainUI.InventoryFrame.PriceInput.Text = ""
        end
        
        -- Force Deselect
        if InventoryController.SelectedUUID == uuid then
            InventoryController.SelectedUUID = nil
            InventoryController:UpdateDisplay()
        end
    else
        warn("Listing Failed: " .. tostring(resultMsg))
    end
end

function MarketController:GetRarityColor(element)
    if element == "Gold" then return Color3.fromRGB(255, 215, 0)
    elseif element == "Void" then return Color3.fromRGB(80, 0, 150)
    elseif element == "Glitch" then return Color3.fromRGB(255, 0, 0)
    else return Color3.fromRGB(200, 200, 200) end
end

return MarketController