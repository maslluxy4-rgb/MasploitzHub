-- Masploitz Anti-AFK Backend (Enhanced - No Kill, Better Logic)
local cfg = getgenv().MasploitzConfig
local TS = game:GetService("TweenService")
local P = game:GetService("Players").LocalPlayer
local TPS = game:GetService("TeleportService")
local HTTP = game:GetService("HttpService")
local RS = game:GetService("RunService")

-- Enhanced State Management
getgenv().MasploitzState = {
    enabled = true,
    moving = false,
    relocating = false,
    savedPos = nil,
    lastChat = tick(),
    lastEmote = tick(),
    lastCamera = tick(),
    positionLostCount = 0,
    lastSuccessfulMove = tick(),
    isRecovering = false,
    animationActive = false
}
local st = getgenv().MasploitzState

-- Animation Controller (More Robust)
local toolAnim = nil
local animTrack = nil
local lastAnimCheck = 0

local function ensureToolAnim()
    if not st.enabled or tick() - lastAnimCheck < 2 then return end
    lastAnimCheck = tick()
    
    local c = P.Character
    if not c then return end
    
    local hum = c:FindFirstChild("Humanoid")
    if not hum or hum.RigType ~= Enum.HumanoidRigType.R15 then return end
    
    -- Only restart if animation stopped
    if animTrack and animTrack.IsPlaying then 
        st.animationActive = true
        return 
    end
    
    local success = pcall(function()
        if not toolAnim then
            toolAnim = Instance.new("Animation")
            toolAnim.AnimationId = "rbxassetid://507768375"
        end
        
        if animTrack then
            animTrack:Stop()
        end
        
        animTrack = hum:LoadAnimation(toolAnim)
        animTrack.Looped = true
        animTrack.Priority = Enum.AnimationPriority.Action
        animTrack:Play()
        st.animationActive = true
        
        if cfg.DEBUG_MODE then
            print("🎬 R15 Tool None animation started")
        end
    end)
    
    if not success then
        st.animationActive = false
    end
end

-- Animation check with better timing
task.spawn(function()
    while task.wait(3) do
        if st.enabled then
            ensureToolAnim()
        end
    end
end)

-- Math Helpers
local function clamp(v, mn, mx) 
    return math.max(mn, math.min(mx, v)) 
end

local function faceCtr(p)
    local c = Vector3.new(0, p.Y, 0)
    local l = (c - p).Unit
    return CFrame.new(p, p + l)
end

local function validatePosition(pos)
    if not pos then return false end
    if typeof(pos) ~= "Vector3" and typeof(pos) ~= "CFrame" then return false end
    local p = typeof(pos) == "CFrame" and pos.Position or pos
    return p.Y > -500 and p.Y < 1000 and math.abs(p.X) < 10000 and math.abs(p.Z) < 10000
end

-- Enhanced Server Hop with better error handling
local function serverHop()
    if st.relocating or st.moving then return end
    
    local success = pcall(function()
        local response = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local servers = HTTP:JSONDecode(response)
        
        if servers and servers.data then
            for _, server in pairs(servers.data) do
                if server.id ~= game.JobId and 
                   server.playing >= cfg.MIN_PLAYERS and 
                   server.playing < server.maxPlayers - 2 then
                    TPS:TeleportToPlaceInstance(game.PlaceId, server.id, P)
                    return
                end
            end
        end
        
        -- Fallback to random server
        TPS:Teleport(game.PlaceId, P)
    end)
    
    if not success then
        -- Final fallback
        task.wait(1)
        TPS:Teleport(game.PlaceId, P)
    end
end

-- Better player count check
task.spawn(function()
    task.wait(5)
    local currentPlayers = #game.Players:GetPlayers()
    
    if currentPlayers < cfg.MIN_PLAYERS then
        if cfg.DEBUG_MODE then
            print("⚠️ Server below minimum players:", currentPlayers)
        end
        task.wait(2)
        serverHop()
    end
end)

