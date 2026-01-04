-- Masploitz Anti-AFK UI
-- Clean interface for controlling anti-AFK features

local cfg = getgenv().MasploitzConfig
local state = getgenv().MasploitzState
local funcs = getgenv().MasploitzFunctions

-- GUI
local g = Instance.new("ScreenGui")
g.Name = "MasploitzAFK"
g.Parent = game.CoreGui
g.ResetOnSpawn = false

local f = Instance.new("Frame")
f.Parent = g
f.BackgroundColor3 = cfg.UI_BG_COLOR
f.BorderSizePixel = 0
f.Position = cfg.UI_POSITION
f.Size = cfg.UI_SIZE
f.Active = true
f.Draggable = true

local fc = Instance.new("UICorner")
fc.CornerRadius = UDim.new(0, 15)
fc.Parent = f

local fs = Instance.new("UIStroke")
fs.Color = cfg.UI_ACCENT_COLOR
fs.Thickness = 3
fs.Parent = f

-- Header
local h = Instance.new("Frame")
h.Parent = f
h.BackgroundColor3 = cfg.UI_HEADER_COLOR
h.BorderSizePixel = 0
h.Size = UDim2.new(1, 0, 0, 55)

local hc = Instance.new("UICorner")
hc.CornerRadius = UDim.new(0, 15)
hc.Parent = h

local hs = Instance.new("UIStroke")
hs.Color = Color3.fromRGB(60, 120, 170)
hs.Thickness = 2
hs.Parent = h

local t = Instance.new("TextLabel")
t.Parent = h
t.BackgroundTransparency = 1
t.Position = UDim2.new(0, 15, 0, 0)
t.Size = UDim2.new(0, 300, 1, 0)
t.Font = Enum.Font.SourceSansBold
t.Text = "⚡ MASPLOITZ ANTI-AFK"
t.TextColor3 = Color3.new(1, 1, 1)
t.TextSize = 24
t.TextXAlignment = Enum.TextXAlignment.Left

local ts = Instance.new("UIStroke")
ts.Color = Color3.fromRGB(0, 0, 0)
ts.Thickness = 2
ts.Parent = t

-- Minimize
local m = Instance.new("TextButton")
m.Parent = h
m.BackgroundColor3 = Color3.fromRGB(30, 60, 85)
m.BorderSizePixel = 0
m.Position = UDim2.new(1, -85, 0, 10)
m.Size = UDim2.new(0, 35, 0, 35)
m.Font = Enum.Font.SourceSansBold
m.Text = "_"
m.TextColor3 = Color3.new(1, 1, 1)
m.TextSize = 22

local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(0, 8)
mc.Parent = m

-- Close Button (X)
local x = Instance.new("TextButton")
x.Parent = h
x.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
x.BorderSizePixel = 0
x.Position = UDim2.new(1, -45, 0, 10)
x.Size = UDim2.new(0, 35, 0, 35)
x.Font = Enum.Font.SourceSansBold
x.Text = "X"
x.TextColor3 = Color3.new(1, 1, 1)
x.TextSize = 20

local xc = Instance.new("UICorner")
xc.CornerRadius = UDim.new(0, 8)
xc.Parent = x

-- Settings Button
local settingsBtn = Instance.new("TextButton")
settingsBtn.Parent = h
settingsBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 85)
settingsBtn.BorderSizePixel = 0
settingsBtn.Position = UDim2.new(1, -125, 0, 10)
settingsBtn.Size = UDim2.new(0, 35, 0, 35)
settingsBtn.Font = Enum.Font.SourceSansBold
settingsBtn.Text = "⚙"
settingsBtn.TextColor3 = Color3.new(1, 1, 1)
settingsBtn.TextSize = 20

local settingsc = Instance.new("UICorner")
settingsc.CornerRadius = UDim.new(0, 8)
settingsc.Parent = settingsBtn

-- Status
local s = Instance.new("TextLabel")
s.Parent = f
s.BackgroundColor3 = Color3.fromRGB(20, 50, 70)
s.BorderSizePixel = 0
s.Position = UDim2.new(0, 15, 0, 70)
s.Size = UDim2.new(1, -30, 0, 40)
s.Font = Enum.Font.SourceSansBold
s.Text = "● Active"
s.TextColor3 = Color3.fromRGB(0, 255, 100)
s.TextSize = 18

local sc = Instance.new("UICorner")
sc.CornerRadius = UDim.new(0, 10)
sc.Parent = s

