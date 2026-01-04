-- Masploitz Anti-AFK Backend (Optimized)
local cfg = getgenv().MasploitzConfig
local TS = game:GetService("TweenService")
local P = game:GetService("Players").LocalPlayer
local TPS = game:GetService("TeleportService")
local HTTP = game:GetService("HttpService")

-- State
getgenv().MasploitzState = {
    enabled = true,
    moving = false,
    relocating = false,
    savedPos = nil,
    lastChat = tick(),
    lastEmote = tick(),
    lastCamera = tick()
}
local st = getgenv().MasploitzState

-- R15 Tool None Animation Controller
local toolAnim = nil
local animTrack = nil

local function ensureToolAnim()
    local c = P.Character
    if not c then return end
    
    local hum = c:FindFirstChild("Humanoid")
    if not hum or hum.RigType ~= Enum.HumanoidRigType.R15 then return end
    
    -- Check if animation is playing
    if animTrack and animTrack.IsPlaying then return end
    
    -- Load R15 Tool None animation
    pcall(function()
        if not toolAnim then
            toolAnim = Instance.new("Animation")
            toolAnim.AnimationId = "rbxassetid://507768375" -- R15 Tool None
        end
        
        animTrack = hum:LoadAnimation(toolAnim)
        animTrack.Looped = true
        animTrack:Play()
        
        if cfg.DEBUG_MODE then
            print("🎬 Started R15 Tool None animation")
        end
    end)
end

-- Animation check loop
spawn(function()
    while task.wait() do
        if st.enabled then
            ensureToolAnim()
        end
    end
end)

-- Math helpers
local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end
local function faceCtr(p)
    local c = Vector3.new(0, p.Y, 0)
    local l = (c - p).Unit
    return CFrame.new(p, p + l)
end

-- Server Hop
local function serverHop()
    pcall(function()
        local s = HTTP:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        local srv = nil
        for i, v in pairs(s.data) do
            if v.id ~= game.JobId and v.playing >= cfg.MIN_PLAYERS and v.playing < v.maxPlayers - 1 then
                srv = v break
            end
        end
        if srv then TPS:TeleportToPlaceInstance(game.PlaceId, srv.id, P) else TPS:Teleport(game.PlaceId, P) end
    end)
    TPS:Teleport(game.PlaceId, P)
end

-- Check player count
spawn(function()
    wait(5)
    if #game.Players:GetPlayers() < cfg.MIN_PLAYERS then
        wait(2) serverHop()
    end
end)

-- Equip
local function eq()
    local bp = P:WaitForChild("Backpack", cfg.TOOL_WAIT_TIMEOUT)
    local t = bp:WaitForChild(cfg.AUTO_EQUIP_TOOL, cfg.TOOL_WAIT_TIMEOUT)
    if t then P.Character:WaitForChild("Humanoid"):EquipTool(t) return true end
    return false
end

-- Count nearby
local function cnt(p, r)
    local n = 0
    for _, pl in pairs(game.Players:GetPlayers()) do
        if pl ~= P and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
            if (pl.Character.HumanoidRootPart.Position - p).Magnitude <= r then n = n + 1 end
        end
    end
    return n
end

-- Check front (45 degree cone, only 180 degrees forward)
local function chkFrt(cf)
    local lv = cf.LookVector
    for _, pl in pairs(game.Players:GetPlayers()) do
        if pl ~= P and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
            local tp = pl.Character.HumanoidRootPart.Position
            local dt = (tp - cf.Position).Unit
            local d = (tp - cf.Position).Magnitude
            if d <= cfg.FRONT_CHECK_DISTANCE then
                local a = math.acos(clamp(lv:Dot(dt), -1, 1))
                local deg = math.deg(a)
                -- Only check front 180 degrees (angle < 90 means in front)
                if deg <= cfg.FRONT_CHECK_ANGLE and deg < 90 then
                    if cfg.DEBUG_MODE then
                        print("⚠️ Player in front:", pl.Name, math.floor(d), "studs", math.floor(deg), "deg")
                    end
                    return true
                end
            end
        end
    end
    return false
end

-- Check blocking
local function chkBlk(p)
    for _, pl in pairs(game.Players:GetPlayers()) do
        if pl ~= P and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
            if (pl.Character.HumanoidRootPart.Position - p).Magnitude <= cfg.BLOCK_CHECK_DISTANCE then
                if cfg.DEBUG_MODE then print("🔴 Player too close:", pl.Name) end
                return true
            end
        end
    end
    return false
end

-- Generate positions (only forward 180 degrees)
local function genPos(ctr, r, ct, curCF)
    local ps = {}
    local baseLook = curCF and curCF.LookVector or Vector3.new(0, 0, -1)
    local baseAngle = math.atan2(baseLook.Z, baseLook.X)
    
    for i = 1, ct do
        -- Only generate positions in front (±90 degrees from forward)
        local offset = (i / ct) * math.pi - (math.pi / 2) -- -90 to +90 degrees
        local ang = baseAngle + offset
        local off = Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r)
        table.insert(ps, ctr + off)
    end
    return ps
