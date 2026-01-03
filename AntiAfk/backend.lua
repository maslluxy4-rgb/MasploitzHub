-- Masploitz Anti-AFK Backend
-- Handles all anti-AFK logic and automation

-- Check game ID
if game.PlaceId ~= getgenv().MasploitzConfig.GAME_ID then
    warn("Masploitz Anti-AFK: Wrong game!")
    return
end

local cfg = getgenv().MasploitzConfig
local TS = game:GetService("TweenService")
local P = game:GetService("Players").LocalPlayer
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Math clamp helper
local function clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

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

local state = getgenv().MasploitzState

-- Create CFrame facing center (0,0,0)
local function createCFrameFacingCenter(pos)
    local center = Vector3.new(0, pos.Y, 0) -- Keep same Y level
    local lookVector = (center - pos).Unit
    return CFrame.new(pos, pos + lookVector)
end

-- Server Hop
local function serverHop()
    local success = pcall(function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        local server = nil
        
        for i, v in pairs(servers.data) do
            if v.id ~= game.JobId and v.playing >= cfg.MIN_PLAYERS and v.playing < v.maxPlayers - 1 then
                server = v
                break
            end
        end
        
        if server then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, P)
        else
            TeleportService:Teleport(game.PlaceId, P)
        end
    end)
    
    if not success then
        TeleportService:Teleport(game.PlaceId, P)
    end
end

-- Check player count on join
spawn(function()
    wait(5)
    if #game.Players:GetPlayers() < cfg.MIN_PLAYERS then
        wait(2)
        serverHop()
    end
end)

-- Auto Equip Tool
local function equipTool()
    local backpack = P:WaitForChild("Backpack", cfg.TOOL_WAIT_TIMEOUT)
    local tool = backpack:WaitForChild(cfg.AUTO_EQUIP_TOOL, cfg.TOOL_WAIT_TIMEOUT)
    
    if tool then
        P.Character:WaitForChild("Humanoid"):EquipTool(tool)
        return true
    end
    return false
end

-- Count players near position
local function countPlayersNear(pos, radius)
    local count = 0
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= P and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (player.Character.HumanoidRootPart.Position - pos).Magnitude
            if dist <= radius then
                count = count + 1
            end
        end
    end
    return count
end

-- Check if player in front (45 degree cone, 15 studs)
local function isPlayerInFront(cf)
    local lookVector = cf.LookVector
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= P and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = player.Character.HumanoidRootPart.Position
            local dirToTarget = (targetPos - cf.Position).Unit
            local dist = (targetPos - cf.Position).Magnitude
            
            if dist <= cfg.FRONT_CHECK_DISTANCE then
                local angle = math.acos(clamp(lookVector:Dot(dirToTarget), -1, 1))
                if math.deg(angle) <= cfg.FRONT_CHECK_ANGLE then
                    if cfg.DEBUG_MODE then
                        print("⚠️ Player in front detected:", player.Name, "at", math.floor(dist), "studs,", math.floor(math.deg(angle)), "degrees")
                    end
                    return true
                end
            end
        end
    end
    return false
end

-- Check if player blocking (360 degrees, 10 studs - anyone too close)
local function isPlayerBlocking(pos)
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= P and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = player.Character.HumanoidRootPart.Position
            local dist = (targetPos - pos).Magnitude
            
            if dist <= cfg.BLOCK_CHECK_DISTANCE then
                if cfg.DEBUG_MODE then
                    print("🔴 Player too close detected:", player.Name, "at", math.floor(dist), "studs")
                end
                return true
            end
        end
    end
    return false
end

-- Generate positions around a point in a circle
local function generateNearbyPositions(center, radius, count)
    local positions = {}
    for i = 1, count do
        local angle = (math.pi * 2 / count) * i
        local offset = Vector3.new(
            math.cos(angle) * radius,
            0,
            math.sin(angle) * radius
        )
        table.insert(positions, center + offset)
    end
    return positions
end

