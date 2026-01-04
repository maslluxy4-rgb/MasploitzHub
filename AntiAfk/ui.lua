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
m.Position = UDim2.new(1, -45, 0, 10)
m.Size = UDim2.new(0, 35, 0, 35)
m.Font = Enum.Font.SourceSansBold
m.Text = "_"
m.TextColor3 = Color3.new(1, 1, 1)
m.TextSize = 22

local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(0, 8)
mc.Parent = m

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

-- Export update function for backend
getgenv().MasploitzUI = {
    updateStatus = upd,
    showSavedPos = function()
        sp.Text = "✓ AFK Pos Auto-Saved!"
        sp.BackgroundColor3 = Color3.fromRGB(0, 180, 70)
        wait(3)
        sp.Text = "Save Pos as AFK Pos"
        sp.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
    end
}

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
