--[[
    ╔══════════════════════════════════════════════╗
    ║         GPO FISHING HUB                      ║
    ║   Auto Fish • Auto Reel • Auto Store Fruits  ║
    ║         Educational Purposes Only            ║
    ╚══════════════════════════════════════════════╝
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ============================================
-- GLOBAL STATE
-- ============================================
_G.AutoFish = false
_G.AutoReel = false
_G.AutoBuyBait = false
_G.FishingSpeed = 1

_G.StoreCommon    = false
_G.StoreRare      = false
_G.StoreEpic      = false
_G.StoreLegendary = false
_G.StoreMythical  = false

-- ============================================
-- UI WINDOW
-- ============================================
local Window = Rayfield:CreateWindow({
    Name = "GPO Fishing Hub 🎣",
    LoadingTitle = "GPO Fishing Hub",
    LoadingSubtitle = "Loading...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GPOFishingHub",
        FileName = "FishConfig"
    },
    KeySystem = false,
})

-- ============================================
-- 🎣 FISHING TAB
-- ============================================
local FishingTab = Window:CreateTab("Fishing", 4483362458)

-- ── General Fishing ──────────────────────────
local GeneralSection = FishingTab:CreateSection("General Fishing")

-- ┌─────────────────────┐
-- │     AUTO CAST       │
-- └─────────────────────┘
-- Automatically equips the fishing rod and casts the line into water.
-- It detects when you're not fishing and recasts.

local AutoFishToggle = FishingTab:CreateToggle({
    Name = "Auto Cast (Auto Fish)",
    CurrentValue = false,
    Flag = "AutoFishToggle",
    Callback = function(Value)
        _G.AutoFish = Value
        if Value then
            game.StarterGui:SetCore("SendNotification", {
                Title = "GPO Fishing Hub",
                Text = "Auto Cast Enabled! Stand near water.",
                Duration = 3,
            })
            spawn(function()
                while _G.AutoFish do
                    pcall(function()
                        local character = player.Character
                        if not character then return end
                        
                        local playerGui = player:FindFirstChild("PlayerGui")
                        
                        -- Check if the fishing mini-game UI is NOT active
                        -- If not fishing, we need to cast
                        local isFishing = false
                        if playerGui then
                            for _, gui in pairs(playerGui:GetChildren()) do
                                if gui:IsA("ScreenGui") then
                                    -- Look for fishing-related UI elements
                                    local fishUI = gui:FindFirstChild("FishingBar") 
                                        or gui:FindFirstChild("FishBar")
                                        or gui:FindFirstChild("Bar")
                                        or gui:FindFirstChild("FishingFrame")
                                        or gui:FindFirstChild("Fishing")
                                    if fishUI and fishUI.Visible then
                                        isFishing = true
                                        break
                                    end
                                end
                            end
                        end
                        
                        if not isFishing then
                            -- Method 1: Try to find and use the fishing rod tool
                            local backpack = player:FindFirstChild("Backpack")
                            local character = player.Character
                            
                            -- Find fishing rod in backpack or character
                            local fishingRod = nil
                            if backpack then
                                for _, item in pairs(backpack:GetChildren()) do
                                    local itemName = item.Name:lower()
                                    if itemName:find("rod") or itemName:find("fishing") then
                                        fishingRod = item
                                        break
                                    end
                                end
                            end
                            if not fishingRod and character then
                                for _, item in pairs(character:GetChildren()) do
                                    local itemName = item.Name:lower()
                                    if itemName:find("rod") or itemName:find("fishing") then
                                        fishingRod = item
                                        break
                                    end
                                end
                            end
                            
                            -- Equip the rod if found in backpack
                            if fishingRod and fishingRod.Parent == backpack then
                                character.Humanoid:EquipTool(fishingRod)
                                wait(0.5)
                            end
                            
                            -- Activate the rod (cast) by simulating click
                            if fishingRod then
                                -- Method A: Activate the tool directly
                                if fishingRod:IsA("Tool") then
                                    fishingRod:Activate()
                                end
                                
                                -- Method B: Fire server remote if applicable
                                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                                if remotes then
                                    for _, remote in pairs(remotes:GetChildren()) do
                                        local remoteName = remote.Name:lower()
                                        if remoteName:find("cast") or remoteName:find("fish") then
                                            if remote:IsA("RemoteEvent") then
                                                remote:FireServer()
                                            elseif remote:IsA("RemoteFunction") then
                                                remote:InvokeServer()
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    
                    wait(2 / _G.FishingSpeed)
                end
            end)
        else
            game.StarterGui:SetCore("SendNotification", {
                Title = "GPO Fishing Hub",
                Text = "Auto Cast Disabled.",
                Duration = 2,
            })
        end
    end,
})

-- ┌─────────────────────┐
-- │     AUTO REEL       │
-- └─────────────────────┘
-- Detects the fishing mini-game UI (two meters) and automatically
-- holds/releases to keep the fish bar within the blue indicators.
-- This simulates the actual fishing mini-game mechanic in GPO.

local AutoReelToggle = FishingTab:CreateToggle({
    Name = "Auto Reel (Mini-Game)",
    CurrentValue = false,
    Flag = "AutoReelToggle",
    Callback = function(Value)
        _G.AutoReel = Value
        if Value then
            game.StarterGui:SetCore("SendNotification", {
                Title = "GPO Fishing Hub",
                Text = "Auto Reel Enabled! Mini-game will play automatically.",
                Duration = 3,
            })
            spawn(function()
                while _G.AutoReel do
                    pcall(function()
                        local playerGui = player:FindFirstChild("PlayerGui")
                        if not playerGui then return end
                        
                        -- Search through all GUIs for the fishing mini-game elements
                        for _, gui in pairs(playerGui:GetChildren()) do
                            if gui:IsA("ScreenGui") and gui.Enabled then
                                -- Look for the fishing bar / mini-game frame
                                -- GPO fishing UI typically has:
                                --   - A "FishBar" or similar: the bar you control
                                --   - Two indicator lines (the blue zone)
                                --   - A progress bar that fills up
                                
                                local fishingFrame = nil
                                local fishBar = nil
                                local progressBar = nil
                                local topIndicator = nil
                                local bottomIndicator = nil
                                
                                -- Recursively search for fishing UI elements
                                local function searchUI(parent)
                                    for _, child in pairs(parent:GetChildren()) do
                                        if child:IsA("GuiObject") then
                                            local name = child.Name:lower()
                                            
                                            -- Find the fish position bar
                                            if name:find("fish") and (name:find("bar") or name:find("icon") or name:find("indicator")) then
                                                fishBar = child
                                            end
                                            
                                            -- Find progress bar
                                            if name:find("progress") or name:find("fill") or name:find("catch") then
                                                progressBar = child
                                            end
                                            
                                            -- Find the frame/container
                                            if name:find("fishing") and (name:find("frame") or name:find("game") or name:find("minigame")) then
                                                fishingFrame = child
                                            end
                                            
                                            -- Find bar boundaries / zone indicators
                                            if name:find("top") or name:find("upper") then
                                                topIndicator = child
                                            end
                                            if name:find("bottom") or name:find("lower") then
                                                bottomIndicator = child
                                            end
                                            
                                            searchUI(child)
                                        end
                                    end
                                end
                                
                                searchUI(gui)
                                
                                -- If we found fishing UI elements, play the mini-game
                                if fishBar and fishBar.Visible then
                                    -- Strategy: Simulate holding and releasing mouse to keep
                                    -- the fish bar centered in the safe zone
                                    
                                    -- Get the fish bar's Y position (relative in the meter)
                                    local fishPos = fishBar.Position.Y.Scale
                                    
                                    -- Target zone is roughly center (0.3 to 0.7 range)
                                    -- Hold mouse if bar is below center, release if above
                                    local targetCenter = 0.5
                                    
                                    if topIndicator and bottomIndicator then
                                        -- Calculate the midpoint of the safe zone
                                        local topY = topIndicator.Position.Y.Scale
                                        local bottomY = bottomIndicator.Position.Y.Scale
                                        targetCenter = (topY + bottomY) / 2
                                    end
                                    
                                    if fishPos > targetCenter then
                                        -- Bar is too LOW — hold click to raise it
                                        VirtualInputManager:SendMouseButtonEvent(
                                            mouse.X, mouse.Y, 0, true, game, 0
                                        )
                                        wait(0.05)
                                    else
                                        -- Bar is too HIGH — release click to lower it
                                        VirtualInputManager:SendMouseButtonEvent(
                                            mouse.X, mouse.Y, 0, false, game, 0
                                        )
                                        wait(0.05)
                                    end
                                else
                                    -- Alternative: Brute-force method
                                    -- Rapidly tap click to maintain a middle position
                                    -- This works as a fallback when UI elements can't be detected by name
                                    
                                    -- Check if ANY visible frame looks like a fishing UI
                                    local function hasVisibleFishingUI()
                                        for _, g in pairs(playerGui:GetChildren()) do
                                            if g:IsA("ScreenGui") and g.Enabled and g.Name:lower():find("fish") then
                                                return true
                                            end
                                        end
                                        return false
                                    end
                                    
                                    if hasVisibleFishingUI() then
                                        -- Tap rhythm: hold briefly, release briefly
                                        -- This creates an oscillating pattern that generally
                                        -- keeps the bar near the middle
                                        VirtualInputManager:SendMouseButtonEvent(
                                            mouse.X, mouse.Y, 0, true, game, 0
                                        )
                                        wait(0.15)
                                        VirtualInputManager:SendMouseButtonEvent(
                                            mouse.X, mouse.Y, 0, false, game, 0
                                        )
                                        wait(0.1)
                                    end
                                end
                            end
                        end
                    end)
                    
                    wait(0.05)  -- Fast loop for responsive mini-game control
                end
            end)
        else
            game.StarterGui:SetCore("SendNotification", {
                Title = "GPO Fishing Hub",
                Text = "Auto Reel Disabled.",
                Duration = 2,
            })
        end
    end,
})

-- ┌─────────────────────────┐
-- │     AUTO BUY BAIT       │
-- └─────────────────────────┘
-- Monitors your bait count. When it runs low, automatically
-- purchases more from the game's remote.

local AutoBuyBaitToggle = FishingTab:CreateToggle({
    Name = "Auto Buy Bait",
    CurrentValue = false,
    Flag = "AutoBuyBaitToggle",
    Callback = function(Value)
        _G.AutoBuyBait = Value
        if Value then
            game.StarterGui:SetCore("SendNotification", {
                Title = "GPO Fishing Hub",
                Text = "Auto Buy Bait Enabled!",
                Duration = 3,
            })
            spawn(function()
                while _G.AutoBuyBait do
                    pcall(function()
                        local backpack = player:FindFirstChild("Backpack")
                        local character = player.Character
                        
                        -- Count current bait
                        local baitCount = 0
                        local baitName = nil
                        
                        -- Check backpack for bait items
                        if backpack then
                            for _, item in pairs(backpack:GetChildren()) do
                                local name = item.Name:lower()
                                if name:find("bait") or name:find("worm") or name:find("lure") then
                                    baitName = item.Name
                                    -- Check if item has a stack/amount value
                                    local amountVal = item:FindFirstChild("Amount") 
                                        or item:FindFirstChild("Count") 
                                        or item:FindFirstChild("Stack")
                                    if amountVal then
                                        baitCount = baitCount + amountVal.Value
                                    else
                                        baitCount = baitCount + 1
                                    end
                                end
                            end
                        end
                        
                        -- Also check character (equipped items)
                        if character then
                            for _, item in pairs(character:GetChildren()) do
                                local name = item.Name:lower()
                                if name:find("bait") or name:find("worm") or name:find("lure") then
                                    baitName = item.Name
                                    local amountVal = item:FindFirstChild("Amount") 
                                        or item:FindFirstChild("Count") 
                                        or item:FindFirstChild("Stack")
                                    if amountVal then
                                        baitCount = baitCount + amountVal.Value
                                    else
                                        baitCount = baitCount + 1
                                    end
                                end
                            end
                        end
                        
                        -- If bait is low (less than 5), try to buy more
                        if baitCount < 5 then
                            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                            if remotes then
                                -- Try to find a buy/shop remote
                                for _, remote in pairs(remotes:GetChildren()) do
                                    local rName = remote.Name:lower()
                                    if rName:find("buy") or rName:find("shop") or rName:find("purchase") then
                                        if remote:IsA("RemoteEvent") then
                                            -- Try buying bait (common bait)
                                            remote:FireServer("Bait", 50) -- Buy 50 bait
                                            remote:FireServer("Common Bait", 50)
                                        elseif remote:IsA("RemoteFunction") then
                                            remote:InvokeServer("Bait", 50)
                                            remote:InvokeServer("Common Bait", 50)
                                        end
                                    end
                                end
                            end
                            
                            game.StarterGui:SetCore("SendNotification", {
                                Title = "GPO Fishing Hub",
                                Text = "Bait low! Attempted to buy more.",
                                Duration = 2,
                            })
                        end
                    end)
                    
                    wait(10) -- Check every 10 seconds
                end
            end)
        else
            game.StarterGui:SetCore("SendNotification", {
                Title = "GPO Fishing Hub",
                Text = "Auto Buy Bait Disabled.",
                Duration = 2,
            })
        end
    end,
})

local FishingSpeedSlider = FishingTab:CreateSlider({
    Name = "Fishing Speed",
    Range = {1, 10},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "FishingSpeedSlider",
    Callback = function(Value)
        _G.FishingSpeed = Value
        game.StarterGui:SetCore("SendNotification", {
            Title = "GPO Fishing Hub",
            Text = "Cast speed: " .. Value .. "x",
            Duration = 2,
        })
    end,
})

-- ── Auto Store Fruits ────────────────────────
local FruitSection = FishingTab:CreateSection("Auto Store Fruits")

local StoreCommonToggle = FishingTab:CreateToggle({
    Name = "Auto Store Common Fruits",
    CurrentValue = false,
    Flag = "StoreCommonToggle",
    Callback = function(Value)
        _G.StoreCommon = Value
        game.StarterGui:SetCore("SendNotification", {
            Title = "GPO Fishing Hub",
            Text = "Store Common: " .. (Value and "ON" or "OFF"),
            Duration = 2,
        })
    end,
})

local StoreRareToggle = FishingTab:CreateToggle({
    Name = "Auto Store Rare Fruits",
    CurrentValue = false,
    Flag = "StoreRareToggle",
    Callback = function(Value)
        _G.StoreRare = Value
        game.StarterGui:SetCore("SendNotification", {
            Title = "GPO Fishing Hub",
            Text = "Store Rare: " .. (Value and "ON" or "OFF"),
            Duration = 2,
        })
    end,
})

local StoreEpicToggle = FishingTab:CreateToggle({
    Name = "Auto Store Epic Fruits",
    CurrentValue = false,
    Flag = "StoreEpicToggle",
    Callback = function(Value)
        _G.StoreEpic = Value
        game.StarterGui:SetCore("SendNotification", {
            Title = "GPO Fishing Hub",
            Text = "Store Epic: " .. (Value and "ON" or "OFF"),
            Duration = 2,
        })
    end,
})

local StoreLegendaryToggle = FishingTab:CreateToggle({
    Name = "Auto Store Legendary Fruits",
    CurrentValue = false,
    Flag = "StoreLegendaryToggle",
    Callback = function(Value)
        _G.StoreLegendary = Value
        game.StarterGui:SetCore("SendNotification", {
            Title = "GPO Fishing Hub",
            Text = "Store Legendary: " .. (Value and "ON" or "OFF"),
            Duration = 2,
        })
    end,
})

local StoreMythicalToggle = FishingTab:CreateToggle({
    Name = "Auto Store Mythical Fruits",
    CurrentValue = false,
    Flag = "StoreMythicalToggle",
    Callback = function(Value)
        _G.StoreMythical = Value
        game.StarterGui:SetCore("SendNotification", {
            Title = "GPO Fishing Hub",
            Text = "Store Mythical: " .. (Value and "ON" or "OFF"),
            Duration = 2,
        })
    end,
})

local StoreAllButton = FishingTab:CreateButton({
    Name = "✅ Enable All Auto Store",
    Callback = function()
        _G.StoreCommon    = true
        _G.StoreRare      = true
        _G.StoreEpic      = true
        _G.StoreLegendary = true
        _G.StoreMythical  = true
        game.StarterGui:SetCore("SendNotification", {
            Title = "GPO Fishing Hub",
            Text = "All fruit rarities will be auto-stored!",
            Duration = 3,
        })
    end,
})

local DisableAllButton = FishingTab:CreateButton({
    Name = "❌ Disable All Auto Store",
    Callback = function()
        _G.StoreCommon    = false
        _G.StoreRare      = false
        _G.StoreEpic      = false
        _G.StoreLegendary = false
        _G.StoreMythical  = false
        game.StarterGui:SetCore("SendNotification", {
            Title = "GPO Fishing Hub",
            Text = "All auto-store disabled!",
            Duration = 3,
        })
    end,
})

-- ============================================
-- 🍎 AUTO STORE FRUIT LOGIC (Background)
-- ============================================

-- Known GPO Devil Fruits organized by rarity
local fruitsByRarity = {
    Common = {
        "Spin", "Bomb", "Spike", "Smoke", "Spring", "Kilo",
        "Sube", "Bane", "Tori"
    },
    Rare = {
        "Flame", "Ice", "Sand", "Dark", "Diamond", "Doku",
        "Bari", "Suna", "Yami", "Mera", "Hie"
    },
    Epic = {
        "String", "Barrier", "Magma", "Quake", "Rubber", "Goro",
        "Magu", "Gura", "Ito", "Gomu", "Ope"
    },
    Legendary = {
        "Light", "Gravity", "Door", "Paw", "Venom", "Zushi",
        "Pika", "Doa", "Nikyu", "Bomu"
    },
    Mythical = {
        "Dragon", "Leopard", "Buddha", "Phoenix", "Shadow", "Tori Tori",
        "Hito Hito", "Uo Uo"
    },
}

-- Rarity check based on toggle state
local function getRarityFlag(rarity)
    local flags = {
        Common    = function() return _G.StoreCommon end,
        Rare      = function() return _G.StoreRare end,
        Epic      = function() return _G.StoreEpic end,
        Legendary = function() return _G.StoreLegendary end,
        Mythical  = function() return _G.StoreMythical end,
    }
    if flags[rarity] then
        return flags[rarity]()
    end
    return false
end

-- Detect fruit rarity
local function detectFruitRarity(itemName)
    -- Method 1: Match against known fruit names
    for rarity, fruits in pairs(fruitsByRarity) do
        for _, fruitName in pairs(fruits) do
            if itemName:lower():find(fruitName:lower()) then
                return rarity
            end
        end
    end
    
    -- Method 2: Check if item name contains "fruit" (catch-all)
    if itemName:lower():find("fruit") or itemName:lower():find("devil") then
        return "Common" -- Default to common if we can't identify
    end
    
    return nil -- Not a fruit
end

-- Store fruit via remote
local function storeFruit(itemName)
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            -- Try various possible remote names for storing items
            local storeNames = {"StoreFruit", "StorageStore", "Store", "StoreItem", "Storage", "InventoryStore"}
            for _, remoteName in pairs(storeNames) do
                local remote = remotes:FindFirstChild(remoteName)
                if remote then
                    if remote:IsA("RemoteEvent") then
                        remote:FireServer(itemName)
                    elseif remote:IsA("RemoteFunction") then
                        remote:InvokeServer(itemName)
                    end
                    break
                end
            end
        end
        
        game.StarterGui:SetCore("SendNotification", {
            Title = "GPO Fishing Hub",
            Text = "🍎 Auto-Stored: " .. itemName,
            Duration = 3,
        })
    end)
end

-- Monitor backpack for new items (fruits)
local backpack = player:WaitForChild("Backpack")

backpack.ChildAdded:Connect(function(item)
    wait(1) -- Let item data load

    pcall(function()
        local rarity = nil

        -- Priority 1: Check item attributes
        if item:GetAttribute("Rarity") then
            rarity = item:GetAttribute("Rarity")
        end

        -- Priority 2: Check for a Rarity child value
        if not rarity then
            local rarityChild = item:FindFirstChild("Rarity")
            if rarityChild and rarityChild:IsA("StringValue") then
                rarity = rarityChild.Value
            end
        end

        -- Priority 3: Match item name against known fruits
        if not rarity then
            rarity = detectFruitRarity(item.Name)
        end

        -- Auto store if rarity matches an enabled toggle
        if rarity and getRarityFlag(rarity) then
            wait(0.5)
            storeFruit(item.Name)
        end
    end)
end)

-- Also monitor character for tools added directly
player.CharacterAdded:Connect(function(character)
    character.ChildAdded:Connect(function(item)
        if item:IsA("Tool") then
            wait(1)
            pcall(function()
                local rarity = detectFruitRarity(item.Name)
                if rarity and getRarityFlag(rarity) then
                    storeFruit(item.Name)
                end
            end)
        end
    end)
end)

-- ============================================
-- ⚙️ SETTINGS TAB
-- ============================================
local SettingsTab = Window:CreateTab("Settings", 4483362458)
local SettingsSection = SettingsTab:CreateSection("Configuration")

local AntiAFKToggle = SettingsTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = true,
    Flag = "AntiAFKToggle",
    Callback = function(Value)
        if Value then
            player.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            game.StarterGui:SetCore("SendNotification", {
                Title = "GPO Fishing Hub",
                Text = "Anti AFK Enabled!",
                Duration = 3,
            })
        end
    end,
})

local DestroyUIButton = SettingsTab:CreateButton({
    Name = "🗑️ Destroy GUI",
    Callback = function()
        _G.AutoFish = false
        _G.AutoReel = false
        _G.AutoBuyBait = false
        Rayfield:Destroy()
    end,
})

-- ============================================
-- ✅ LOADED
-- ============================================
game.StarterGui:SetCore("SendNotification", {
    Title = "GPO Fishing Hub",
    Text = "Script loaded! Open the menu to configure.",
    Duration = 5,
})