-- Find best nearby position around a crowded spot
local function findBestNearbySpot(crowdedPos, crowdedCF)
    local bestPos = nil
    local maxPlayers = 0
    local bestCF = nil
    
    if cfg.DEBUG_MODE then
        print("🔍 Searching for positions near crowded spot...")
    end
    
    -- Try different distances from crowded spot
    for radius = 5, 15, 5 do
        local nearbyPositions = generateNearbyPositions(crowdedPos, radius, 8)
        
        for _, pos in pairs(nearbyPositions) do
            -- Create CFrame facing the center (0,0,0)
            local testCF = createCFrameFacingCenter(pos)
            
            -- Check if this position is clear (no one in front AND no one too close)
            if not isPlayerInFront(testCF) and not isPlayerBlocking(pos) then
                local playerCount = countPlayersNear(pos, cfg.PLAYER_RADIUS)
                if playerCount > maxPlayers then
                    maxPlayers = playerCount
                    bestPos = pos
                    bestCF = testCF
                    
                    if cfg.DEBUG_MODE then
                        print("  ✅ Found spot at", radius, "studs with", playerCount, "players")
                    end
                end
            end
        end
        
        -- If we found a good spot, use it
        if bestPos and maxPlayers > 5 then
            if cfg.DEBUG_MODE then
                print("  ✨ Selected best nearby spot with", maxPlayers, "players")
            end
            break
        end
    end
    
    return bestCF, maxPlayers
end

-- Find best spawn with smart crowded spot handling
local function findBestSpot(excludePos)
    local bestClearSpot = nil
    local maxClearPlayers = 0
    local crowdedSpot = nil
    local maxCrowdedPlayers = 0
    local crowdedCF = nil
    
    -- First pass: find best clear spot AND most crowded spot
    for _, spawnPos in pairs(cfg.SPAWN_POSITIONS) do
        local spawnCF = createCFrameFacingCenter(spawnPos)
        
        if not excludePos or (spawnCF.Position - excludePos).Magnitude > 5 then
            local playerCount = countPlayersNear(spawnCF.Position, cfg.PLAYER_RADIUS)
            local noFront = not isPlayerInFront(spawnCF)
            local noBlock = not isPlayerBlocking(spawnCF.Position)
            local isClear = noFront and noBlock
            
            -- Track best clear spot
            if isClear and playerCount > maxClearPlayers then
                maxClearPlayers = playerCount
                bestClearSpot = spawnCF
            end
            
            -- Track most crowded spot (even if blocked)
            if playerCount > maxCrowdedPlayers then
                maxCrowdedPlayers = playerCount
                crowdedSpot = spawnCF.Position
                crowdedCF = spawnCF
            end
        end
    end
    
    -- If crowded spot has significantly more players (like 20 vs 3-5)
    if crowdedSpot and maxCrowdedPlayers > maxClearPlayers + 10 then
        if cfg.DEBUG_MODE then
            print("🔍 Found crowded spot with", maxCrowdedPlayers, "players vs best clear", maxClearPlayers)
        end
        
        -- Try to find a nearby position around the crowded spot
        local nearbySpot, nearbyCount = findBestNearbySpot(crowdedSpot, crowdedCF)
        
        if nearbySpot and nearbyCount > maxClearPlayers then
            if cfg.DEBUG_MODE then
                print("✅ Found nearby spot with", nearbyCount, "players - using pathfinding!")
            end
            return nearbySpot, nearbyCount, true -- true = needs pathfinding
        end
    end
    
    return bestClearSpot, maxClearPlayers, false
end

-- Check position validity
local function checkPos(root, target)
    return (root.Position - target.Position).Magnitude < 1
end

-- Kill character
local function killChar()
    if P.Character and P.Character:FindFirstChild("Humanoid") then
        P.Character.Humanoid.Health = 0
    end
end

