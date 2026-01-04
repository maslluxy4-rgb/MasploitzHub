-- Masploitz Anti-AFK UI - Enhanced Edition
-- Clean interface with smooth animations and better UX

local cfg = getgenv().MasploitzConfig
local state = getgenv().MasploitzState
local funcs = getgenv().MasploitzFunctions
local TweenService = game:GetService("TweenService")

-- Tween configs
local tweenInfo = {
    fast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    medium = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    slow = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    bounce = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
}

-- Helper function for smooth tweens
local function tween(obj, props, info)
    local tw = TweenService:Create(obj, info or tweenInfo.fast, props)
    tw:Play()
    return tw
end

-- Helper for button hover effects
local function addHoverEffect(btn, normalColor, hoverColor, scaleAmount)
    scaleAmount = scaleAmount or 1.05
    
    btn.MouseEnter:Connect(function()
        tween(btn, {BackgroundColor3 = hoverColor or normalColor, Size = btn.Size * scaleAmount}, tweenInfo.fast)
    end)
    
    btn.MouseLeave:Connect(function()
        tween(btn, {BackgroundColor3 = normalColor, Size = btn.Size / scaleAmount}, tweenInfo.fast)
    end)
end

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
f.BackgroundTransparency = 1 -- Start invisible for fade-in

local fc = Instance.new("UICorner")
fc.CornerRadius = UDim.new(0, 15)
fc.Parent = f

local fs = Instance.new("UIStroke")
fs.Color = cfg.UI_ACCENT_COLOR
fs.Thickness = 3
fs.Transparency = 1 -- Start invisible
fs.Parent = f

-- Header
local h = Instance.new("Frame")
h.Parent = f
h.BackgroundColor3 = cfg.UI_HEADER_COLOR
h.BorderSizePixel = 0
h.Size = UDim2.new(1, 0, 0, 55)
h.BackgroundTransparency = 1

local hc = Instance.new("UICorner")
hc.CornerRadius = UDim.new(0, 15)
hc.Parent = h

local hs = Instance.new("UIStroke")
hs.Color = Color3.fromRGB(60, 120, 170)
hs.Thickness = 2
hs.Transparency = 1
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
t.TextTransparency = 1

local ts = Instance.new("UIStroke")
ts.Color = Color3.fromRGB(0, 0, 0)
ts.Thickness = 2
ts.Transparency = 1
ts.Parent = t

-- Minimize Button
local m = Instance.new("TextButton")
m.Parent = h
m.BackgroundColor3 = Color3.fromRGB(30, 60, 85)
m.BorderSizePixel = 0
m.Position = UDim2.new(1, -90, 0, 10)
m.Size = UDim2.new(0, 35, 0, 35)
m.Font = Enum.Font.SourceSansBold
m.Text = "_"
m.TextColor3 = Color3.new(1, 1, 1)
m.TextSize = 22
m.BackgroundTransparency = 1
m.TextTransparency = 1

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
x.Text = "×"
x.TextColor3 = Color3.new(1, 1, 1)
x.TextSize = 26
x.BackgroundTransparency = 1
x.TextTransparency = 1

local xc = Instance.new("UICorner")
xc.CornerRadius = UDim.new(0, 8)
xc.Parent = x

local xs = Instance.new("UIStroke")
xs.Color = Color3.fromRGB(0, 0, 0)
xs.Thickness = 2
xs.Transparency = 1
xs.Parent = x

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
s.BackgroundTransparency = 1
s.TextTransparency = 1

local sc = Instance.new("UICorner")
sc.CornerRadius = UDim.new(0, 10)
sc.Parent = s

local ss = Instance.new("UIStroke")
ss.Color = Color3.fromRGB(0, 0, 0)
ss.Thickness = 2
ss.Transparency = 1
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
sp.BackgroundTransparency = 1
sp.TextTransparency = 1

local spc = Instance.new("UICorner")
spc.CornerRadius = UDim.new(0, 10)
spc.Parent = sp

local sps = Instance.new("UIStroke")
sps.Color = Color3.fromRGB(0, 0, 0)
sps.Thickness = 2
sps.Transparency = 1
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
b.BackgroundTransparency = 1
b.TextTransparency = 1