end

-- Find nearby spot (only forward)
local function fndNear(cp, ccf)
    local bp, mp, bcf = nil, 0, nil
    if cfg.DEBUG_MODE then print("🔍 Searching forward positions...") end
    
    for r = 5, 15, 5 do
        local nps = genPos(cp, r, 8, ccf)
        for _, p in pairs(nps) do
            local tcf = faceCtr(p)
            if not chkFrt(tcf) and not chkBlk(p) then
                local pc = cnt(p, cfg.PLAYER_RADIUS)
                if pc > mp then
                    mp = pc bp = p bcf = tcf
                    if cfg.DEBUG_MODE then print("  ✅ Forward spot:", r, "studs,", pc, "players") end
                end
            end
        end
        if bp and mp > 5 then break end
    end
    return bcf, mp
end

-- Find best spot (forward only when relocating)
local function fndBst(ex, curCF)
    local bcs, mcp, crs, mcrp, crcf = nil, 0, nil, 0, nil
    
    for _, sp in pairs(cfg.SPAWN_POSITIONS) do
        local scf = faceCtr(sp)
        if not ex or (scf.Position - ex).Magnitude > 5 then
            local pc = cnt(scf.Position, cfg.PLAYER_RADIUS)
            local nf = not chkFrt(scf)
            local nb = not chkBlk(scf.Position)
            if nf and nb and pc > mcp then mcp = pc bcs = scf end
            if pc > mcrp then mcrp = pc crs = scf.Position crcf = scf end
        end
    end
    
    if crs and mcrp > mcp + 10 then
        if cfg.DEBUG_MODE then print("🔍 Crowded:", mcrp, "vs clear:", mcp) end
        local ns, nc = fndNear(crs, curCF or crcf)
        if ns and nc > mcp then
            if cfg.DEBUG_MODE then print("✅ Forward spot:", nc, "players") end
            return ns, nc, true
        end
    end
    return bcs, mcp, false
end

-- Position check
local function chkPs(rt, tg) return (rt.Position - tg.Position).Magnitude < 1 end

-- Kill
local function kll()
    if P.Character and P.Character:FindFirstChild("Humanoid") then
        P.Character.Humanoid.Health = 0
    end
end

-- Move
local function mv()
    if not st.enabled or st.moving or st.relocating then return end
    st.moving = true
    pcall(function()
        local c = P.Character if not c then return end
        local h = c:FindFirstChild("Humanoid")
        local rt = c:FindFirstChild("HumanoidRootPart")
        if not h or not rt or h.Health <= 0 then st.moving = false return end
        
        local og = st.savedPos or rt.CFrame
        if not og then st.moving = false return end
        if getgenv().MasploitzUI then getgenv().MasploitzUI.updateStatus("Moving...", Color3.fromRGB(100, 150, 255)) end
        
        local jc = math.random(cfg.MIN_JUMPS, cfg.MAX_JUMPS)
        for i = 1, jc do h.Jump = true wait(cfg.JUMP_INTERVAL) end
        wait(0.1)
        
        local a = math.rad(math.random(0, 360))
        local d = math.random(cfg.MIN_WALK_DISTANCE, cfg.MAX_WALK_DISTANCE)
        local dr = Vector3.new(math.cos(a), 0, math.sin(a))
        local tp = og.Position + (dr * d)
        h.WalkSpeed = cfg.WALK_SPEED_NORMAL h:MoveTo(tp)
        wait(d / cfg.WALK_SPEED_NORMAL + 0.3)
        
        h.WalkSpeed = cfg.WALK_SPEED_FAST h:MoveTo(og.Position)
        wait((d / cfg.WALK_SPEED_FAST) + 0.2)
        wait(math.random(10, 30) / 10)
        
        h:ChangeState(Enum.HumanoidStateType.Physics)
        local tw = TS:Create(rt, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = og})
        tw:Play() tw.Completed:Wait() wait(0.1)
        
        if not chkPs(rt, og) then
            if getgenv().MasploitzUI then getgenv().MasploitzUI.updateStatus("Position lost!", Color3.fromRGB(255, 100, 100)) end
            wait(0.5) kll() st.moving = false return
        end
        
        h:ChangeState(Enum.HumanoidStateType.Running)
        h.WalkSpeed = cfg.WALK_SPEED_NORMAL
        if getgenv().MasploitzUI then getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100)) end
    end)
    st.moving = false
end