-- Main movement function
local function move()
    if not state.enabled or state.moving or state.relocating then return end
    state.moving = true
    
    pcall(function()
        local c = P.Character
        if not c then return end
        local hum = c:FindFirstChild("Humanoid")
        local root = c:FindFirstChild("HumanoidRootPart")
        if not hum or not root or hum.Health <= 0 then state.moving = false return end
        
        local orig = state.savedPos or root.CFrame
        if not orig then state.moving = false return end
        
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus("Moving...", Color3.fromRGB(100, 150, 255))
        end
        
        -- Jumps
        local jc = math.random(cfg.MIN_JUMPS, cfg.MAX_JUMPS)
        for i = 1, jc do
            hum.Jump = true
            wait(cfg.JUMP_INTERVAL)
        end
        
        wait(0.1)
        
        -- Walk out
        local ang = math.rad(math.random(0, 360))
        local dist = math.random(cfg.MIN_WALK_DISTANCE, cfg.MAX_WALK_DISTANCE)
        local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
        local tpos = orig.Position + (dir * dist)
        
        hum.WalkSpeed = cfg.WALK_SPEED_NORMAL
        hum:MoveTo(tpos)
        
        wait(dist / cfg.WALK_SPEED_NORMAL + 0.3)
        
        -- Walk back fast
        hum.WalkSpeed = cfg.WALK_SPEED_FAST
        hum:MoveTo(orig.Position)
        
        wait((dist / cfg.WALK_SPEED_FAST) + 0.2)
        
        -- Wait before rotation
        wait(math.random(10, 30) / 10)
        
        -- Smooth rotation
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        
        local tw = TS:Create(root, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = orig})
        tw:Play()
        tw.Completed:Wait()
        
        wait(0.1)
        
        -- Verify position
        if not checkPos(root, orig) then
            if getgenv().MasploitzUI then
                getgenv().MasploitzUI.updateStatus("Position lost! Resetting...", Color3.fromRGB(255, 100, 100))
            end
            wait(0.5)
            killChar()
            state.moving = false
            return
        end
        
        hum:ChangeState(Enum.HumanoidStateType.Running)
        hum.WalkSpeed = cfg.WALK_SPEED_NORMAL
        
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
        end
    end)
    
    state.moving = false
end

-- Relocate to better spot
local function relocate()
    if state.relocating or state.moving then return end
    
    local c = P.Character
    if not c or not c:FindFirstChild("HumanoidRootPart") or not c:FindFirstChild("Humanoid") then return end
    
    local root = c.HumanoidRootPart
    local hum = c.Humanoid
    
    -- Check if someone is in front (45 degree cone, 15 studs)
    local frontBlocked = isPlayerInFront(root.CFrame)
    -- Check if someone is too close (360 degrees, 10 studs)
    local tooClose = isPlayerBlocking(root.Position)
    
    if frontBlocked or tooClose then
        state.relocating = true
        
        if getgenv().MasploitzUI then
            local msg = frontBlocked and "Player in front! Finding new spot..." or "Player too close! Relocating..."
            getgenv().MasploitzUI.updateStatus(msg, Color3.fromRGB(255, 150, 50))
        end
        
        local bestSpot, bestCount, needsPath = findBestSpot(root.Position)
        
        if bestSpot then
            local PathfindingService = game:GetService("PathfindingService")
            local path = PathfindingService:CreatePath()
            
            local success = pcall(function()
                path:ComputeAsync(root.Position, bestSpot.Position)
            end)
            
            if success and path.Status == Enum.PathStatus.Success then
                local waypoints = path:GetWaypoints()
                
                for _, waypoint in pairs(waypoints) do
                    if waypoint.Action == Enum.PathWaypointAction.Jump then
                        hum.Jump = true
                    end
                    hum:MoveTo(waypoint.Position)
                    hum.MoveToFinished:Wait()
                end
            else
                hum:MoveTo(bestSpot.Position)
                wait(3)
            end
            
            root.CFrame = bestSpot
            state.savedPos = bestSpot
            
            if getgenv().MasploitzUI then
                if needsPath then
                    getgenv().MasploitzUI.updateStatus("Found crowded area! (" .. bestCount .. " players)", Color3.fromRGB(100, 200, 255))
                else
                    getgenv().MasploitzUI.updateStatus("Moved to clear spot!", Color3.fromRGB(100, 200, 255))
                end
            end
            wait(2)
            if getgenv().MasploitzUI then
                getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
            end
        end
        
        state.relocating = false
        return
    end
    
    -- Check for better spots (including crowded ones)
    local currentCount = countPlayersNear(root.Position, cfg.PLAYER_RADIUS)
    local bestSpot, bestCount, needsPath = findBestSpot(root.Position)
    
    if bestSpot and bestCount > currentCount + 2 then
        state.relocating = true
        
        if getgenv().MasploitzUI then
            if needsPath then
                getgenv().MasploitzUI.updateStatus("Found crowded spot! Pathfinding...", Color3.fromRGB(255, 200, 100))
            else
                getgenv().MasploitzUI.updateStatus("Found busier spot! Moving...", Color3.fromRGB(255, 200, 100))
            end
        end
        
        if needsPath then
            -- Use pathfinding for crowded spots
            local PathfindingService = game:GetService("PathfindingService")
            local path = PathfindingService:CreatePath()
            
            local success = pcall(function()
                path:ComputeAsync(root.Position, bestSpot.Position)
            end)
            
            if success and path.Status == Enum.PathStatus.Success then
                local waypoints = path:GetWaypoints()
                
                for _, waypoint in pairs(waypoints) do
                    if waypoint.Action == Enum.PathWaypointAction.Jump then
                        hum.Jump = true
                    end
                    hum:MoveTo(waypoint.Position)
                    hum.MoveToFinished:Wait()
                end
            else
                hum:MoveTo(bestSpot.Position)
                wait(3)
            end
        else
            -- Direct walk for normal spots
            hum.WalkSpeed = cfg.WALK_SPEED_NORMAL
            hum:MoveTo(bestSpot.Position)
            
            local dist = (root.Position - bestSpot.Position).Magnitude
            wait(dist / cfg.WALK_SPEED_NORMAL + 1)
        end
        
        root.CFrame = bestSpot
        state.savedPos = bestSpot
        
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus("Relocated! (" .. bestCount .. " nearby)", Color3.fromRGB(100, 200, 255))
        end
        wait(2)
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
        end
        
        state.relocating = false
    end
