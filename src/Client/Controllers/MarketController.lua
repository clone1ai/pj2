local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketController = {}

local NetFolder = ReplicatedStorage:WaitForChild("Net")
local Remotes = require(NetFolder:WaitForChild("Remotes"))
local UI = script.Parent.Parent:WaitForChild("UI")
local MarketUI = require(UI:WaitForChild("MarketUI"))

-- Asset Folder
local Assets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Brains")

local GetMarketRF = Remotes.GetRemoteFunction("GetMarketData")
local GetPlayerListingsRF = Remotes.GetRemoteFunction("GetPlayerListings")
local BuyItemRF = Remotes.GetRemoteFunction("BuyItem")
local RemoveListingRF = Remotes.GetRemoteFunction("RemoveListing")

-- State
local CurrentTab = "Global" 
local SelectedListing = nil
local DisplayItems = {}

function MarketController.Start()
    print("[MarketController] Starting UI...")
    local uiRef = MarketUI.Create()
    
    if not uiRef.Toggle then warn("CRITICAL: Toggle Button Missing!") return end
    if not uiRef.Close then warn("CRITICAL: Close Button Missing!") return end
    
    local function ClearSelection()
        SelectedListing = nil
        uiRef.Details.ItemNameLabel.Text = "Select an Item"
        uiRef.Details.PriceLabel.Text = "---"
        
        -- Reset Detail Labels
        uiRef.Details.UID.Text = "UID: ---"
        uiRef.Details.Element.Text = "Element: ---"
        uiRef.Details.Model.Text = "Model: ---"
        uiRef.Details.Size.Text = "Size: ---"
        uiRef.Details.Seller.Text = "Seller: ---"
        
        uiRef.Details.Button.Text = "SELECT ITEM"
        uiRef.Details.Button.BackgroundColor3 = Color3.fromRGB(60,60,60)
        uiRef.Details.Button.TextColor3 = Color3.fromRGB(180,180,180)
    end

    -- Toggle
    uiRef.Toggle.MouseButton1Click:Connect(function()
        uiRef.Frame.Visible = not uiRef.Frame.Visible
        if uiRef.Frame.Visible then 
            MarketController.Refresh(uiRef) 
            ClearSelection()
        end
    end)
    
    -- Close
    uiRef.Close.MouseButton1Click:Connect(function()
        uiRef.Frame.Visible = false
    end)
    
    -- Tabs
    local function SetTab(tabName)
        CurrentTab = tabName
        ClearSelection()
        if tabName == "Global" then
            uiRef.Tabs.Global.TextColor3 = Color3.fromRGB(46, 204, 113) 
            uiRef.Tabs.Personal.TextColor3 = Color3.fromRGB(150, 150, 150)
        else
            uiRef.Tabs.Personal.TextColor3 = Color3.fromRGB(46, 204, 113)
            uiRef.Tabs.Global.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
        MarketController.Refresh(uiRef)
    end

    uiRef.Tabs.Global.MouseButton1Click:Connect(function() SetTab("Global") end)
    uiRef.Tabs.Personal.MouseButton1Click:Connect(function() SetTab("Personal") end)
    
    -- Refresh
    uiRef.Refresh.MouseButton1Click:Connect(function()
        MarketController.Refresh(uiRef)
        ClearSelection()
    end)
    
    -- Action Button
    uiRef.Details.Button.MouseButton1Click:Connect(function()
        if not SelectedListing then return end
        
        local isMine = (SelectedListing.SellerName == game.Players.LocalPlayer.Name)
        
        if isMine or CurrentTab == "Personal" then
            uiRef.Details.Button.Text = "REMOVING..."
            local res = RemoveListingRF:InvokeServer(SelectedListing.ListingId)
            if res.Success then
                MarketController.Refresh(uiRef)
                ClearSelection()
            else
                uiRef.Details.Button.Text = "FAILED"
                task.wait(1)
                uiRef.Details.Button.Text = "TAKE DOWN"
            end
        else
            uiRef.Details.Button.Text = "BUYING..."
            local res = BuyItemRF:InvokeServer(SelectedListing.ListingId)
            if res.Success then
                uiRef.Details.Button.Text = "PURCHASED!"
                task.wait(1)
                MarketController.Refresh(uiRef)
                ClearSelection()
            else
                uiRef.Details.Button.Text = res.Msg or "Error"
                task.wait(1)
                uiRef.Details.Button.Text = "BUY NOW"
            end
        end
    end)
end