-- Equip with retry logic
local function eq()
    for attempt = 1, 5 do
        local success = pcall(function()
            local bp = P:WaitForChild("Backpack", 5)
            local t = bp:FindFirstChild(cfg.AUTO_EQUIP_TOOL)
            
            if t and P.Character and P.Character:FindFirstChild("Humanoid") then
                P.Character.Humanoid:EquipTool(t)
                return true
            end
        end)
        
        if success then return true end
        task.wait(0.5)
    end
    return false
end

-- Count nearby players with validation
local function cnt(p, r)
    if not validatePosition(p) then return 0 end
    
    local n = 0
    for _, pl in pairs(game.Players:GetPlayers()) do
        if pl ~= P and pl.Character then
            local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local distance = (hrp.Position - p).Magnitude
                if distance <= r then
                    n = n + 1
                end
            end
        end
    end
    return n
end

-- Enhanced front check (180 degree forward cone)
local function chkFrt(cf)
    if not cf then return false end
    
    local lv = cf.LookVector
    for _, pl in pairs(game.Players:GetPlayers()) do
        if pl ~= P and pl.Character then
            local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local tp = hrp.Position
                local dt = (tp - cf.Position).Unit
                local d = (tp - cf.Position).Magnitude
                
                if d <= cfg.FRONT_CHECK_DISTANCE then
                    local dotProduct = lv:Dot(dt)
                    local a = math.acos(clamp(dotProduct, -1, 1))
                    local deg = math.deg(a)
                    
                    -- Only front 180 degrees
                    if deg <= cfg.FRONT_CHECK_ANGLE and deg < 90 then
                        if cfg.DEBUG_MODE then
                            print(string.format("⚠️ Player in front: %s | %.1f studs | %.1f°", pl.Name, d, deg))
                        end
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- Check if player blocking
local function chkBlk(p)
    if not validatePosition(p) then return true end
    
    for _, pl in pairs(game.Players:GetPlayers()) do
        if pl ~= P and pl.Character then
            local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - p).Magnitude <= cfg.BLOCK_CHECK_DISTANCE then
                if cfg.DEBUG_MODE then
                    print("🔴 Player blocking:", pl.Name)
                end
                return true
            end
        end
    end
    return false
end

-- Generate forward-facing positions
local function genPos(ctr, r, ct, curCF)
    local ps = {}
    local baseLook = curCF and curCF.LookVector or Vector3.new(0, 0, -1)
    local baseAngle = math.atan2(baseLook.Z, baseLook.X)
    
    for i = 1, ct do
        local offset = (i / ct) * math.pi - (math.pi / 2)
        local ang = baseAngle + offset
        local off = Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r)
        local pos = ctr + off
        
        if validatePosition(pos) then
            table.insert(ps, pos)
        end
    end
    return ps
end

-- Find nearby spot with better validation
local function fndNear(cp, ccf)
    if not validatePosition(cp) then return nil, 0 end
    
    local bp, mp, bcf = nil, 0, nil
    if cfg.DEBUG_MODE then print("🔍 Scanning forward positions...") end
    
    for r = 5, 20, 5 do
        local nps = genPos(cp, r, 12, ccf)
        for _, p in pairs(nps) do
            local tcf = faceCtr(p)
            if not chkFrt(tcf) and not chkBlk(p) then
                local pc = cnt(p, cfg.PLAYER_RADIUS)
                if pc > mp then
                    mp = pc
                    bp = p
                    bcf = tcf
                    if cfg.DEBUG_MODE then
                        print(string.format("  ✅ Forward spot: %d studs | %d players", r, pc))
                    end
                end
            end
        end
        if bp and mp > 3 then break end
    end
    return bcf, mp
end

