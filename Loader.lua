--lyxme Hub 
repeat wait() until game:IsLoaded()
repeat wait() until game.Players.LocalPlayer.Character
repeat wait() until game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
repeat wait() until game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
-- Reset all values
    selectedPlayer = ""
    currentPlayerList = {}
    Options = {}
    autoShake = true
    if shakeConnection then
        shakeConnection:Disconnect()
    end
    autoShakeDelay = 0
    autoReel = true
    autoReelDelay = 0
    getgenv().giftloop = false
    getgenv().autoconfirm = false
end

-- Core Services
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGUI = Player:WaitForChild("PlayerGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local selectedPlayer = ""
local currentPlayerList = {}
local Options = {}
local autoShake = true
local shakeConnection = nil
local autoShakeDelay = 0
local autoReel = true
local autoReelDelay = 0
local SpectatePlys = false
local SelectPly = false

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "[🤿]Fisch | lyxme Hub",
    SubTitle = "",
    TabWidth = 160,
    Size = UDim2.fromOffset(510, 390),
    Acrylic = false, -- The blur may be detectable, setting this to false disables blur entirely
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
})

--Fluent provides Lucide Icons https://lucide.dev/icons/ for the tabs, icons are optional
local Tabs = {
    Genaral = Window:AddTab({ Title = "General", Icon = "rbxassetid://11433532654" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

do
    Fluent:Notify({
        Title = "Notification",
        Content = "lyxme Hub running script",
        SubContent = "", -- Optional
        Duration = 10 -- Set to nil to make the notification not disappear
    })

end

local Toggle = Tabs.Genaral:AddToggle("MyToggle", {Title = "Auto Shake", Default = false })

Toggle:OnChanged(function(Value)
        autoShake = Value
        
        if Value then
            PlayerGUI.ChildAdded:Connect(function(GUI)
                if GUI:IsA("ScreenGui") and GUI.Name == "shakeui" then
                    local safezone = GUI:WaitForChild("safezone", 5)
                    if safezone then
                        safezone.ChildAdded:Connect(function(child)
                            if child:IsA("ImageButton") and child.Name == "button" then
                                task.spawn(function()
                                    if autoShake then
                                        handleButtonClick(child)
                                    end
                                end)
                            end
                        end)
                    end
                end
            end)
        end
    end
end)

Options.MyToggle:SetValue(false)

local Toggle = Tabs.Genaral:AddToggle("MyToggle", {Title = "Auto reel", Default = true })

    Toggle:OnChanged(function(Value)
        autoReel = Value
        
        if Value then
            PlayerGUI.ChildAdded:Connect(function(GUI)
                if GUI:IsA("ScreenGui") and GUI.Name == "reel" then
                    if autoReel then
                        local reelEvent = ReplicatedStorage:WaitForChild("events"):WaitForChild("reelfinished")
                        if reelEvent then
                            repeat
                                task.wait(autoReelDelay)
                                reelEvent:FireServer(100, false)
                            until GUI == nil or not autoReel
                        end
                    end
                end
            end)
        end
    end)
    Options.MyToggle:SetValue(false)


local Toggle = Tabs.Genaral:AddToggle("MyToggle", {Title = "Auto Sell", Default = false })

Toggle:OnChanged(function(Value)
_G.sell = Value
if _G.sell then
     while _G.sell do wait()
          workspace.world.npcs:FindFirstChild("Marc Merchant").merchant.sellall:InvokeServer()
   end
end
end)

Options.MyToggle:SetValue(false)

Tabs.Genaral:AddButton({
    Title = "Redeem All Code",
    Description = "",
    Callback = function()
        local args = {                
                [1] = "SorryForDowntime"
            }
            
            game:GetService("ReplicatedStorage").events.runcode:FireServer(unpack(args))

        local args = {
                [1] = "Scubaaaa"
            }
            
            game:GetService("ReplicatedStorage").events.runcode:FireServer(unpack(args))

        local args = {
                [1] = "FischFright2024"
            }

            game:GetService("ReplicatedStorage").events.runcode:FireServer(unpack(args))
    end
})

-- Functions
local function UpdatePlayerList()
    local newPlayerList = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player then
            table.insert(newPlayerList, player.Name)
        end
    end
    currentPlayerList = newPlayerList
    if Options.PlayerSelect then
        Options.PlayerSelect:SetValues(newPlayerList)
    end
end

local function TradeEquipped()
    if selectedPlayer == "" then
        Fluent:Notify({
            Title = "Refresh Player",
            Content = "Select a player first!",
            Duration = 3
        })
        return
    end

    local targetPlayer = Players:FindFirstChild(selectedPlayer)
    if targetPlayer then
        local equippedTool = Player.Character:FindFirstChildWhichIsA("Tool")
        if equippedTool and equippedTool:FindFirstChild("offer") then
            equippedTool.offer:FireServer(targetPlayer)
        else
            Fluent:Notify({
                Title = "Equip Item",
                Content = "Hold an Item first!",
                Duration = 3
            })
        end
    end
end

local function GiftAll()
    if selectedPlayer == "" then
        Fluent:Notify({
            Title = "Error",
            Content = "Select a player first!",
            Duration = 3
        })
        getgenv().giftloop = false
        return
    end

    local targetPlayer = Players:FindFirstChild(selectedPlayer)
    if targetPlayer then
        while getgenv().giftloop do
            for _, item in pairs(Player.Backpack:GetChildren()) do
                if not getgenv().giftloop then break end
                if item:FindFirstChild("offer") then
                    Player.PlayerGui.hud.safezone.backpack.events.equip:FireServer(item)
                    wait(0.1)
                    item.offer:FireServer(targetPlayer)
                    wait(0.2)
                end
            end
            wait(0.5)
        end
    end
end

local function startAutoConfirm()
    PlayerGUI.hud.safezone.bodyannouncements.ChildAdded:Connect(function(child)
        if getgenv().autoconfirm and child:IsA("Frame") and child.Name == "offer" then
            local confirmButton = child:FindFirstChild("confirm")
            local shouldStop = false
            
            child.AncestryChanged:Connect(function(_, parent)
                if not parent then shouldStop = true end
            end)
            
            if confirmButton then
                confirmButton.AncestryChanged:Connect(function(_, parent)
                    if not parent then shouldStop = true end
                end)
                
                while not shouldStop and getgenv().autoconfirm do
                    if confirmButton.Visible then
                        local pos = confirmButton.AbsolutePosition
                        local size = confirmButton.AbsoluteSize
                        local x = pos.X + size.X / 2
                        local y = pos.Y + size.Y / 2 + 58
                        
                        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, Player, 0)
                        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, Player, 0)
                    end
                    task.wait(0.01)
                end
            end
        end
    end)
end

-- Gifting Tab Elements
Options.PlayerSelect = Tabs.Gifting:AddDropdown("PlayerSelect", {
    Title = "Select Player",
    Values = {},
    Multi = false,
    Default = "",
    Callback = function(Value)
        selectedPlayer = Value
    end
})

Tabs.Gifting:AddButton({
    Title = "Refresh Player List",
    Callback = UpdatePlayerList
})

Tabs.Gifting:AddToggle("AutoGift", {
    Title = "Auto Gift All Items",
    Default = false,
    Callback = function(Value)
        getgenv().giftloop = Value
        if Value then
            spawn(GiftAll)
        end
    end
})

Tabs.Gifting:AddButton({
    Title = "Gift Equipped Fish",
    Callback = TradeEquipped
})

Tabs.Gifting:AddToggle("AutoConfirm", {
    Title = "Auto Confirm Gifts",
    Default = false,
    Callback = function(Value)
        getgenv().autoconfirm = Value
        if Value then
            startAutoConfirm()
        end
    end
})

-- Player Events
Players.PlayerAdded:Connect(function(player)
    if player ~= Player then
        table.insert(currentPlayerList, player.Name)
        Options.PlayerSelect:SetValues(currentPlayerList)
        Fluent:Notify({
            Title = "Player Joined",
            Content = player.Name .. " joined!",
            Duration = 3
        })
    end
end)

Players.PlayerRemoving:Connect(function(player)
    for i, name in ipairs(currentPlayerList) do
        if name == player.Name then
            table.remove(currentPlayerList, i)
            Options.PlayerSelect:SetValues(currentPlayerList)
            Fluent:Notify({
                Title = "Player Left",
                Content = player.Name .. " left!",
                Duration = 3
            })
            break
        end
    end
end)

-- Initial Setup
UpdatePlayerList()

    Tabs.Settings:AddButton({
        Title = "rejoin server",
        Description = "",
        Callback = function()
            local ts = game:GetService("TeleportService")
    
            local p = game:GetService("Players").LocalPlayer
            
             
            
            ts:Teleport(game.PlaceId, p)
        end
    })
    
    Tabs.Settings:AddButton({
        Title = "Hop Server",
        Description = "",
        Callback = function()
            local Http = game:GetService("HttpService")
            local TPS = game:GetService("TeleportService")
            local Api = "https://games.roblox.com/v1/games/"
            
            local _place = game.PlaceId
            local _servers = Api.._place.."/servers/Public?sortOrder=Asc&limit=100"
            function ListServers(cursor)
               local Raw = game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or ""))
               return Http:JSONDecode(Raw)
            end
            
            local Server, Next; repeat
               local Servers = ListServers(Next)
               Server = Servers.data[1]
               Next = Servers.nextPageCursor
            until Server
            
            TPS:TeleportToPlaceInstance(_place,Server.id,game.Players.LocalPlayer)
        end
    })
    
    
    
    

-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- InterfaceManager (Allows you to have a interface managment system)

-- Hand the library over to our managers
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- You can add indexes of elements the save manager should ignore
SaveManager:SetIgnoreIndexes({})

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Notification",
    Content = "The script has been loading",
    Duration = 5
})

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()


--uitoggle

do
    local ToggleUI = game.CoreGui:FindFirstChild("MyToggle") 
    if ToggleUI then 
    ToggleUI:Destroy()
    end
end

local MyToggle = Instance.new("ScreenGui")
local ImageButton = Instance.new("ImageButton")
local UICorner = Instance.new("UICorner")

--Properties:

MyToggle.Name = "MyToggle"
MyToggle.Parent = game.CoreGui
MyToggle.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

ImageButton.Parent = MyToggle
ImageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImageButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
ImageButton.BorderSizePixel = 0
ImageButton.Position = UDim2.new(0.156000003, 0, -0, 0)
ImageButton.Size = UDim2.new(0, 50, 0, 50)
ImageButton.Image = "rbxassetid://16731758728"
ImageButton.MouseButton1Click:Connect(function()
game.CoreGui:FindFirstChild("ScreenGui").Enabled = not game.CoreGui:FindFirstChild("ScreenGui").Enabled
end)


UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = ImageButton
