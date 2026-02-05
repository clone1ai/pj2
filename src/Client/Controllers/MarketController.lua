local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketController = {}

local NetFolder = ReplicatedStorage:WaitForChild("Net")
local Remotes = require(NetFolder:WaitForChild("Remotes"))
local UI = script.Parent.Parent:WaitForChild("UI")
local MarketUI = require(UI:WaitForChild("MarketUI"))

local GetMarketRF = Remotes.GetRemoteFunction("GetMarketData")
local GetPlayerListingsRF = Remotes.GetRemoteFunction("GetPlayerListings") -- [NEW]
local BuyItemRF = Remotes.GetRemoteFunction("BuyItem")
local RemoveListingRF = Remotes.GetRemoteFunction("RemoveListing")

-- State
local CurrentTab = "Global" 
local SelectedListing = nil
local DisplayItems = {} -- We store the current view here

function MarketController.Start()
    print("[MarketController] Started")
    local uiRef = MarketUI.Create()
    
    local function ClearSelection()
        SelectedListing = nil
        uiRef.Details.Name.Text = "Select Item"
        uiRef.Details.Price.Text = ""
        uiRef.Details.Button.Text = "ACTION"
        uiRef.Details.Button.BackgroundColor3 = Color3.fromRGB(100,100,100)
    end

    uiRef.Toggle.MouseButton1Click:Connect(function()
        uiRef.Frame.Visible = not uiRef.Frame.Visible
        if uiRef.Frame.Visible then 
            MarketController.Refresh(uiRef) 
            ClearSelection()
        end
    end)
    
    uiRef.GlobalTab.MouseButton1Click:Connect(function()
        CurrentTab = "Global"
        uiRef.GlobalTab.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        uiRef.PersonalTab.BackgroundColor3 = Color3.fromRGB(60,60,60)
        ClearSelection()
        MarketController.Refresh(uiRef) -- Must fetch new data source
    end)
    
    uiRef.PersonalTab.MouseButton1Click:Connect(function()
        CurrentTab = "Personal"
        uiRef.PersonalTab.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        uiRef.GlobalTab.BackgroundColor3 = Color3.fromRGB(60,60,60)
        ClearSelection()
        MarketController.Refresh(uiRef) -- Must fetch new data source
    end)
    
    uiRef.Refresh.MouseButton1Click:Connect(function()
        MarketController.Refresh(uiRef)
        ClearSelection()
    end)
    
    uiRef.Details.Button.MouseButton1Click:Connect(function()
        if not SelectedListing then return end
        
        -- Logic: If Personal Tab OR Owner Name matches -> Take Down
        local isMine = (SelectedListing.SellerName == game.Players.LocalPlayer.Name)
        
        if isMine or CurrentTab == "Personal" then
            -- TAKE DOWN
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
            -- BUY
            uiRef.Details.Button.Text = "BUYING..."
            local res = BuyItemRF:InvokeServer(SelectedListing.ListingId)
            
            if res.Success then
                uiRef.Details.Button.Text = "PURCHASED!"
                task.wait(1)
                MarketController.Refresh(uiRef)
                ClearSelection()
            else
                uiRef.Details.Button.Text = res.Msg
                task.wait(1)
                uiRef.Details.Button.Text = "BUY ($" .. SelectedListing.ListingPrice .. ")"
            end
        end
    end)
end

function MarketController.Refresh(uiRef)
    if CurrentTab == "Global" then
        DisplayItems = GetMarketRF:InvokeServer() or {}
        print("Client Recv Global: " .. #DisplayItems) -- ADD THIS PRINT
    else
        DisplayItems = GetPlayerListingsRF:InvokeServer() or {}
    end
    MarketController.Render(uiRef)
end

function MarketController.Render(uiRef)
    for _, c in pairs(uiRef.Grid:GetChildren()) do 
        if c:IsA("TextButton") then c:Destroy() end 
    end
    
    local myName = game.Players.LocalPlayer.Name
    
    -- Sort by Price
    table.sort(DisplayItems, function(a,b) return a.ListingPrice < b.ListingPrice end)
    
    for _, item in ipairs(DisplayItems) do
        local isMine = (item.SellerName == myName)
        
        -- [CRITICAL] RESTORED THE HIDE FILTER FOR GLOBAL TAB
        if CurrentTab == "Global" and isMine then continue end

        local btn = Instance.new("TextButton")
        btn.Text = item.Name .. "\n$" .. item.ListingPrice
        btn.BackgroundColor3 = Color3.fromRGB(80,80,80)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.Parent = uiRef.Grid
        
        -- Color coding for Personal Tab
        if CurrentTab == "Personal" then
            btn.BackgroundColor3 = Color3.fromRGB(52, 152, 219) 
            btn.Text = item.Name .. "\n(LISTED) $" .. item.ListingPrice
        end
        
        btn.MouseButton1Click:Connect(function()
            SelectedListing = item
            uiRef.Details.Name.Text = item.Name
            uiRef.Details.Price.Text = "$" .. item.ListingPrice
            
            if isMine or CurrentTab == "Personal" then
                uiRef.Details.Button.Text = "TAKE DOWN"
                uiRef.Details.Button.BackgroundColor3 = Color3.fromRGB(231, 76, 60) 
            else
                uiRef.Details.Button.Text = "BUY ($" .. item.ListingPrice .. ")"
                uiRef.Details.Button.BackgroundColor3 = Color3.fromRGB(46, 204, 113) 
            end
        end)
    end
end

return MarketController