local ss = Instance.new("UIStroke")
ss.Color = Color3.fromRGB(0, 0, 0)
ss.Thickness = 2
ss.Parent = s

-- Save Position Button
local sp = Instance.new("TextButton")
sp.Parent = f
sp.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
sp.BorderSizePixel = 0
sp.Position = UDim2.new(0, 15, 0, 125)
sp.Size = UDim2.new(1, -30, 0, 40)
sp.Font = Enum.Font.SourceSansBold
sp.Text = "Save Pos as AFK Pos"
sp.TextColor3 = Color3.new(1, 1, 1)
sp.TextSize = 16

local spc = Instance.new("UICorner")
spc.CornerRadius = UDim.new(0, 10)
spc.Parent = sp

local sps = Instance.new("UIStroke")
sps.Color = Color3.fromRGB(0, 0, 0)
sps.Thickness = 2
sps.Parent = sp

-- Toggle
local b = Instance.new("TextButton")
b.Parent = f
b.BackgroundColor3 = Color3.fromRGB(0, 180, 70)
b.BorderSizePixel = 0
b.Position = UDim2.new(0, 15, 0, 180)
b.Size = UDim2.new(1, -30, 0, 40)
b.Font = Enum.Font.SourceSansBold
b.Text = "ANTI-AFK: ON"
b.TextColor3 = Color3.new(1, 1, 1)
b.TextSize = 16

local bc = Instance.new("UICorner")
bc.CornerRadius = UDim.new(0, 10)
bc.Parent = b

local bs = Instance.new("UIStroke")
bs.Color = Color3.fromRGB(0, 0, 0)
bs.Thickness = 2
bs.Parent = b

-- Server Hop Button
local sh = Instance.new("TextButton")
sh.Parent = f
sh.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
sh.BorderSizePixel = 0
sh.Position = UDim2.new(0, 15, 0, 235)
sh.Size = UDim2.new(1, -30, 0, 40)
sh.Font = Enum.Font.SourceSansBold
sh.Text = "Test Server Hop"
sh.TextColor3 = Color3.new(1, 1, 1)
sh.TextSize = 16

local shc = Instance.new("UICorner")
shc.CornerRadius = UDim.new(0, 10)
shc.Parent = sh

local shs = Instance.new("UIStroke")
shs.Color = Color3.fromRGB(0, 0, 0)
shs.Thickness = 2
shs.Parent = sh

-- Footer
local ft = Instance.new("TextLabel")
ft.Parent = f
ft.BackgroundTransparency = 1
ft.Position = UDim2.new(0, 0, 1, -30)
ft.Size = UDim2.new(1, 0, 0, 30)
ft.Font = Enum.Font.SourceSansBold
ft.Text = "Made by Masploitz | Auto-hop: 19min"
ft.TextColor3 = Color3.fromRGB(120, 160, 190)
ft.TextSize = 13

-- Settings Panel Container (uses ClipsDescendants)
local settingsContainer = Instance.new("Frame")
settingsContainer.Parent = f
settingsContainer.BackgroundTransparency = 1
settingsContainer.Position = UDim2.new(1, 0, 0, 55) -- Start offscreen to the right
settingsContainer.Size = UDim2.new(0, 400, 1, -55)
settingsContainer.ClipsDescendants = true
settingsContainer.ZIndex = 10

local settingsPanel = Instance.new("Frame")
settingsPanel.Parent = settingsContainer
settingsPanel.BackgroundColor3 = Color3.fromRGB(20, 50, 70)
settingsPanel.BorderSizePixel = 0
settingsPanel.Position = UDim2.new(1, 0, 0, 0) -- Start offscreen
settingsPanel.Size = UDim2.new(1, 0, 1, 0)

local settingsPanelCorner = Instance.new("UICorner")
settingsPanelCorner.CornerRadius = UDim.new(0, 12)
settingsPanelCorner.Parent = settingsPanel

local settingsPanelStroke = Instance.new("UIStroke")
settingsPanelStroke.Color = cfg.UI_ACCENT_COLOR
settingsPanelStroke.Thickness = 2
settingsPanelStroke.Parent = settingsPanel

-- Settings Header
local settingsHeader = Instance.new("TextLabel")
settingsHeader.Parent = settingsPanel
settingsHeader.BackgroundTransparency = 1
settingsHeader.Position = UDim2.new(0, 15, 0, 10)
settingsHeader.Size = UDim2.new(1, -30, 0, 30)
settingsHeader.Font = Enum.Font.SourceSansBold
settingsHeader.Text = "⚙ SETTINGS"
settingsHeader.TextColor3 = Color3.new(1, 1, 1)
settingsHeader.TextSize = 20
settingsHeader.TextXAlignment = Enum.TextXAlignment.Left