-- Relocate (forward only)
local function rlc()
    if st.relocating or st.moving then return end
    local c = P.Character
    if not c or not c:FindFirstChild("HumanoidRootPart") or not c:FindFirstChild("Humanoid") then return end
    
    local rt = c.HumanoidRootPart
    local h = c.Humanoid
    local fb = chkFrt(rt.CFrame)
    local tc = chkBlk(rt.Position)
    
    if fb or tc then
        st.relocating = true
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus(fb and "Player in front! Moving forward..." or "Player too close!", Color3.fromRGB(255, 150, 50))
        end
        
        local bs, bc, np = fndBst(rt.Position, rt.CFrame)
        if bs then
            local PFS = game:GetService("PathfindingService")
            local pth = PFS:CreatePath()
            local ok = pcall(function() pth:ComputeAsync(rt.Position, bs.Position) end)
            
            if ok and pth.Status == Enum.PathStatus.Success then
                for _, wp in pairs(pth:GetWaypoints()) do
                    if wp.Action == Enum.PathWaypointAction.Jump then h.Jump = true end
                    h:MoveTo(wp.Position) h.MoveToFinished:Wait()
                end
            else h:MoveTo(bs.Position) wait(3) end
            
            rt.CFrame = bs st.savedPos = bs
            if getgenv().MasploitzUI then
                getgenv().MasploitzUI.updateStatus(np and "Found crowded area! (" .. bc .. ")" or "Moved forward!", Color3.fromRGB(100, 200, 255))
            end
            wait(2)
            if getgenv().MasploitzUI then getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100)) end
        end
        st.relocating = false return
    end
    
    local cc = cnt(rt.Position, cfg.PLAYER_RADIUS)
    local bs, bc, np = fndBst(rt.Position, rt.CFrame)
    
    if bs and bc > cc + 2 then
        st.relocating = true
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus(np and "Crowded spot! Pathfinding..." or "Busier spot!", Color3.fromRGB(255, 200, 100))
        end
        
        if np then
            local PFS = game:GetService("PathfindingService")
            local pth = PFS:CreatePath()
            local ok = pcall(function() pth:ComputeAsync(rt.Position, bs.Position) end)
            if ok and pth.Status == Enum.PathStatus.Success then
                for _, wp in pairs(pth:GetWaypoints()) do
                    if wp.Action == Enum.PathWaypointAction.Jump then h.Jump = true end
                    h:MoveTo(wp.Position) h.MoveToFinished:Wait()
                end
            else h:MoveTo(bs.Position) wait(3) end
        else
            h.WalkSpeed = cfg.WALK_SPEED_NORMAL h:MoveTo(bs.Position)
            wait((rt.Position - bs.Position).Magnitude / cfg.WALK_SPEED_NORMAL + 1)
        end
        
        rt.CFrame = bs st.savedPos = bs
        if getgenv().MasploitzUI then getgenv().MasploitzUI.updateStatus("Relocated! (" .. bc .. ")", Color3.fromRGB(100, 200, 255)) end
        wait(2)
        if getgenv().MasploitzUI then getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100)) end
        st.relocating = false
    end
end