function MarketController.Refresh(uiRef)
    if CurrentTab == "Global" then
        DisplayItems = GetMarketRF:InvokeServer() or {}
    else
        DisplayItems = GetPlayerListingsRF:InvokeServer() or {}
    end
    MarketController.Render(uiRef)
end

function MarketController.Render(uiRef)
    -- 1. Clear Grid
    for _, c in pairs(uiRef.Grid:GetChildren()) do 
        if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end 
    end
    
    local myName = game.Players.LocalPlayer.Name
    table.sort(DisplayItems, function(a,b) return a.ListingPrice < b.ListingPrice end)
    
    for _, item in ipairs(DisplayItems) do
        local isMine = (item.SellerName == myName)
        
        if CurrentTab == "Global" and isMine then continue end

        -- 2. CREATE CARD CONTAINER
        local card = Instance.new("TextButton")
        card.Text = ""
        card.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        card.ZIndex = 10 
        card.Parent = uiRef.Grid
        
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(70, 70, 70)
        stroke.Thickness = 1
        stroke.Parent = card

        -- 3. VIEWPORT FRAME (3D Model)
        local viewport = Instance.new("ViewportFrame")
        viewport.Size = UDim2.new(1, 0, 0.7, 0) -- Top 70% of card
        viewport.Position = UDim2.new(0, 0, 0, 10)
        viewport.BackgroundTransparency = 1
        viewport.LightColor = Color3.fromRGB(255, 255, 255)
        viewport.Ambient = Color3.fromRGB(150, 150, 150)
        viewport.ZIndex = 11 
        viewport.Parent = card
        
        local originalModel = Assets:FindFirstChild(item.Model)
        if originalModel then
            local clone = originalModel:Clone()
            clone.Parent = viewport
            local cam = Instance.new("Camera")
            viewport.CurrentCamera = cam
            cam.Parent = viewport
            local cf, size = clone:GetBoundingBox()
            local maxDim = math.max(size.X, size.Y, size.Z)
            local dist = maxDim * 1.5
            cam.CFrame = CFrame.new(cf.Position + Vector3.new(dist, dist*0.5, dist), cf.Position)
        end
        
        -- 4. Item Name Overlay
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Text = item.Name
        nameLbl.Size = UDim2.new(1, -10, 0, 20)
        nameLbl.Position = UDim2.new(0, 5, 0, 5)
        nameLbl.BackgroundTransparency = 1
        nameLbl.TextColor3 = Color3.new(1,1,1)
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 11
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.ZIndex = 12 
        nameLbl.Parent = card
        
        -- 5. Price Pill
        local pricePill = Instance.new("Frame")
        pricePill.Size = UDim2.new(0.9, 0, 0, 30)
        pricePill.Position = UDim2.new(0.05, 0, 0.8, -5)
        pricePill.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        pricePill.ZIndex = 11 
        pricePill.Parent = card
        Instance.new("UICorner", pricePill).CornerRadius = UDim.new(0, 6)
        
        local priceLbl = Instance.new("TextLabel")
        priceLbl.Text = "$" .. item.ListingPrice
        priceLbl.Size = UDim2.new(1, 0, 1, 0)
        priceLbl.BackgroundTransparency = 1
        priceLbl.TextColor3 = Color3.fromRGB(46, 204, 113) 
        priceLbl.Font = Enum.Font.GothamBold
        priceLbl.TextSize = 14
        priceLbl.ZIndex = 12 
        priceLbl.Parent = pricePill

        -- 6. Click Logic (Populate Details)
        card.MouseButton1Click:Connect(function()
            SelectedListing = item
            
            uiRef.Details.ItemNameLabel.Text = item.Name
            uiRef.Details.PriceLabel.Text = "$" .. item.ListingPrice
            
            -- [NEW] Populate Detailed Stats
            uiRef.Details.UID.Text = "UID: " .. (item.Id:sub(1,8) .. "...")
            uiRef.Details.Element.Text = "Element: " .. (item.Element or "None")
            uiRef.Details.Model.Text = "Model: " .. (item.Model or "Unknown")
            uiRef.Details.Size.Text = "Size: " .. string.format("%.1f", item.Size or 1.0)
            uiRef.Details.Seller.Text = "Seller: " .. (item.SellerName or "System")
            
            uiRef.Details.Button.TextColor3 = Color3.new(1,1,1)
            
            if isMine or CurrentTab == "Personal" then
                uiRef.Details.Button.Text = "TAKE DOWN"
                uiRef.Details.Button.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            else
                uiRef.Details.Button.Text = "BUY NOW"
                uiRef.Details.Button.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            end
        end)
    end
end

return MarketController