-- Scrolling Frame for Settings
local settingsScroll = Instance.new("ScrollingFrame")
settingsScroll.Parent = settingsPanel
settingsScroll.BackgroundColor3 = Color3.fromRGB(15, 40, 60)
settingsScroll.BorderSizePixel = 0
settingsScroll.Position = UDim2.new(0, 10, 0, 50)
settingsScroll.Size = UDim2.new(1, -20, 1, -60)
settingsScroll.CanvasSize = UDim2.new(0, 0, 0, 600)
settingsScroll.ScrollBarThickness = 6

local settingsScrollCorner = Instance.new("UICorner")
settingsScrollCorner.CornerRadius = UDim.new(0, 8)
settingsScrollCorner.Parent = settingsScroll

local settingsList = Instance.new("UIListLayout")
settingsList.Parent = settingsScroll
settingsList.Padding = UDim.new(0, 10)
settingsList.SortOrder = Enum.SortOrder.LayoutOrder

-- Helper function to create setting items
local function createSetting(name, configKey, settingType, min, max)
    local settingFrame = Instance.new("Frame")
    settingFrame.Parent = settingsScroll
    settingFrame.BackgroundColor3 = Color3.fromRGB(25, 55, 75)
    settingFrame.BorderSizePixel = 0
    settingFrame.Size = UDim2.new(1, -10, 0, 50)
    
    local settingCorner = Instance.new("UICorner")
    settingCorner.CornerRadius = UDim.new(0, 6)
    settingCorner.Parent = settingFrame
    
    local settingLabel = Instance.new("TextLabel")
    settingLabel.Parent = settingFrame
    settingLabel.BackgroundTransparency = 1
    settingLabel.Position = UDim2.new(0, 10, 0, 0)
    settingLabel.Size = UDim2.new(0.6, 0, 1, 0)
    settingLabel.Font = Enum.Font.Gotham
    settingLabel.Text = name
    settingLabel.TextColor3 = Color3.new(1, 1, 1)
    settingLabel.TextSize = 14
    settingLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    if settingType == "toggle" then
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Parent = settingFrame
        toggleBtn.BackgroundColor3 = cfg[configKey] and Color3.fromRGB(0, 180, 70) or Color3.fromRGB(180, 50, 50)
        toggleBtn.BorderSizePixel = 0
        toggleBtn.Position = UDim2.new(1, -70, 0.5, -15)
        toggleBtn.Size = UDim2.new(0, 60, 0, 30)
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.Text = cfg[configKey] and "ON" or "OFF"
        toggleBtn.TextColor3 = Color3.new(1, 1, 1)
        toggleBtn.TextSize = 12
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 6)
        toggleCorner.Parent = toggleBtn
        
        toggleBtn.MouseButton1Click:Connect(function()
            cfg[configKey] = not cfg[configKey]
            toggleBtn.Text = cfg[configKey] and "ON" or "OFF"
            toggleBtn.BackgroundColor3 = cfg[configKey] and Color3.fromRGB(0, 180, 70) or Color3.fromRGB(180, 50, 50)
        end)
        
    elseif settingType == "number" then
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Parent = settingFrame
        valueLabel.BackgroundColor3 = Color3.fromRGB(35, 65, 85)
        valueLabel.BorderSizePixel = 0
        valueLabel.Position = UDim2.new(1, -70, 0.5, -15)
        valueLabel.Size = UDim2.new(0, 60, 0, 30)
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.Text = tostring(cfg[configKey])
        valueLabel.TextColor3 = Color3.new(1, 1, 1)
        valueLabel.TextSize = 14
        
        local valueCorner = Instance.new("UICorner")
        valueCorner.CornerRadius = UDim.new(0, 6)
        valueCorner.Parent = valueLabel
    end
    
    return settingFrame
end

