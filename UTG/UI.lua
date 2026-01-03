-- Masploitz Hub UI
-- Upload this as ui.lua to your GitHub repo

local TS = game:GetService("TweenService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local MS = game:GetService("MarketplaceService")

local UI = {}
local backend = nil
local tpBtns = {}
local settingsOpen = false

-- UI Elements (will be created in init)
local sg, container, shadow, main, setPanel, statLbl, statDot, teamList

-- Helper functions
local function c(t, p)
    local i = Instance.new(t)
    for k, v in pairs(p) do if k ~= "Parent" then i[k] = v end end
    i.Parent = p.Parent
    return i
end

local function corner(p, r) return c("UICorner", {CornerRadius = UDim.new(0, r), Parent = p}) end
local function stroke(p, col, t, tr) return c("UIStroke", {Color = col, Thickness = t or 2, Transparency = tr or 0, Parent = p}) end
local function grad(p, c1, c2, r) return c("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2)}), Rotation = r or 90, Parent = p}) end
local function tween(o, t, p) TS:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play() end

local function btn(par, pos, sz, c1, txt, ts)
    local b = c("TextButton", {Parent = par, Size = sz, Position = pos, BackgroundColor3 = c1, Text = txt, TextColor3 = Color3.fromRGB(224, 231, 255), Font = Enum.Font.GothamBold, TextSize = ts or 14, BorderSizePixel = 0, ZIndex = 3})
    corner(b, 12) stroke(b, Color3.fromRGB(59, 130, 246), 1, 0.15)
    b.MouseEnter:Connect(function() 
        tween(b, 0.15, {Size = UDim2.new(sz.X.Scale, sz.X.Offset + 3, sz.Y.Scale, sz.Y.Offset + 2)})
        tween(b:FindFirstChildOfClass("UIStroke"), 0.15, {Transparency = 0})
    end)
    b.MouseLeave:Connect(function() 
        tween(b, 0.15, {Size = sz})
        tween(b:FindFirstChildOfClass("UIStroke"), 0.15, {Transparency = 0.15})
    end)
    return b
end

-- Status update
local function updateStat(txt, col)
    statLbl.Text = txt
    tween(statLbl, 0.2, {TextColor3 = Color3.fromRGB(229, 231, 235)})
    tween(statDot, 0.2, {BackgroundColor3 = col})
end

-- Create team button
local function createTeamBtn(col, cnt, colVal, y)
    local f = c("Frame", {Parent = teamList, Size = UDim2.new(1, -10, 0, 42), Position = UDim2.new(0, 5, 0, y), BackgroundColor3 = Color3.fromRGB(11, 16, 32), BorderSizePixel = 0, ZIndex = 3})
    corner(f, 10) stroke(f, Color3.fromRGB(59, 130, 246), 1, 0.15)
    
    local box = c("Frame", {Parent = f, Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(0, 8, 0.5, -13), BackgroundColor3 = colVal, BorderSizePixel = 0, ZIndex = 4})
    corner(box, 8) stroke(box, Color3.fromRGB(255, 255, 255), 1, 0.5)
    
    c("TextLabel", {Parent = f, BackgroundTransparency = 1, Size = UDim2.new(0, 85, 1, 0), Position = UDim2.new(0, 40, 0, 0), Text = col, TextColor3 = Color3.fromRGB(229, 231, 235), Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4})
    
    local badge = c("Frame", {Parent = f, BackgroundColor3 = Color3.fromRGB(30, 64, 175), Size = UDim2.new(0, 32, 0, 20), Position = UDim2.new(0, 130, 0.5, -10), BorderSizePixel = 0, ZIndex = 4, BackgroundTransparency = 0.5})
    corner(badge, 6)
    c("TextLabel", {Parent = badge, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = cnt, TextColor3 = Color3.fromRGB(147, 197, 253), Font = Enum.Font.GothamBold, TextSize = 11, ZIndex = 5})
    
    local b = btn(f, UDim2.new(1, -75, 0.5, -13), UDim2.new(0, 70, 0, 26), Color3.fromRGB(30, 64, 175), "Join", 11)
    
    b.MouseButton1Click:Connect(function()
        local active = b.Text == "Active"
        if active then
            b.Text = "Join"
            tween(b, 0.2, {BackgroundColor3 = Color3.fromRGB(30, 64, 175)})
            backend.stopTeleport()
            updateStat("Inactive", Color3.fromRGB(248, 113, 113))
        else
            for _, bt in pairs(tpBtns) do
                bt.Text = "Join"
                tween(bt, 0.2, {BackgroundColor3 = Color3.fromRGB(30, 64, 175)})
            end
            b.Text = "Active"
            tween(b, 0.2, {BackgroundColor3 = Color3.fromRGB(6, 78, 59)})
            
            local success = backend.startTeleport(col, function()
                -- On team joined callback
                updateStat("Team Joined!", Color3.fromRGB(52, 211, 153))
                for _, bt in pairs(tpBtns) do
                    bt.Text = "Join"
                    tween(bt, 0.2, {BackgroundColor3 = Color3.fromRGB(30, 64, 175)})
                end
                
                -- Auto return if enabled
                if backend.settings.autoReturn then
                    wait(0.3)
                    backend.returnToSpawn()
                    wait(0.2)
                end
                
                updateStat("Inactive", Color3.fromRGB(248, 113, 113))
            end)
            
            if success then
                updateStat("Active - " .. col, Color3.fromRGB(52, 211, 153))
            else
                updateStat("No players found", Color3.fromRGB(251, 191, 36))
                b.Text = "Join"
                tween(b, 0.2, {BackgroundColor3 = Color3.fromRGB(30, 64, 175)})
            end
        end
    end)
    return b
end

-- Update teams list
local function updateTeams()
    for _, ch in pairs(teamList:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
    tpBtns = {}
    
    local teams = backend.getTeams()
    local y = 0
    for col, info in pairs(teams) do
        table.insert(tpBtns, createTeamBtn(col, info.Count, info.Color, y))
        y = y + 47
    end
    teamList.CanvasSize = UDim2.new(0, 0, 0, y)
end

-- Initialize UI
function UI.init(backendModule)
    backend = backendModule
    
    -- Create ScreenGui
    sg = Instance.new("ScreenGui", LP:WaitForChild("PlayerGui"))
    sg.ResetOnSpawn, sg.Name = false, "MasploitzHub"
    
    -- Toggle Button
    local tog = c("TextButton", {Parent = sg, Size = UDim2.new(0, 75, 0, 75), Position = UDim2.new(0.5, -37.5, 0, 25), BackgroundColor3 = Color3.fromRGB(11, 16, 32), Text = "🎯", TextColor3 = Color3.fromRGB(224, 231, 255), Font = Enum.Font.GothamBold, TextSize = 36, BorderSizePixel = 0, Visible = false, ZIndex = 10})
    corner(tog, 20) stroke(tog, Color3.fromRGB(59, 130, 246), 2, 0.3)
    
    -- Shadow
    shadow = c("Frame", {Parent = sg, BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.4, Size = UDim2.new(0, 360, 0, 450), Position = UDim2.new(0.5, -180, 0.5, -220), BorderSizePixel = 0, ZIndex = 0})
    corner(shadow, 18)
    
    -- Container
    container = c("Frame", {Parent = sg, BackgroundTransparency = 1, Size = UDim2.new(0, 350, 0, 440), Position = UDim2.new(0.5, -175, 0.5, -220), ClipsDescendants = true, BorderSizePixel = 0})
    
    -- Main Panel
    main = c("Frame", {Parent = container, BackgroundColor3 = Color3.fromRGB(11, 16, 32), Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), BorderSizePixel = 0})
    corner(main, 16) stroke(main, Color3.fromRGB(59, 130, 246), 1, 0.15) grad(main, Color3.fromRGB(11, 20, 48), Color3.fromRGB(11, 16, 32), 180)
    
    c("Frame", {Parent = main, BackgroundColor3 = Color3.fromRGB(59, 130, 246), Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 0, 0), BorderSizePixel = 0, ZIndex = 5, BackgroundTransparency = 0.3})
    
    -- Settings Panel
    setPanel = c("Frame", {Parent = container, BackgroundColor3 = Color3.fromRGB(11, 16, 32), Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(1, 0, 0, 0), BorderSizePixel = 0})
    corner(setPanel, 16) stroke(setPanel, Color3.fromRGB(59, 130, 246), 1, 0.15) grad(setPanel, Color3.fromRGB(11, 20, 48), Color3.fromRGB(11, 16, 32), 180)
    
    c("Frame", {Parent = setPanel, BackgroundColor3 = Color3.fromRGB(59, 130, 246), Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 0, 0), BorderSizePixel = 0, ZIndex = 5, BackgroundTransparency = 0.3})
    
    -- Title (Main)
    local title = c("Frame", {Parent = main, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 65), BorderSizePixel = 0, ZIndex = 2})
    local brandFrame = c("Frame", {Parent = title, BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.new(0, 15, 0, 0), ZIndex = 3})
    c("TextLabel", {Parent = brandFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 10), Text = "MASPLOITZ HUB", TextColor3 = Color3.fromRGB(224, 231, 255), Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3})
    
    local gameName = MS:GetProductInfo(game.PlaceId).Name
    c("TextLabel", {Parent = brandFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0, 0, 0, 40), Text = gameName:lower(), TextColor3 = Color3.fromRGB(139, 147, 167), Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3})
    
    local settingsBtn = btn(title, UDim2.new(1, -140, 0.5, -18), UDim2.new(0, 38, 0, 36), Color3.fromRGB(30, 64, 175), "⚙", 20)
    local hide = btn(title, UDim2.new(1, -95, 0.5, -18), UDim2.new(0, 38, 0, 36), Color3.fromRGB(30, 41, 59), "−", 22)
    local close = btn(title, UDim2.new(1, -50, 0.5, -18), UDim2.new(0, 38, 0, 36), Color3.fromRGB(127, 29, 29), "×", 22)
    
    -- Title (Settings)
    local setTitle = c("Frame", {Parent = setPanel, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 65), BorderSizePixel = 0, ZIndex = 2})
    c("TextLabel", {Parent = setTitle, BackgroundTransparency = 1, Size = UDim2.new(0.7, 0, 0, 28), Position = UDim2.new(0, 15, 0, 18), Text = "SETTINGS", TextColor3 = Color3.fromRGB(224, 231, 255), Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3})
    local backBtn = btn(setTitle, UDim2.new(1, -50, 0.5, -18), UDim2.new(0, 38, 0, 36), Color3.fromRGB(30, 41, 59), "←", 22)
    
    -- Status
    local statF = c("Frame", {Parent = main, BackgroundColor3 = Color3.fromRGB(2, 6, 23), Size = UDim2.new(0.88, 0, 0, 50), Position = UDim2.new(0.06, 0, 0, 80), BorderSizePixel = 0, ZIndex = 2})
    corner(statF, 12) stroke(statF, Color3.fromRGB(59, 130, 246), 1, 0.25)
    statDot = c("Frame", {Parent = statF, BackgroundColor3 = Color3.fromRGB(248, 113, 113), Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 15, 0.5, -5), BorderSizePixel = 0, ZIndex = 3})
    corner(statDot, 5)
    statLbl = c("TextLabel", {Parent = statF, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 32, 0, 0), Text = "Inactive", TextColor3 = Color3.fromRGB(229, 231, 235), Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3})
    
    -- Controls
    local ctrlF = c("Frame", {Parent = main, BackgroundTransparency = 1, Size = UDim2.new(0.88, 0, 0, 48), Position = UDim2.new(0.06, 0, 0, 145), ZIndex = 2})
    local stop = btn(ctrlF, UDim2.new(0, 0, 0, 0), UDim2.new(0.48, 0, 1, 0), Color3.fromRGB(127, 29, 29), "Stop", 14)
    local ret = btn(ctrlF, UDim2.new(0.52, 0, 0, 0), UDim2.new(0.48, 0, 1, 0), Color3.fromRGB(30, 64, 175), "Return", 14)
    
    -- Team Header
    local teamH = c("Frame", {Parent = main, BackgroundColor3 = Color3.fromRGB(2, 6, 23), Size = UDim2.new(0.88, 0, 0, 32), Position = UDim2.new(0.06, 0, 0, 208), BorderSizePixel = 0, ZIndex = 2})
    corner(teamH, 10) stroke(teamH, Color3.fromRGB(59, 130, 246), 1, 0.2)
    c("TextLabel", {Parent = teamH, BackgroundTransparency = 1, Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0, 12, 0, 0), Text = "Available Teams", TextColor3 = Color3.fromRGB(229, 231, 235), Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3})
    
    -- Team List
    teamList = c("ScrollingFrame", {Parent = main, BackgroundColor3 = Color3.fromRGB(2, 6, 23), Size = UDim2.new(0.88, 0, 0, 190), Position = UDim2.new(0.06, 0, 0, 245), CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 6, BorderSizePixel = 0, ScrollBarImageColor3 = Color3.fromRGB(59, 130, 246), ZIndex = 2})
    corner(teamList, 12) stroke(teamList, Color3.fromRGB(59, 130, 246), 1, 0.25)
    
    -- Settings Content
    local setContent = c("Frame", {Parent = setPanel, BackgroundTransparency = 1, Size = UDim2.new(0.88, 0, 0, 360), Position = UDim2.new(0.06, 0, 0, 80), ZIndex = 2})
    
    -- Auto Return
    local autoRetF = c("Frame", {Parent = setContent, BackgroundColor3 = Color3.fromRGB(2, 6, 23), Size = UDim2.new(1, 0, 0, 65), Position = UDim2.new(0, 0, 0, 0), BorderSizePixel = 0, ZIndex = 3})
    corner(autoRetF, 12) stroke(autoRetF, Color3.fromRGB(59, 130, 246), 1, 0.2)
    c("TextLabel", {Parent = autoRetF, BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 0, 22), Position = UDim2.new(0, 14, 0, 10), Text = "Auto Return", TextColor3 = Color3.fromRGB(229, 231, 235), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4})
    c("TextLabel", {Parent = autoRetF, BackgroundTransparency = 1, Size = UDim2.new(0.85, 0, 0, 25), Position = UDim2.new(0, 14, 0, 34), Text = "Return to spawn after joining team", TextColor3 = Color3.fromRGB(139, 147, 167), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 4})
    
    local toggleF = c("Frame", {Parent = autoRetF, BackgroundColor3 = Color3.fromRGB(52, 211, 153), Size = UDim2.new(0, 52, 0, 28), Position = UDim2.new(1, -58, 0.5, -14), BorderSizePixel = 0, ZIndex = 4})
    corner(toggleF, 14) stroke(toggleF, Color3.fromRGB(52, 211, 153), 1, 0.3)
    local toggleCircle = c("Frame", {Parent = toggleF, BackgroundColor3 = Color3.fromRGB(224, 231, 255), Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(0, 27, 0.5, -11), BorderSizePixel = 0, ZIndex = 5})
    corner(toggleCircle, 11)
    local toggleBtn = c("TextButton", {Parent = toggleF, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", ZIndex = 6})
    
    -- Distance
    local distF = c("Frame", {Parent = setContent, BackgroundColor3 = Color3.fromRGB(2, 6, 23), Size = UDim2.new(1, 0, 0, 65), Position = UDim2.new(0, 0, 0, 75), BorderSizePixel = 0, ZIndex = 3})
    corner(distF, 12) stroke(distF, Color3.fromRGB(59, 130, 246), 1, 0.2)
    c("TextLabel", {Parent = distF, BackgroundTransparency = 1, Size = UDim2.new(0.55, 0, 0, 22), Position = UDim2.new(0, 14, 0, 10), Text = "Follow Distance", TextColor3 = Color3.fromRGB(229, 231, 235), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4})
    c("TextLabel", {Parent = distF, BackgroundTransparency = 1, Size = UDim2.new(0.7, 0, 0, 25), Position = UDim2.new(0, 14, 0, 34), Text = "Distance behind target (0-100 studs)", TextColor3 = Color3.fromRGB(139, 147, 167), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4})
    
    local distBox = c("TextBox", {Parent = distF, BackgroundColor3 = Color3.fromRGB(2, 6, 23), Size = UDim2.new(0, 60, 0, 32), Position = UDim2.new(1, -66, 0.5, -16), Text = "3", TextColor3 = Color3.fromRGB(229, 231, 235), Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0, ZIndex = 4, PlaceholderText = "3", TextXAlignment = Enum.TextXAlignment.Center})
    corner(distBox, 10) stroke(distBox, Color3.fromRGB(59, 130, 246), 1, 0.25)
    
    -- Exclude Own Team Toggle
    local excludeF = c("Frame", {Parent = setContent, BackgroundColor3 = Color3.fromRGB(2, 6, 23), Size = UDim2.new(1, 0, 0, 65), Position = UDim2.new(0, 0, 0, 150), BorderSizePixel = 0, ZIndex = 3})
    corner(excludeF, 12) stroke(excludeF, Color3.fromRGB(59, 130, 246), 1, 0.2)
    c("TextLabel", {Parent = excludeF, BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 0, 22), Position = UDim2.new(0, 14, 0, 10), Text = "Hide Own Team", TextColor3 = Color3.fromRGB(229, 231, 235), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4})
    c("TextLabel", {Parent = excludeF, BackgroundTransparency = 1, Size = UDim2.new(0.85, 0, 0, 25), Position = UDim2.new(0, 14, 0, 34), Text = "Don't show your current team in the list", TextColor3 = Color3.fromRGB(139, 147, 167), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 4})
    
    local excludeToggleF = c("Frame", {Parent = excludeF, BackgroundColor3 = Color3.fromRGB(248, 113, 113), Size = UDim2.new(0, 52, 0, 28), Position = UDim2.new(1, -58, 0.5, -14), BorderSizePixel = 0, ZIndex = 4})
    corner(excludeToggleF, 14) stroke(excludeToggleF, Color3.fromRGB(248, 113, 113), 1, 0.3)
    local excludeCircle = c("Frame", {Parent = excludeToggleF, BackgroundColor3 = Color3.fromRGB(224, 231, 255), Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(0, 3, 0.5, -11), BorderSizePixel = 0, ZIndex = 5})
    corner(excludeCircle, 11)
    local excludeToggleBtn = c("TextButton", {Parent = excludeToggleF, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", ZIndex = 6})
    
    -- Stop On Team Join Toggle
    local stopJoinF = c("Frame", {Parent = setContent, BackgroundColor3 = Color3.fromRGB(2, 6, 23), Size = UDim2.new(1, 0, 0, 65), Position = UDim2.new(0, 0, 0, 225), BorderSizePixel = 0, ZIndex = 3})
    corner(stopJoinF, 12) stroke(stopJoinF, Color3.fromRGB(59, 130, 246), 1, 0.2)
    c("TextLabel", {Parent = stopJoinF, BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 0, 22), Position = UDim2.new(0, 14, 0, 10), Text = "Stop On Team Join", TextColor3 = Color3.fromRGB(229, 231, 235), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4})
    c("TextLabel", {Parent = stopJoinF, BackgroundTransparency = 1, Size = UDim2.new(0.85, 0, 0, 25), Position = UDim2.new(0, 14, 0, 34), Text = "Stop teleporting when you join the target team", TextColor3 = Color3.fromRGB(139, 147, 167), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 4})
    
    local stopJoinToggleF = c("Frame", {Parent = stopJoinF, BackgroundColor3 = Color3.fromRGB(52, 211, 153), Size = UDim2.new(0, 52, 0, 28), Position = UDim2.new(1, -58, 0.5, -14), BorderSizePixel = 0, ZIndex = 4})
    corner(stopJoinToggleF, 14) stroke(stopJoinToggleF, Color3.fromRGB(52, 211, 153), 1, 0.3)
    local stopJoinCircle = c("Frame", {Parent = stopJoinToggleF, BackgroundColor3 = Color3.fromRGB(224, 231, 255), Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(0, 27, 0.5, -11), BorderSizePixel = 0, ZIndex = 5})
    corner(stopJoinCircle, 11)
    local stopJoinToggleBtn = c("TextButton", {Parent = stopJoinToggleF, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", ZIndex = 6})
    
    -- Info
    local infoF = c("Frame", {Parent = setContent, BackgroundColor3 = Color3.fromRGB(6, 78, 59), BackgroundTransparency = 0.65, Size = UDim2.new(1, 0, 0, 85), Position = UDim2.new(0, 0, 0, 300), BorderSizePixel = 0, ZIndex = 3})
    corner(infoF, 12) stroke(infoF, Color3.fromRGB(52, 211, 153), 1, 0.35)
    c("TextLabel", {Parent = infoF, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, -14), Position = UDim2.new(0, 10, 0, 7), Text = "💡 Tip: Lower distances keep you closer to the target. Higher distances give you more space. You'll always face the same direction as your target!", TextColor3 = Color3.fromRGB(229, 231, 235), Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, ZIndex = 4})
    
    -- Dragging
    local drag, dragIn, dragSt, stPos
    local function updateDrag(inp)
        local d = inp.Position - dragSt
        container.Position = UDim2.new(stPos.X.Scale, stPos.X.Offset + d.X, stPos.Y.Scale, stPos.Y.Offset + d.Y)
        shadow.Position = UDim2.new(stPos.X.Scale, stPos.X.Offset + d.X - 5, stPos.Y.Scale, stPos.Y.Offset + d.Y + 5)
    end
    
    title.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag, dragSt, stPos = true, inp.Position, container.Position
            inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then drag = false end end)
        end
    end)
    
    setTitle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag, dragSt, stPos = true, inp.Position, container.Position
            inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then drag = false end end)
        end
    end)
    
    title.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then dragIn = inp end
    end)
    
    setTitle.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then dragIn = inp end
    end)
    
    UIS.InputChanged:Connect(function(inp) if inp == dragIn and drag then updateDrag(inp) end end)
    
    -- Button Events
    stop.MouseButton1Click:Connect(function()
        backend.stopTeleport()
        updateStat("Inactive", Color3.fromRGB(248, 113, 113))
        for _, bt in pairs(tpBtns) do bt.Text = "Join" tween(bt, 0.2, {BackgroundColor3 = Color3.fromRGB(30, 64, 175)}) end
    end)
    
    ret.MouseButton1Click:Connect(function()
        backend.returnToSpawn()
    end)
    
    settingsBtn.MouseButton1Click:Connect(function()
        if settingsOpen then
            tween(main, 0.4, {Position = UDim2.new(0, 0, 0, 0)})
            tween(setPanel, 0.4, {Position = UDim2.new(1, 0, 0, 0)})
            settingsOpen = false
        else
            tween(main, 0.4, {Position = UDim2.new(-1, 0, 0, 0)})
            tween(setPanel, 0.4, {Position = UDim2.new(0, 0, 0, 0)})
            settingsOpen = true
        end
    end)
    
    backBtn.MouseButton1Click:Connect(function()
        tween(main, 0.4, {Position = UDim2.new(0, 0, 0, 0)})
        tween(setPanel, 0.4, {Position = UDim2.new(1, 0, 0, 0)})
        settingsOpen = false
    end)
    
    toggleBtn.MouseButton1Click:Connect(function()
        backend.settings.autoReturn = not backend.settings.autoReturn
        if backend.settings.autoReturn then
            tween(toggleF, 0.3, {BackgroundColor3 = Color3.fromRGB(52, 211, 153)})
            tween(toggleCircle, 0.3, {Position = UDim2.new(0, 27, 0.5, -11)})
        else
            tween(toggleF, 0.3, {BackgroundColor3 = Color3.fromRGB(248, 113, 113)})
            tween(toggleCircle, 0.3, {Position = UDim2.new(0, 3, 0.5, -11)})
        end
    end)
    
    excludeToggleBtn.MouseButton1Click:Connect(function()
        backend.settings.excludeOwnTeam = not backend.settings.excludeOwnTeam
        if backend.settings.excludeOwnTeam then
            tween(excludeToggleF, 0.3, {BackgroundColor3 = Color3.fromRGB(52, 211, 153)})
            tween(excludeCircle, 0.3, {Position = UDim2.new(0, 27, 0.5, -11)})
        else
            tween(excludeToggleF, 0.3, {BackgroundColor3 = Color3.fromRGB(248, 113, 113)})
            tween(excludeCircle, 0.3, {Position = UDim2.new(0, 3, 0.5, -11)})
        end
        updateTeams() -- Refresh team list immediately
    end)
    
    distBox.FocusLost:Connect(function()
        local n = tonumber(distBox.Text)
        if n and n >= 0 and n <= 100 then
            backend.settings.distance = n
        else
            distBox.Text = tostring(backend.settings.distance)
        end
    end)
    
    hide.MouseButton1Click:Connect(function()
        tween(container, 0.3, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)})
        tween(shadow, 0.3, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)})
        wait(0.3)
        container.Visible, shadow.Visible, tog.Visible = false, false, true
    end)
    
    tog.MouseButton1Click:Connect(function()
        container.Visible, shadow.Visible = true, true
        tween(container, 0.4, {Size = UDim2.new(0, 350, 0, 440), Position = UDim2.new(0.5, -175, 0.5, -220)})
        tween(shadow, 0.4, {Size = UDim2.new(0, 360, 0, 450), Position = UDim2.new(0.5, -180, 0.5, -225)})
        tog.Visible = false
    end)
    
    close.MouseButton1Click:Connect(function()
        backend.cleanup()
        tween(container, 0.3, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)})
        tween(shadow, 0.3, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)})
        wait(0.3)
        sg:Destroy()
    end)
    
    -- Auto update teams
    spawn(function()
        while sg.Parent do
            updateTeams()
            wait(2)
        end
    end)
    
    -- Initial update
    updateTeams()
end

return UI