-- Chat/Emote/Camera
local function cht()
    if cfg.ENABLE_CHAT_MESSAGES and tick() - st.lastChat > math.random(cfg.CHAT_INTERVAL_MIN, cfg.CHAT_INTERVAL_MAX) then
        pcall(function()
            game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(
                cfg.CHAT_MESSAGES[math.random(1, #cfg.CHAT_MESSAGES)], "All")
            st.lastChat = tick()
        end)
    end
end

local function emt()
    if cfg.ENABLE_EMOTES and tick() - st.lastEmote > math.random(cfg.EMOTE_INTERVAL_MIN, cfg.EMOTE_INTERVAL_MAX) then
        local h = P.Character and P.Character:FindFirstChild("Humanoid")
        if h then
            local e = h:GetPlayingAnimationTracks()
            if #e > 0 then e[1]:Stop() end
        end
        st.lastEmote = tick()
    end
end

local function cam()
    if cfg.ENABLE_CAMERA_MOVE and tick() - st.lastCamera > math.random(cfg.CAMERA_INTERVAL_MIN, cfg.CAMERA_INTERVAL_MAX) then
        local cm = workspace.CurrentCamera
        if cm then
            local ccf = cm.CFrame
            local off = CFrame.Angles(math.rad(math.random(-10, 10)), math.rad(math.random(-20, 20)), 0)
            TS:Create(cm, TweenInfo.new(2, Enum.EasingStyle.Quad), {CFrame = ccf * off}):Play()
        end
        st.lastCamera = tick()
    end
end

-- Re-equip
local function reEq()
    if not cfg.AUTO_RE_EQUIP then return end
    local c = P.Character if not c then return end
    local h = c:FindFirstChild("Humanoid") if not h then return end
    if c:FindFirstChild(cfg.AUTO_EQUIP_TOOL) then return end
    
    local bp = P:FindFirstChild("Backpack")
    if bp then
        local t = bp:FindFirstChild(cfg.AUTO_EQUIP_TOOL)
        if t then
            pcall(function()
                h:EquipTool(t)
                if getgenv().MasploitzUI then
                    getgenv().MasploitzUI.updateStatus("Tool Re-equipped", Color3.fromRGB(100, 255, 150))
                    wait(1) getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
                end
            end)
        end
    end
end

-- Anti-AFK
local vu = game:GetService('VirtualUser')
P.Idled:Connect(function()
    if st.enabled then
        vu:CaptureController() vu:ClickButton2(Vector2.new())
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus("Kick Blocked!", Color3.fromRGB(255, 200, 0))
            wait(2) getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
        end
    end
end)

-- Loops
spawn(function() while wait(math.random(cfg.RANDOM_MOVE_MIN, cfg.RANDOM_MOVE_MAX)) do if st.enabled then mv() end end end)
spawn(function() while wait(cfg.REGULAR_MOVE_INTERVAL) do if st.enabled and P.Character then mv() end end end)
spawn(function() while wait(math.random(cfg.MICRO_MOVE_MIN, cfg.MICRO_MOVE_MAX)) do if st.enabled then pcall(function() vu:CaptureController() vu:ClickButton2(Vector2.new()) end) end end end)
spawn(function() while wait(cfg.SPOT_CHECK_INTERVAL) do if st.enabled and not st.relocating and not st.moving then rlc() end end end)
spawn(function() while wait(cfg.BLOCK_CHECK_INTERVAL) do if st.enabled and not st.relocating and not st.moving then local c = P.Character if c and c:FindFirstChild("HumanoidRootPart") then if chkFrt(c.HumanoidRootPart.CFrame) or chkBlk(c.HumanoidRootPart.Position) then rlc() end end end end end)
spawn(function() while wait(10) do if st.enabled then cht() emt() cam() end end end)
spawn(function() while wait(cfg.RE_EQUIP_INTERVAL) do if st.enabled and cfg.AUTO_RE_EQUIP then reEq() end end end)
spawn(function() wait(cfg.AUTO_HOP_TIME) wait(2) serverHop() end)

-- Character handling
P.CharacterAdded:Connect(function()
    wait(2)
    if st.savedPos and st.enabled then
        local c = P.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            c.HumanoidRootPart.CFrame = st.savedPos
            if getgenv().MasploitzUI then getgenv().MasploitzUI.updateStatus("Respawned", Color3.fromRGB(100, 200, 255)) end
            wait(2)
        end
    end
    spawn(function() wait(1) for i = 1, 10 do if eq() then break end wait(0.5) end end)
    if st.enabled and getgenv().MasploitzUI then getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100)) end
end)

-- Initial spawn
spawn(function()
    repeat wait() until P.Character and P.Character:FindFirstChild("HumanoidRootPart")
    wait(1)
    
    local bs, pc, np = fndBst(nil, nil)
    if not bs then
        bs = faceCtr(cfg.SPAWN_POSITIONS[math.random(1, #cfg.SPAWN_POSITIONS)])
        pc = 0 np = false
    end
    
    if np and P.Character and P.Character:FindFirstChild("Humanoid") then
        local h = P.Character.Humanoid
        local rt = P.Character.HumanoidRootPart
        local PFS = game:GetService("PathfindingService")
        local pth = PFS:CreatePath()
        local ok = pcall(function() pth:ComputeAsync(rt.Position, bs.Position) end)
        if ok and pth.Status == Enum.PathStatus.Success then
            for _, wp in pairs(pth:GetWaypoints()) do
                if wp.Action == Enum.PathWaypointAction.Jump then h.Jump = true end
                h:MoveTo(wp.Position) h.MoveToFinished:Wait()
            end
        end
    end
    
    P.Character.HumanoidRootPart.CFrame = bs st.savedPos = bs
    for i = 1, 20 do if getgenv().MasploitzUI then break end wait(0.1) end
    
    if getgenv().MasploitzUI then
        getgenv().MasploitzUI.updateStatus(np and "Crowded area! (" .. pc .. ")" or "Best spot (" .. pc .. ")", Color3.fromRGB(100, 200, 255))
        spawn(function() getgenv().MasploitzUI.showSavedPos() end)
    end
    wait(1) eq() wait(2)
    if getgenv().MasploitzUI then getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100)) end
end)

print("✅ Masploitz Backend initialized")

-- Exposed functions
getgenv().MasploitzFunctions = {
    serverHop = serverHop,
    savePosition = function()
        local c = P.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            st.savedPos = c.HumanoidRootPart.CFrame return true
        end
        return false
    end,
    toggleEnabled = function()
        st.enabled = not st.enabled return st.enabled
    end,
    reEquipTool = reEq
}