local bc = Instance.new("UICorner")
bc.CornerRadius = UDim.new(0, 10)
bc.Parent = b

local bs = Instance.new("UIStroke")
bs.Color = Color3.fromRGB(0, 0, 0)
bs.Thickness = 2
bs.Transparency = 1
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
sh.BackgroundTransparency = 1
sh.TextTransparency = 1

local shc = Instance.new("UICorner")
shc.CornerRadius = UDim.new(0, 10)
shc.Parent = sh

local shs = Instance.new("UIStroke")
shs.Color = Color3.fromRGB(0, 0, 0)
shs.Thickness = 2
shs.Transparency = 1
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
ft.TextTransparency = 1

-- Restore Button
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

-- Fade in animation on load
task.spawn(function()
    wait(0.1)
    tween(f, {BackgroundTransparency = 0}, tweenInfo.slow)
    tween(fs, {Transparency = 0}, tweenInfo.slow)
    tween(h, {BackgroundTransparency = 0}, tweenInfo.slow)
    tween(hs, {Transparency = 0}, tweenInfo.slow)
    tween(t, {TextTransparency = 0}, tweenInfo.slow)
    tween(ts, {Transparency = 0}, tweenInfo.slow)
    tween(m, {BackgroundTransparency = 0, TextTransparency = 0}, tweenInfo.slow)
    tween(x, {BackgroundTransparency = 0, TextTransparency = 0}, tweenInfo.slow)
    tween(xs, {Transparency = 0}, tweenInfo.slow)
    tween(s, {BackgroundTransparency = 0, TextTransparency = 0}, tweenInfo.slow)
    tween(ss, {Transparency = 0}, tweenInfo.slow)
    tween(sp, {BackgroundTransparency = 0, TextTransparency = 0}, tweenInfo.slow)
    tween(sps, {Transparency = 0}, tweenInfo.slow)
    tween(b, {BackgroundTransparency = 0, TextTransparency = 0}, tweenInfo.slow)
    tween(bs, {Transparency = 0}, tweenInfo.slow)
    tween(sh, {BackgroundTransparency = 0, TextTransparency = 0}, tweenInfo.slow)
    tween(shs, {Transparency = 0}, tweenInfo.slow)
    tween(ft, {TextTransparency = 0}, tweenInfo.slow)
end)

-- Add hover effects to all buttons
addHoverEffect(m, Color3.fromRGB(30, 60, 85), Color3.fromRGB(40, 75, 105), 1.08)
addHoverEffect(x, Color3.fromRGB(180, 50, 50), Color3.fromRGB(220, 70, 70), 1.08)
addHoverEffect(sp, Color3.fromRGB(50, 120, 200), Color3.fromRGB(70, 140, 220), 1.03)
addHoverEffect(b, Color3.fromRGB(0, 180, 70), Color3.fromRGB(0, 200, 90), 1.03)
addHoverEffect(sh, Color3.fromRGB(200, 100, 50), Color3.fromRGB(220, 120, 70), 1.03)
addHoverEffect(r, cfg.UI_BG_COLOR, cfg.UI_HEADER_COLOR, 1.05)

-- Update status function with smooth transitions
local function upd(txt, col)
    tween(s, {TextTransparency = 1}, tweenInfo.fast)
    task.wait(0.2)
    s.Text = "● " .. txt
    tween(s, {TextColor3 = col, TextTransparency = 0}, tweenInfo.fast)
end

-- Export update function for backend
getgenv().MasploitzUI = {
    updateStatus = upd,
    showSavedPos = function()
        tween(sp, {
            BackgroundColor3 = Color3.fromRGB(0, 180, 70)
        }, tweenInfo.medium)
        sp.Text = "✓ AFK Pos Auto-Saved!"
        task.wait(3)
        tween(sp, {
            BackgroundColor3 = Color3.fromRGB(50, 120, 200)
        }, tweenInfo.medium)
        sp.Text = "Save Pos as AFK Pos"
    end
}

-- Save Position with animation
sp.MouseButton1Click:Connect(function()
    if funcs.savePosition() then
        tween(sp, {
            BackgroundColor3 = Color3.fromRGB(0, 180, 70),
            Size = sp.Size * 1.05
        }, tweenInfo.bounce)
        sp.Text = "✓ AFK Pos Saved!"
        task.wait(0.3)
        tween(sp, {Size = sp.Size / 1.05}, tweenInfo.fast)
        task.wait(2)
        tween(sp, {
            BackgroundColor3 = Color3.fromRGB(50, 120, 200)
        }, tweenInfo.medium)
        sp.Text = "Save Pos as AFK Pos"
    end
end)