-- Enhanced best spot finder
local function fndBst(ex, curCF)
    local bcs, mcp = nil, 0
    local crs, mcrp, crcf = nil, 0, nil
    
    for _, sp in pairs(cfg.SPAWN_POSITIONS) do
        if not validatePosition(sp) then continue end
        
        local scf = faceCtr(sp)
        if not ex or (scf.Position - ex).Magnitude > 10 then
            local pc = cnt(scf.Position, cfg.PLAYER_RADIUS)
            local nf = not chkFrt(scf)
            local nb = not chkBlk(scf.Position)
            
            if nf and nb and pc > mcp then
                mcp = pc
                bcs = scf
            end
            
            if pc > mcrp then
                mcrp = pc
                crs = scf.Position
                crcf = scf
            end
        end
    end
    
    -- Try to find better spot near crowded areas
    if crs and mcrp > mcp + 8 then
        if cfg.DEBUG_MODE then
            print(string.format("🔍 Crowded area: %d vs clear: %d", mcrp, mcp))
        end
        
        local ns, nc = fndNear(crs, curCF or crcf)
        if ns and nc > mcp then
            if cfg.DEBUG_MODE then
                print(string.format("✅ Better forward spot: %d players", nc))
            end
            return ns, nc, true
        end
    end
    
    return bcs, mcp, false
end

-- Improved position recovery (NO KILL)
local function recoverPosition()
    if st.isRecovering then return false end
    st.isRecovering = true
    
    local recovered = false
    pcall(function()
        local c = P.Character
        if not c or not c:FindFirstChild("HumanoidRootPart") then return end
        
        local rt = c.HumanoidRootPart
        local h = c:FindFirstChild("Humanoid")
        if not h then return end
        
        if cfg.DEBUG_MODE then
            print("🔄 Attempting position recovery...")
        end
        
        -- Try saved position first
        if st.savedPos and validatePosition(st.savedPos) then
            h:ChangeState(Enum.HumanoidStateType.Physics)
            task.wait(0.1)
            rt.CFrame = st.savedPos
            task.wait(0.2)
            h:ChangeState(Enum.HumanoidStateType.Running)
            
            if (rt.Position - st.savedPos.Position).Magnitude < 5 then
                recovered = true
                st.positionLostCount = 0
                if cfg.DEBUG_MODE then print("✅ Position recovered!") end
                return
            end
        end
        
        -- Try finding new spot
        local bs, pc = fndBst(nil, rt.CFrame)
        if bs and validatePosition(bs) then
            h:ChangeState(Enum.HumanoidStateType.Physics)
            task.wait(0.1)
            rt.CFrame = bs
            task.wait(0.2)
            h:ChangeState(Enum.HumanoidStateType.Running)
            st.savedPos = bs
            recovered = true
            st.positionLostCount = 0
            if cfg.DEBUG_MODE then print("✅ Found new position!") end
        end
    end)
    
    st.isRecovering = false
    return recovered
end