end

-- NEW: Random chat messages
local function sendChat()
    if cfg.ENABLE_CHAT_MESSAGES and tick() - state.lastChat > math.random(cfg.CHAT_INTERVAL_MIN, cfg.CHAT_INTERVAL_MAX) then
        pcall(function()
            local msg = cfg.CHAT_MESSAGES[math.random(1, #cfg.CHAT_MESSAGES)]
            game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
            state.lastChat = tick()
        end)
    end
end

-- NEW: Random emotes
local function playEmote()
    if cfg.ENABLE_EMOTES and tick() - state.lastEmote > math.random(cfg.EMOTE_INTERVAL_MIN, cfg.EMOTE_INTERVAL_MAX) then
        local hum = P.Character and P.Character:FindFirstChild("Humanoid")
        if hum then
            local emotes = hum:GetPlayingAnimationTracks()
            if #emotes > 0 then
                emotes[1]:Stop()
            end
        end
        state.lastEmote = tick()
    end
end

-- NEW: Camera movement
local function moveCamera()
    if cfg.ENABLE_CAMERA_MOVE and tick() - state.lastCamera > math.random(cfg.CAMERA_INTERVAL_MIN, cfg.CAMERA_INTERVAL_MAX) then
        local cam = workspace.CurrentCamera
        if cam then
            local currentCF = cam.CFrame
            local offset = CFrame.Angles(math.rad(math.random(-10, 10)), math.rad(math.random(-20, 20)), 0)
            
            local tween = TS:Create(cam, TweenInfo.new(2, Enum.EasingStyle.Quad), {CFrame = currentCF * offset})
            tween:Play()
        end
        state.lastCamera = tick()
    end
end

-- Anti-AFK
local vu = game:GetService('VirtualUser')

P.Idled:Connect(function()
    if state.enabled then
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus("Kick Blocked!", Color3.fromRGB(255, 200, 0))
        end
        wait(2)
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
        end
    end
end)

-- Movement loops
spawn(function() while wait(math.random(cfg.RANDOM_MOVE_MIN, cfg.RANDOM_MOVE_MAX)) do if state.enabled then move() end end end)
spawn(function() while wait(cfg.REGULAR_MOVE_INTERVAL) do if state.enabled and P.Character then move() end end end)
spawn(function() while wait(math.random(cfg.MICRO_MOVE_MIN, cfg.MICRO_MOVE_MAX)) do if state.enabled then pcall(function() vu:CaptureController() vu:ClickButton2(Vector2.new()) end) end end end)

-- Spot checks
spawn(function() while wait(cfg.SPOT_CHECK_INTERVAL) do if state.enabled and not state.relocating and not state.moving then relocate() end end end)
spawn(function() 
    while wait(cfg.BLOCK_CHECK_INTERVAL) do 
        if state.enabled and not state.relocating and not state.moving then 
            local c = P.Character 
            if c and c:FindFirstChild("HumanoidRootPart") then 
                -- Check both front blocking and proximity blocking
                if isPlayerInFront(c.HumanoidRootPart.CFrame) or isPlayerBlocking(c.HumanoidRootPart.Position) then 
                    relocate() 
                end 
            end 
        end 
    end 
end)

-- NEW: Anti-detection features
spawn(function() while wait(10) do if state.enabled then sendChat() playEmote() moveCamera() end end end)

-- Auto hop
spawn(function()
    wait(cfg.AUTO_HOP_TIME)
    wait(2)
    serverHop()
end)

-- Character handling
P.CharacterAdded:Connect(function()
    wait(2)
    if state.savedPos and state.enabled then
        local c = P.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            c.HumanoidRootPart.CFrame = state.savedPos
            if getgenv().MasploitzUI then
                getgenv().MasploitzUI.updateStatus("Respawned at AFK Pos", Color3.fromRGB(100, 200, 255))
            end
            wait(2)
        end
    end
    
    spawn(function()
        wait(1)
        for i = 1, 10 do
            if equipTool() then break end
            wait(0.5)
        end
    end)
    
    if state.enabled and getgenv().MasploitzUI then
        getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
    end
end)

-- Initial spawn
-- Initial spawn
spawn(function()
    repeat wait() until P.Character and P.Character:FindFirstChild("HumanoidRootPart")
    wait(1)
    
    local bestSpot, playerCount, needsPath = findBestSpot(nil)
    
    if not bestSpot then
        local randomPos = cfg.SPAWN_POSITIONS[math.random(1, #cfg.SPAWN_POSITIONS)]
        bestSpot = createCFrameFacingCenter(randomPos)
        playerCount = 0
        needsPath = false
    end
    
    -- If we need pathfinding, walk there first
    if needsPath and P.Character and P.Character:FindFirstChild("Humanoid") then
        local hum = P.Character.Humanoid
        local root = P.Character.HumanoidRootPart
        
        if cfg.DEBUG_MODE then
            print("🚶 Using pathfinding to reach crowded area...")
        end
        
        local PathfindingService = game:GetService("PathfindingService")
        local path = PathfindingService:CreatePath()
        
        local success = pcall(function()
            path:ComputeAsync(root.Position, bestSpot.Position)
        end)
        
        if success and path.Status == Enum.PathStatus.Success then
            local waypoints = path:GetWaypoints()
            
            for _, waypoint in pairs(waypoints) do
                if waypoint.Action == Enum.PathWaypointAction.Jump then
                    hum.Jump = true
                end
                hum:MoveTo(waypoint.Position)
                hum.MoveToFinished:Wait()
            end
        end
    end
    
    P.Character.HumanoidRootPart.CFrame = bestSpot
    state.savedPos = bestSpot
    
    -- Wait for UI to load
    for i = 1, 20 do
        if getgenv().MasploitzUI then break end
        wait(0.1)
    end
    
    if getgenv().MasploitzUI then
        local statusMsg = needsPath and 
            "Found crowded area! (" .. playerCount .. " nearby)" or
            "Spawned at best spot (" .. playerCount .. " nearby)"
        getgenv().MasploitzUI.updateStatus(statusMsg, Color3.fromRGB(100, 200, 255))
        spawn(function()
            getgenv().MasploitzUI.showSavedPos()
        end)
    end
    
    if cfg.DEBUG_MODE then
        print("📍 Initial spawn - Players nearby:", playerCount, "| Pathfinding used:", needsPath)
    end
    
    wait(1)
    equipTool()
    
    wait(2)
    if getgenv().MasploitzUI then
        getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
    end
end)

print("✅ Masploitz Backend initialized")

-- Expose functions for UI
getgenv().MasploitzFunctions = {
    serverHop = serverHop,
    savePosition = function()
        local c = P.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            state.savedPos = c.HumanoidRootPart.CFrame
            return true
        end
        return false
    end,
    toggleEnabled = function()
        state.enabled = not state.enabled
        return state.enabled
    end
}