-- Create Settings
createSetting("Force Animation", "FORCE_ANIMATION", "toggle")
createSetting("Auto Re-Equip Tool", "AUTO_RE_EQUIP", "toggle")
createSetting("Enable Chat Messages", "ENABLE_CHAT_MESSAGES", "toggle")
createSetting("Enable Emotes", "ENABLE_EMOTES", "toggle")
createSetting("Enable Camera Move", "ENABLE_CAMERA_MOVE", "toggle")
createSetting("Debug Mode", "DEBUG_MODE", "toggle")
createSetting("Walk Speed Normal", "WALK_SPEED_NORMAL", "number", 10, 30)
createSetting("Walk Speed Fast", "WALK_SPEED_FAST", "number", 20, 40)
createSetting("Max Walk Distance", "MAX_WALK_DISTANCE", "number", 1, 10)
createSetting("Min Safe Distance", "MIN_SAFE_DISTANCE", "number", 3, 10)
createSetting("Min Players (Server)", "MIN_PLAYERS", "number", 10, 30)
createSetting("Re-Equip Interval (s)", "RE_EQUIP_INTERVAL", "number", 30, 300)

-- Restore
local r = Instance.new("TextButton")
r.Parent = g
r.BackgroundColor3 = cfg.UI_BG_COLOR
r.BorderSizePixel = 0
r.Position = UDim2.new(0.5, -80, 0, 15)
r.Size = UDim2.new(0, 160, 0, 40)
r.Font = Enum.Font.SourceSansBold
r.Text = "Show UI"
r.TextColor3 = Color3.new(1, 1, 1)
r.TextSize = 18
r.Visible = false

local rcc = Instance.new("UICorner")
rcc.CornerRadius = UDim.new(0, 10)
rcc.Parent = r

local rss = Instance.new("UIStroke")
rss.Color = cfg.UI_ACCENT_COLOR
rss.Thickness = 2
rss.Parent = r

-- Update status function
local function upd(txt, col)
    s.Text = "● " .. txt
    s.TextColor3 = col
end

local settingsOpen = false

-- Export update function for backend
getgenv().MasploitzUI = {
    updateStatus = upd,
    showSavedPos = function()
        sp.Text = "✓ AFK Pos Auto-Saved!"
        sp.BackgroundColor3 = Color3.fromRGB(0, 180, 70)
        wait(3)
        sp.Text = "Save Pos as AFK Pos"
        sp.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
    end,
    destroy = function()
        g:Destroy()
    end
}

-- Close Button (Destroy Everything)
x.MouseButton1Click:Connect(function()
    -- Stop all anti-AFK systems
    if getgenv().MasploitzState then
        getgenv().MasploitzState.enabled = false
    end
    
    -- Destroy UI
    g:Destroy()
    
    -- Clear globals
    getgenv().MasploitzConfig = nil
    getgenv().MasploitzState = nil
    getgenv().MasploitzFunctions = nil
    getgenv().MasploitzUI = nil
    
    print("🔥 Masploitz Anti-AFK completely unloaded")
end)

-- Settings Toggle
settingsBtn.MouseButton1Click:Connect(function()
    settingsOpen = not settingsOpen
    
    local targetPos = settingsOpen and UDim2.new(0, 0, 0, 0) or UDim2.new(1, 0, 0, 0)
    local tween = game:GetService("TweenService"):Create(
        settingsPanel,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = targetPos}
    )
    tween:Play()
end)

-- Save Position
sp.MouseButton1Click:Connect(function()
    if funcs.savePosition() then
        sp.Text = "✓ AFK Pos Saved!"
        sp.BackgroundColor3 = Color3.fromRGB(0, 180, 70)
        wait(2)
        sp.Text = "Save Pos as AFK Pos"
        sp.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
    end
end)

-- Toggle
b.MouseButton1Click:Connect(function()
    local enabled = funcs.toggleEnabled()
    if enabled then
        b.Text = "ANTI-AFK: ON"
        b.BackgroundColor3 = Color3.fromRGB(0, 180, 70)
        upd("Active", Color3.fromRGB(0, 255, 100))
    else
        b.Text = "ANTI-AFK: OFF"
        b.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        upd("Disabled", Color3.fromRGB(180, 50, 50))
    end
end)

-- Server Hop
sh.MouseButton1Click:Connect(function()
    sh.Text = "Hopping..."
    sh.BackgroundColor3 = Color3.fromRGB(150, 80, 30)
    upd("Server hopping...", Color3.fromRGB(255, 150, 50))
    wait(1)
    funcs.serverHop()
end)

-- Minimize/Restore
m.MouseButton1Click:Connect(function()
    f.Visible = false
    r.Visible = true
end)

r.MouseButton1Click:Connect(function()
    f.Visible = true
    r.Visible = false
end)

print("✅ Masploitz UI initialized")