-- Enhanced movement with recovery
local function mv()
    if not st.enabled or st.moving or st.relocating then return end
    st.moving = true
    
    local success = pcall(function()
        local c = P.Character
        if not c then return end
        
        local h = c:FindFirstChild("Humanoid")
        local rt = c:FindFirstChild("HumanoidRootPart")
        
        if not h or not rt or h.Health <= 0 then
            st.moving = false
            return
        end
        
        local og = st.savedPos or rt.CFrame
        if not validatePosition(og) then
            recoverPosition()
            st.moving = false
            return
        end
        
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus("Moving...", Color3.fromRGB(100, 150, 255))
        end
        
        -- Random jumps
        local jc = math.random(cfg.MIN_JUMPS, cfg.MAX_JUMPS)
        for i = 1, jc do
            h.Jump = true
            task.wait(cfg.JUMP_INTERVAL)
        end
        task.wait(0.15)
        
        -- Random walk
        local a = math.rad(math.random(0, 360))
        local d = math.random(cfg.MIN_WALK_DISTANCE, cfg.MAX_WALK_DISTANCE)
        local dr = Vector3.new(math.cos(a), 0, math.sin(a))
        local tp = og.Position + (dr * d)
        
        h.WalkSpeed = cfg.WALK_SPEED_NORMAL
        h:MoveTo(tp)
        task.wait(d / cfg.WALK_SPEED_NORMAL + 0.4)
        
        -- Return to position
        h.WalkSpeed = cfg.WALK_SPEED_FAST
        h:MoveTo(og.Position)
        task.wait((d / cfg.WALK_SPEED_FAST) + 0.3)
        task.wait(math.random(15, 35) / 10)
        
        -- Smooth return with tween
        h:ChangeState(Enum.HumanoidStateType.Physics)
        local tw = TS:Create(rt, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = og})
        tw:Play()
        tw.Completed:Wait()
        task.wait(0.15)
        
        -- Check position (with tolerance)
        local distance = (rt.Position - og.Position).Magnitude
        if distance > 3 then
            st.positionLostCount = st.positionLostCount + 1
            
            if cfg.DEBUG_MODE then
                print(string.format("⚠️ Position drift: %.1f studs (count: %d)", distance, st.positionLostCount))
            end
            
            if getgenv().MasploitzUI then
                getgenv().MasploitzUI.updateStatus("Position drift detected", Color3.fromRGB(255, 180, 100))
            end
            
            -- Attempt recovery instead of killing
            if st.positionLostCount >= 3 then
                if not recoverPosition() then
                    -- Find completely new spot
                    local bs = fndBst(rt.Position, rt.CFrame)
                    if bs then
                        rt.CFrame = bs
                        st.savedPos = bs
                        st.positionLostCount = 0
                    end
                end
            end
        else
            st.positionLostCount = 0
            st.lastSuccessfulMove = tick()
        end
        
        h:ChangeState(Enum.HumanoidStateType.Running)
        h.WalkSpeed = cfg.WALK_SPEED_NORMAL
        
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
        end
    end)
    
    if not success and cfg.DEBUG_MODE then
        print("❌ Movement error occurred")
    end
    
    st.moving = false
end

