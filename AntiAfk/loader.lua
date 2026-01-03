local TS = game:GetService("TweenService")
local P = game:GetService("Players").LocalPlayer
local RS = game:GetService("RunService")

local enabled = true
local moving = false

-- GUI
local g = Instance.new("ScreenGui")
g.Name = "MasploitzAFK"
g.Parent = game.CoreGui
g.ResetOnSpawn = false

local f = Instance.new("Frame")
f.Parent = g
f.BackgroundColor3 = Color3.fromRGB(15, 45, 65)
f.BorderSizePixel = 0
f.Position = UDim2.new(0.5, -210, 0.5, -120)
f.Size = UDim2.new(0, 420, 0, 240)
f.Active = true
f.Draggable = true

local fc = Instance.new("UICorner")
fc.CornerRadius = UDim.new(0, 15)
fc.Parent = f

local fs = Instance.new("UIStroke")
fs.Color = Color3.fromRGB(80, 150, 200)
fs.Thickness = 3
fs.Parent = f

-- Header
local h = Instance.new("Frame")
h.Parent = f
h.BackgroundColor3 = Color3.fromRGB(10, 35, 55)
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
s.Size = UDim2.new(1, -30, 0, 45)
s.Font = Enum.Font.SourceSansBold
s.Text = "● Active"
s.TextColor3 = Color3.fromRGB(0, 255, 100)
s.TextSize = 20

local sc = Instance.new("UICorner")
sc.CornerRadius = UDim.new(0, 10)
sc.Parent = s

local ss = Instance.new("UIStroke")
ss.Color = Color3.fromRGB(0, 0, 0)
ss.Thickness = 2
ss.Parent = s

-- Toggle
local b = Instance.new("TextButton")
b.Parent = f
b.BackgroundColor3 = Color3.fromRGB(0, 180, 70)
b.BorderSizePixel = 0
b.Position = UDim2.new(0, 15, 0, 130)
b.Size = UDim2.new(1, -30, 0, 50)
b.Font = Enum.Font.SourceSansBold
b.Text = "ANTI-AFK: ON"
b.TextColor3 = Color3.new(1, 1, 1)
b.TextSize = 20

local bc = Instance.new("UICorner")
bc.CornerRadius = UDim.new(0, 10)
bc.Parent = b

local bs = Instance.new("UIStroke")
bs.Color = Color3.fromRGB(0, 0, 0)
bs.Thickness = 2
bs.Parent = b

-- Footer
local ft = Instance.new("TextLabel")
ft.Parent = f
ft.BackgroundTransparency = 1
ft.Position = UDim2.new(0, 0, 1, -30)
ft.Size = UDim2.new(1, 0, 0, 30)
ft.Font = Enum.Font.SourceSansBold
ft.Text = "Made by Masploitz"
ft.TextColor3 = Color3.fromRGB(120, 160, 190)
ft.TextSize = 14

-- Restore
local r = Instance.new("TextButton")
r.Parent = g
r.BackgroundColor3 = Color3.fromRGB(15, 45, 65)
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
rss.Color = Color3.fromRGB(80, 150, 200)
rss.Thickness = 2
rss.Parent = r

-- Functions
local function upd(txt, col)
    s.Text = "● " .. txt
    s.TextColor3 = col
end

local function move()
    if not enabled or moving then return end
    moving = true
    
    pcall(function()
        local c = P.Character
        if not c then return end
        local hum = c:FindFirstChild("Humanoid")
        local root = c:FindFirstChild("HumanoidRootPart")
        if not hum or not root or hum.Health <= 0 then moving = false return end
        
        local orig = root.CFrame
        local jc = math.random(1, 10)
        
        -- Jumps
        for i = 1, jc do
            hum.Jump = true
            wait(0.3)
        end
        
        -- Walk out
        local ang = math.rad(math.random(0, 360))
        local dist = math.random(1, 10)
        local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
        local tpos = orig.Position + (dir * dist)
        
        upd("Moving...", Color3.fromRGB(100, 150, 255))
        
        -- Human-like walking with speed variation
        local speed = 16 + math.random(-2, 4)
        hum.WalkSpeed = speed
        hum:MoveTo(tpos)
        
        -- Add slight direction changes
        spawn(function()
            for i = 1, 3 do
                wait(0.3)
                if hum then
                    local offset = Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
                    hum:MoveTo(tpos + offset)
                end
            end
        end)
        
        wait(dist / speed + 0.5)
        
        -- Fast walk back
        hum.WalkSpeed = 32
        hum:MoveTo(orig.Position)
        wait(dist / 32)
        
        -- Smooth tween back to exact position
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        local tw = TS:Create(root, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {CFrame = orig})
        tw:Play()
        tw.Completed:Wait()
        
        hum:ChangeState(Enum.HumanoidStateType.Running)
        hum.WalkSpeed = 16
        
        upd("Active", Color3.fromRGB(0, 255, 100))
    end)
    
    moving = false
end

-- Toggle
b.MouseButton1Click:Connect(function()
    enabled = not enabled
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

m.MouseButton1Click:Connect(function() f.Visible = false r.Visible = true end)
r.MouseButton1Click:Connect(function() f.Visible = true r.Visible = false end)

-- Anti-AFK
local vu = game:GetService('VirtualUser')

P.Idled:Connect(function()
    if enabled then
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
        upd("Kick Blocked!", Color3.fromRGB(255, 200, 0))
        wait(2)
        upd("Active", Color3.fromRGB(0, 255, 100))
    end
end)

spawn(function() while wait(math.random(1, 60)) do if enabled then move() end end end)
spawn(function() while wait(10) do if enabled and P.Character then move() end end end)
spawn(function() while wait(math.random(4, 8)) do if enabled then pcall(function() vu:CaptureController() vu:ClickButton2(Vector2.new()) end) end end end)

P.CharacterAdded:Connect(function() wait(1) if enabled then upd("Active", Color3.fromRGB(0, 255, 100)) end end)

print("Masploitz Anti-AFK loaded!")