-- Toggle with smooth animations
b.MouseButton1Click:Connect(function()
    local enabled = funcs.toggleEnabled()
    
    -- Click animation
    tween(b, {Size = b.Size * 0.95}, tweenInfo.fast)
    task.wait(0.1)
    tween(b, {Size = b.Size / 0.95}, tweenInfo.fast)
    
    if enabled then
        tween(b, {BackgroundColor3 = Color3.fromRGB(0, 180, 70)}, tweenInfo.medium)
        b.Text = "ANTI-AFK: ON"
        upd("Active", Color3.fromRGB(0, 255, 100))
    else
        tween(b, {BackgroundColor3 = Color3.fromRGB(180, 50, 50)}, tweenInfo.medium)
        b.Text = "ANTI-AFK: OFF"
        upd("Disabled", Color3.fromRGB(180, 50, 50))
    end
end)

-- Server Hop with loading animation
sh.MouseButton1Click:Connect(function()
    tween(sh, {
        BackgroundColor3 = Color3.fromRGB(150, 80, 30),
        Size = sh.Size * 0.95
    }, tweenInfo.fast)
    sh.Text = "Hopping..."
    upd("Server hopping...", Color3.fromRGB(255, 150, 50))
    task.wait(0.1)
    tween(sh, {Size = sh.Size / 0.95}, tweenInfo.fast)
    task.wait(0.9)
    funcs.serverHop()
end)

-- Minimize with smooth fade
m.MouseButton1Click:Connect(function()
    tween(m, {Rotation = 360}, tweenInfo.medium)
    tween(f, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(f.Position.X.Scale, f.Position.X.Offset + f.Size.X.Offset/2, 
                            f.Position.Y.Scale, f.Position.Y.Offset + f.Size.Y.Offset/2)
    }, tweenInfo.medium)
    task.wait(0.3)
    f.Visible = false
    f.Size = cfg.UI_SIZE
    f.Position = cfg.UI_POSITION
    m.Rotation = 0
    r.Visible = true
    tween(r, {Size = UDim2.new(0, 160, 0, 40)}, tweenInfo.bounce)
end)

-- Restore with smooth expansion
r.MouseButton1Click:Connect(function()
    tween(r, {Size = UDim2.new(0, 0, 0, 0)}, tweenInfo.fast)
    task.wait(0.2)
    r.Visible = false
    r.Size = UDim2.new(0, 160, 0, 40)
    f.Visible = true
    f.Size = UDim2.new(0, 0, 0, 0)
    f.Position = UDim2.new(0.5, 0, 0.5, 0)
    tween(f, {
        Size = cfg.UI_SIZE,
        Position = cfg.UI_POSITION
    }, tweenInfo.bounce)
end)

-- Close button with confirmation
local closeConfirming = false
x.MouseButton1Click:Connect(function()
    if not closeConfirming then
        closeConfirming = true
        local originalText = x.Text
        local originalColor = x.BackgroundColor3
        
        tween(x, {
            BackgroundColor3 = Color3.fromRGB(220, 70, 70),
            Rotation = 90
        }, tweenInfo.fast)
        x.Text = "?"
        
        upd("Click X again to close", Color3.fromRGB(255, 200, 50))
        
        task.wait(3)
        if closeConfirming then
            tween(x, {
                BackgroundColor3 = originalColor,
                Rotation = 0
            }, tweenInfo.fast)
            x.Text = originalText
            closeConfirming = false
            upd("Active", Color3.fromRGB(0, 255, 100))
        end
    else
        -- Final close with animation
        upd("Goodbye!", Color3.fromRGB(255, 100, 100))
        
        tween(x, {Rotation = 180}, tweenInfo.medium)
        tween(f, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1
        }, tweenInfo.medium)
        
        task.wait(0.4)
        g:Destroy()
        print("👋 Masploitz UI closed gracefully")
    end
end)

print("✅ Masploitz UI initialized with enhanced animations")