-- Enhanced relocation with pathfinding
local function rlc()
    if st.relocating or st.moving or st.isRecovering then return end
    
    local c = P.Character
    if not c or not c:FindFirstChild("HumanoidRootPart") or not c:FindFirstChild("Humanoid") then
        return
    end
    
    local rt = c.HumanoidRootPart
    local h = c.Humanoid
    
    if h.Health <= 0 then return end
    
    local fb = chkFrt(rt.CFrame)
    local tc = chkBlk(rt.Position)
    
    -- Immediate relocation if blocked
    if fb or tc then
        st.relocating = true
        
        if getgenv().MasploitzUI then
            local msg = fb and "Player in front! Relocating..." or "Too crowded! Moving..."
            getgenv().MasploitzUI.updateStatus(msg, Color3.fromRGB(255, 150, 50))
        end
        
        local bs, bc, np = fndBst(rt.Position, rt.CFrame)
        if bs and validatePosition(bs) then
            local moved = false
            
            -- Try pathfinding for complex routes
            if np or (rt.Position - bs.Position).Magnitude > 30 then
                local PFS = game:GetService("PathfindingService")
                local path = PFS:CreatePath({
                    AgentRadius = 2,
                    AgentHeight = 5,
                    AgentCanJump = true,
                    WaypointSpacing = 4
                })
                
                local ok = pcall(function()
                    path:ComputeAsync(rt.Position, bs.Position)
                end)
                
                if ok and path.Status == Enum.PathStatus.Success then
                    local waypoints = path:GetWaypoints()
                    for i, wp in pairs(waypoints) do
                        if not st.enabled then break end
                        if wp.Action == Enum.PathWaypointAction.Jump then
                            h.Jump = true
                        end
                        h:MoveTo(wp.Position)
                        local timeout = tick() + 5
                        repeat
                            task.wait()
                        until (rt.Position - wp.Position).Magnitude < 5 or tick() > timeout
                    end
                    moved = true
                else
                    -- Pathfinding failed, try direct
                    h:MoveTo(bs.Position)
                    task.wait(3)
                end
            else
                -- Direct movement for close distances
                h.WalkSpeed = cfg.WALK_SPEED_NORMAL
                h:MoveTo(bs.Position)
                task.wait((rt.Position - bs.Position).Magnitude / cfg.WALK_SPEED_NORMAL + 1.5)
                moved = true
            end
            
            if moved then
                h:ChangeState(Enum.HumanoidStateType.Physics)
                task.wait(0.1)
                rt.CFrame = bs
                task.wait(0.1)
                h:ChangeState(Enum.HumanoidStateType.Running)
                st.savedPos = bs
                
                if getgenv().MasploitzUI then
                    local msg = np and string.format("Found crowded spot! (%d)", bc) or "Relocated forward!"
                    getgenv().MasploitzUI.updateStatus(msg, Color3.fromRGB(100, 200, 255))
                end
                
                task.wait(2)
                if getgenv().MasploitzUI then
                    getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
                end
            end
        end
        
        st.relocating = false
        return
    end
    
    -- Opportunistic relocation to better spots
    local cc = cnt(rt.Position, cfg.PLAYER_RADIUS)
    local bs, bc, np = fndBst(rt.Position, rt.CFrame)
    
    if bs and bc > cc + 5 then
        st.relocating = true
        
        if getgenv().MasploitzUI then
            local msg = np and "Crowded area found! Moving..." or "Better spot available!"
            getgenv().MasploitzUI.updateStatus(msg, Color3.fromRGB(255, 200, 100))
        end
        
        -- Similar pathfinding logic
        if np then
            local PFS = game:GetService("PathfindingService")
            local path = PFS:CreatePath({
                AgentRadius = 2,
                AgentHeight = 5,
                AgentCanJump = true
            })
            
            local ok = pcall(function()
                path:ComputeAsync(rt.Position, bs.Position)
            end)
            
            if ok and path.Status == Enum.PathStatus.Success then
                for _, wp in pairs(path:GetWaypoints()) do
                    if not st.enabled then break end
                    if wp.Action == Enum.PathWaypointAction.Jump then h.Jump = true end
                    h:MoveTo(wp.Position)
                    local timeout = tick() + 5
                    repeat task.wait() until (rt.Position - wp.Position).Magnitude < 5 or tick() > timeout
                end
            end
        else
            h.WalkSpeed = cfg.WALK_SPEED_NORMAL
            h:MoveTo(bs.Position)
            task.wait((rt.Position - bs.Position).Magnitude / cfg.WALK_SPEED_NORMAL + 1)
        end
        
        h:ChangeState(Enum.HumanoidStateType.Physics)
        task.wait(0.1)
        rt.CFrame = bs
        task.wait(0.1)
        h:ChangeState(Enum.HumanoidStateType.Running)
        st.savedPos = bs
        
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus(string.format("Relocated! (%d players)", bc), Color3.fromRGB(100, 200, 255))
        end
        
        task.wait(2)
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
        end
        
        st.relocating = false
    end
end

-- Chat messages
local function cht()
    if not cfg.ENABLE_CHAT_MESSAGES then return end
    if tick() - st.lastChat < math.random(cfg.CHAT_INTERVAL_MIN, cfg.CHAT_INTERVAL_MAX) then return end
    
    pcall(function()
        local chatService = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
        if chatService then
            local sayEvent = chatService:FindFirstChild("SayMessageRequest")
            if sayEvent then
                local msg = cfg.CHAT_MESSAGES[math.random(1, #cfg.CHAT_MESSAGES)]
                sayEvent:FireServer(msg, "All")
                st.lastChat = tick()
            end
        end
    end)
end

-- Emotes
local function emt()
    if not cfg.ENABLE_EMOTES then return end
    if tick() - st.lastEmote < math.random(cfg.EMOTE_INTERVAL_MIN, cfg.EMOTE_INTERVAL_MAX) then return end
    
    pcall(function()
        local h = P.Character and P.Character:FindFirstChild("Humanoid")
        if h then
            local tracks = h:GetPlayingAnimationTracks()
            if #tracks > 0 then
                tracks[math.random(1, #tracks)]:Stop()
            end
        end
        st.lastEmote = tick()
    end)
end

-- Camera movement
local function cam()
    if not cfg.ENABLE_CAMERA_MOVE then return end
    if tick() - st.lastCamera < math.random(cfg.CAMERA_INTERVAL_MIN, cfg.CAMERA_INTERVAL_MAX) then return end
    
    pcall(function()
        local cm = workspace.CurrentCamera
        if cm and cm.CameraType == Enum.CameraType.Custom then
            local ccf = cm.CFrame
            local off = CFrame.Angles(
                math.rad(math.random(-15, 15)),
                math.rad(math.random(-25, 25)),
                0
            )
            TS:Create(cm, TweenInfo.new(2.5, Enum.EasingStyle.Quad), {CFrame = ccf * off}):Play()
        end
        st.lastCamera = tick()
    end)
end

-- Enhanced re-equip
local function reEq()
    if not cfg.AUTO_RE_EQUIP then return end
    
    pcall(function()
        local c = P.Character
        if not c then return end
        
        local h = c:FindFirstChild("Humanoid")
        if not h then return end
        
        -- Check if tool already equipped
        if c:FindFirstChild(cfg.AUTO_EQUIP_TOOL) then return end
        
        local bp = P:FindFirstChild("Backpack")
        if not bp then return end
        
        local t = bp:FindFirstChild(cfg.AUTO_EQUIP_TOOL)
        if t then
            h:EquipTool(t)
            
            if getgenv().MasploitzUI then
                getgenv().MasploitzUI.updateStatus("Tool re-equipped", Color3.fromRGB(100, 255, 150))
                task.wait(1.5)
                getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
            end
        end
    end)
end

-- Anti-AFK kick prevention
local vu = game:GetService('VirtualUser')
P.Idled:Connect(function()
    if st.enabled then
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
        
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus("AFK Kick Prevented!", Color3.fromRGB(255, 200, 0))
            task.wait(2)
            getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
        end
    end
end)

-- Main loops with better timing
task.spawn(function()
    while task.wait(math.random(cfg.RANDOM_MOVE_MIN, cfg.RANDOM_MOVE_MAX)) do
        if st.enabled and not st.relocating then
            mv()
        end
    end
end)

task.spawn(function()
    while task.wait(cfg.REGULAR_MOVE_INTERVAL) do
        if st.enabled and P.Character and not st.relocating then
            mv()
        end
    end
end)

task.spawn(function()
    while task.wait(math.random(cfg.MICRO_MOVE_MIN, cfg.MICRO_MOVE_MAX)) do
        if st.enabled then
            pcall(function()
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(cfg.SPOT_CHECK_INTERVAL) do
        if st.enabled and not st.relocating and not st.moving then
            rlc()
        end
    end
end)

task.spawn(function()
    while task.wait(cfg.BLOCK_CHECK_INTERVAL) do
        if st.enabled and not st.relocating and not st.moving then
            local c = P.Character
            if c and c:FindFirstChild("HumanoidRootPart") then
                local rt = c.HumanoidRootPart
                if chkFrt(rt.CFrame) or chkBlk(rt.Position) then
                    rlc()
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(12) do
        if st.enabled then
            cht()
            emt()
            cam()
        end
    end
end)

task.spawn(function()
    while task.wait(cfg.RE_EQUIP_INTERVAL) do
        if st.enabled and cfg.AUTO_RE_EQUIP then
            reEq()
        end
    end
end)

task.spawn(function()
    task.wait(cfg.AUTO_HOP_TIME)
    task.wait(2)
    serverHop()
end)

-- Character respawn handling
P.CharacterAdded:Connect(function(character)
    task.wait(2)
    
    if st.savedPos and st.enabled and validatePosition(st.savedPos) then
        local rt = character:WaitForChild("HumanoidRootPart", 5)
        if rt then
            pcall(function()
                rt.CFrame = st.savedPos
                if getgenv().MasploitzUI then
                    getgenv().MasploitzUI.updateStatus("Respawned at saved position", Color3.fromRGB(100, 200, 255))
                end
                task.wait(2)
            end)
        end
    end
    
    -- Try to equip tool
    task.spawn(function()
        task.wait(1)
        for i = 1, 10 do
            if eq() then break end
            task.wait(0.5)
        end
    end)
    
    if st.enabled and getgenv().MasploitzUI then
        getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
    end
end)

-- Initial spawn setup
task.spawn(function()
    repeat task.wait() until P.Character and P.Character:FindFirstChild("HumanoidRootPart")
    task.wait(1)
    
    local bs, pc, np = fndBst(nil, nil)
    
    if not bs or not validatePosition(bs) then
        bs = faceCtr(cfg.SPAWN_POSITIONS[math.random(1, #cfg.SPAWN_POSITIONS)])
        pc = 0
        np = false
    end
    
    -- Pathfind to initial spot if crowded
    if np and P.Character and P.Character:FindFirstChild("Humanoid") then
        local h = P.Character.Humanoid
        local rt = P.Character.HumanoidRootPart
        
        local PFS = game:GetService("PathfindingService")
        local path = PFS:CreatePath()
        
        local ok = pcall(function()
            path:ComputeAsync(rt.Position, bs.Position)
        end)
        
        if ok and path.Status == Enum.PathStatus.Success then
            for _, wp in pairs(path:GetWaypoints()) do
                if wp.Action == Enum.PathWaypointAction.Jump then
                    h.Jump = true
                end
                h:MoveTo(wp.Position)
                local timeout = tick() + 5
                repeat task.wait() until (rt.Position - wp.Position).Magnitude < 5 or tick() > timeout
            end
        end
    end
    
    -- Set initial position
    if P.Character and P.Character:FindFirstChild("HumanoidRootPart") then
        P.Character.HumanoidRootPart.CFrame = bs
        st.savedPos = bs
    end
    
    -- Wait for UI
    for i = 1, 20 do
        if getgenv().MasploitzUI then break end
        task.wait(0.1)
    end
    
    if getgenv().MasploitzUI then
        local msg = np and string.format("Crowded area! (%d players)", pc) or string.format("Positioned (%d players)", pc)
        getgenv().MasploitzUI.updateStatus(msg, Color3.fromRGB(100, 200, 255))
        task.spawn(function()
            getgenv().MasploitzUI.showSavedPos()
        end)
    end
    
    task.wait(1)
    eq()
    task.wait(2)
    
    if getgenv().MasploitzUI then
        getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
    end
end)

print("✅ Masploitz Backend Enhanced (No Kill) - Initialized")

-- Exposed API
getgenv().MasploitzFunctions = {
    serverHop = serverHop,
    savePosition = function()
        local c = P.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            local pos = c.HumanoidRootPart.CFrame
            if validatePosition(pos) then
                st.savedPos = pos
                st.positionLostCount = 0
                return true
            end
        end
        return false
    end,
    toggleEnabled = function()
        st.enabled = not st.enabled
        return st.enabled
    end,
    reEquipTool = reEq,
    recoverPosition = recoverPosition,
    getState = function()
        return {
            enabled = st.enabled,
            moving = st.moving,
            relocating = st.relocating,
            positionLostCount = st.positionLostCount,
            hasSavedPosition = st.savedPos ~= nil,
            animationActive = st.animationActive
        }
    end
}
