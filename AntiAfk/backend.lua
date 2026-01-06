-- Masploitz Anti-AFK Backend (Improved - No Tweening)
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
    lastValidation = tick(),
    consecutiveFailures = 0,
    isRespawning = false
}
local st = getgenv().MasploitzState

-- Animation System
local toolAnim = nil
local animTrack = nil

local function ensureToolAnim()
    local c = P.Character
    if not c then return end
    
    local hum = c:FindFirstChild("Humanoid")
    if not hum or hum.RigType ~= Enum.HumanoidRigType.R15 then return end
    
    if animTrack and animTrack.IsPlaying then return end
    
    local success = pcall(function()
        if not toolAnim then
            toolAnim = Instance.new("Animation")
            toolAnim.AnimationId = "rbxassetid://507768375"
        end
        
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            animTrack = animator:LoadAnimation(toolAnim)
            animTrack.Looped = true
            animTrack.Priority = Enum.AnimationPriority.Action
            animTrack:Play(0.1, 1, 1)
            
            if cfg.DEBUG_MODE then
                print("🎬 Animation started")
            end
        end
    end)
    
    if not success and cfg.DEBUG_MODE then
        print("⚠️ Animation load failed")
    end
end

-- Animation loop with proper yielding
task.spawn(function()
    while true do
        task.wait(5)
        if st.enabled and not st.isRespawning then
            ensureToolAnim()
        end
    end
end)

-- Utility Functions
local function clamp(v, mn, mx)
    return math.max(mn, math.min(mx, v))
end

local function getCharacterParts()
    local c = P.Character
    if not c then return nil, nil, nil end
    
    local hum = c:FindFirstChild("Humanoid")
    local root = c:FindFirstChild("HumanoidRootPart")
    
    if hum and hum.Health > 0 and root then
        return c, hum, root
    end
    return nil, nil, nil
end

local function isValidPosition(pos)
    if not pos then return false end
    
    -- Check for NaN or infinite values
    if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z then return false end
    if math.abs(pos.X) == math.huge or math.abs(pos.Y) == math.huge or math.abs(pos.Z) == math.huge then
        return false
    end
    
    -- Check if position is within reasonable bounds
    if math.abs(pos.Y) > 10000 then return false end
    
    return true
end

local function createLookAtCFrame(pos)
    if not isValidPosition(pos) then return nil end
    
    local center = Vector3.new(0, pos.Y, 0)
    local lookVec = (center - pos).Unit
    
    -- Ensure look vector is valid
    if lookVec.X ~= lookVec.X then
        lookVec = Vector3.new(0, 0, -1)
    end
    
    return CFrame.new(pos, pos + lookVec)
end

-- Server Hopping with better error handling
local function serverHop()
    local success, err = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local response = game:HttpGet(url)
        local data = HTTP:JSONDecode(response)
        
        if not data or not data.data then
            TPS:Teleport(game.PlaceId, P)
            return
        end
        
        local validServers = {}
        for _, server in pairs(data.data) do
            if server.id ~= game.JobId and 
               server.playing >= cfg.MIN_PLAYERS and 
               server.playing < server.maxPlayers - 2 then
                table.insert(validServers, server)
            end
        end
        
        if #validServers > 0 then
            local chosen = validServers[math.random(1, #validServers)]
            TPS:TeleportToPlaceInstance(game.PlaceId, chosen.id, P)
        else
            TPS:Teleport(game.PlaceId, P)
        end
    end)
    
    if not success then
        wait(1)
        TPS:Teleport(game.PlaceId, P)
    end
end

-- Player count check with delay
task.spawn(function()
    task.wait(8)
    if #game.Players:GetPlayers() < cfg.MIN_PLAYERS then
        if cfg.DEBUG_MODE then
            print("⚠️ Server underpopulated, switching...")
        end
        task.wait(2)
        serverHop()
    end
end)

-- Tool Management
local function equipTool()
    local c, hum, root = getCharacterParts()
    if not c or not hum then return false end
    
    local success = pcall(function()
        local bp = P:WaitForChild("Backpack", cfg.TOOL_WAIT_TIMEOUT)
        if not bp then return end
        
        local tool = bp:FindFirstChild(cfg.AUTO_EQUIP_TOOL)
        if tool then
            hum:EquipTool(tool)
            task.wait(0.3)
            return true
        end
    end)
    
    return success or false
end

-- Player Detection System
local function countNearbyPlayers(pos, radius)
    if not isValidPosition(pos) then return 0 end
    
    local count = 0
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= P and player.Character then
            local theirRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if theirRoot and isValidPosition(theirRoot.Position) then
                local dist = (theirRoot.Position - pos).Magnitude
                if dist <= radius then
                    count = count + 1
                end
            end
        end
    end
    return count
end

local function checkPlayerInFront(cf, maxDist, maxAngle)
    if not cf then return false end
    
    local lookVec = cf.LookVector
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= P and player.Character then
            local theirRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if theirRoot and isValidPosition(theirRoot.Position) then
                local targetPos = theirRoot.Position
                local dirToTarget = (targetPos - cf.Position).Unit
                local dist = (targetPos - cf.Position).Magnitude
                
                if dist <= maxDist then
                    local dotProduct = clamp(lookVec:Dot(dirToTarget), -1, 1)
                    local angle = math.deg(math.acos(dotProduct))
                    
                    -- Only consider players in front (angle < 90)
                    if angle <= maxAngle and angle < 90 then
                        if cfg.DEBUG_MODE then
                            print("⚠️ Player detected:", player.Name, math.floor(dist), "studs,", math.floor(angle), "°")
                        end
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function checkPlayerTooClose(pos, minDist)
    if not isValidPosition(pos) then return true end
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= P and player.Character then
            local theirRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if theirRoot and isValidPosition(theirRoot.Position) then
                local dist = (theirRoot.Position - pos).Magnitude
                if dist <= minDist then
                    if cfg.DEBUG_MODE then
                        print("🔴 Player too close:", player.Name, math.floor(dist), "studs")
                    end
                    return true
                end
            end
        end
    end
    return false
end

-- Position Generation (forward-facing)
local function generateForwardPositions(center, radius, count, currentCF)
    if not isValidPosition(center) then return {} end
    
    local positions = {}
    local baseLook = currentCF and currentCF.LookVector or Vector3.new(0, 0, -1)
    local baseAngle = math.atan2(baseLook.Z, baseLook.X)
    
    -- Generate positions in a forward arc (±90 degrees)
    for i = 1, count do
        local offset = (i / count) * math.pi - (math.pi / 2)
        local angle = baseAngle + offset
        local offsetVec = Vector3.new(
            math.cos(angle) * radius,
            0,
            math.sin(angle) * radius
        )
        
        local pos = center + offsetVec
        if isValidPosition(pos) then
            table.insert(positions, pos)
        end
    end
    
    return positions
end

-- Find nearby forward spot
local function findNearbySpot(currentPos, currentCF)
    if not isValidPosition(currentPos) or not currentCF then return nil, 0 end
    
    local bestPos = nil
    local maxPlayers = 0
    local bestCF = nil
    
    if cfg.DEBUG_MODE then
        print("🔍 Searching forward positions...")
    end
    
    for radius = 5, 20, 5 do
        local positions = generateForwardPositions(currentPos, radius, 12, currentCF)
        
        for _, pos in pairs(positions) do
            local testCF = createLookAtCFrame(pos)
            if testCF then
                local hasPlayerInFront = checkPlayerInFront(testCF, cfg.FRONT_CHECK_DISTANCE, cfg.FRONT_CHECK_ANGLE)
                local playerTooClose = checkPlayerTooClose(pos, cfg.BLOCK_CHECK_DISTANCE)
                
                if not hasPlayerInFront and not playerTooClose then
                    local playerCount = countNearbyPlayers(pos, cfg.PLAYER_RADIUS)
                    if playerCount > maxPlayers then
                        maxPlayers = playerCount
                        bestPos = pos
                        bestCF = testCF
                        
                        if cfg.DEBUG_MODE then
                            print("  ✅ Good spot at", radius, "studs,", playerCount, "nearby")
                        end
                    end
                end
            end
        end
        
        if bestPos and maxPlayers > 5 then break end
    end
    
    return bestCF, maxPlayers
end

-- Find best spawn position
local function findBestSpot(excludePos, currentCF)
    local bestClearSpot = nil
    local maxClearPlayers = 0
    local crowdedSpot = nil
    local maxCrowdedPlayers = 0
    local crowdedCF = nil
    
    for _, spawnPos in pairs(cfg.SPAWN_POSITIONS) do
        if isValidPosition(spawnPos) then
            local spawnCF = createLookAtCFrame(spawnPos)
            if spawnCF then
                -- Skip if too close to exclude position
                if excludePos and (spawnPos - excludePos).Magnitude <= 5 then
                    continue
                end
                
                local playerCount = countNearbyPlayers(spawnPos, cfg.PLAYER_RADIUS)
                local hasPlayerInFront = checkPlayerInFront(spawnCF, cfg.FRONT_CHECK_DISTANCE, cfg.FRONT_CHECK_ANGLE)
                local playerTooClose = checkPlayerTooClose(spawnPos, cfg.BLOCK_CHECK_DISTANCE)
                
                -- Track crowded spots separately
                if playerCount > maxCrowdedPlayers then
                    maxCrowdedPlayers = playerCount
                    crowdedSpot = spawnPos
                    crowdedCF = spawnCF
                end
                
                -- Only consider clear spots for immediate use
                if not hasPlayerInFront and not playerTooClose then
                    if playerCount > maxClearPlayers then
                        maxClearPlayers = playerCount
                        bestClearSpot = spawnCF
                    end
                end
            end
        end
    end
    
    -- If crowded spot has significantly more players, find a nearby clear spot
    if crowdedSpot and maxCrowdedPlayers > maxClearPlayers + 10 then
        if cfg.DEBUG_MODE then
            print("🔍 Crowded area found:", maxCrowdedPlayers, "vs clear:", maxClearPlayers)
        end
        
        local nearbySpot, nearbyCount = findNearbySpot(crowdedSpot, currentCF or crowdedCF)
        if nearbySpot and nearbyCount > maxClearPlayers then
            if cfg.DEBUG_MODE then
                print("✅ Using nearby forward spot:", nearbyCount, "players")
            end
            return nearbySpot, nearbyCount, true
        end
    end
    
    return bestClearSpot, maxClearPlayers, false
end

-- Position Validation
local function validatePosition(root, targetCF)
    if not root or not targetCF then return false end
    if not isValidPosition(root.Position) or not isValidPosition(targetCF.Position) then return false end
    
    local dist = (root.Position - targetCF.Position).Magnitude
    return dist < 5
end

-- Natural Movement System (NO TWEENING)
local function performMovement()
    if not st.enabled or st.moving or st.relocating then return end
    
    st.moving = true
    local success = pcall(function()
        local c, hum, root = getCharacterParts()
        if not c or not hum or not root then
            st.moving = false
            return
        end
        
        local savedCF = st.savedPos
        if not savedCF or not isValidPosition(savedCF.Position) then
            st.moving = false
            return
        end
        
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus("Moving...", Color3.fromRGB(100, 150, 255))
        end
        
        -- Random jumps
        local jumpCount = math.random(cfg.MIN_JUMPS, cfg.MAX_JUMPS)
        for i = 1, jumpCount do
            if hum.Health <= 0 then break end
            hum.Jump = true
            task.wait(cfg.JUMP_INTERVAL)
        end
        task.wait(0.2)
        
        -- Walk in random direction
        local angle = math.rad(math.random(0, 360))
        local distance = math.random(cfg.MIN_WALK_DISTANCE, cfg.MAX_WALK_DISTANCE)
        local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local targetPos = savedCF.Position + (direction * distance)
        
        if not isValidPosition(targetPos) then
            st.moving = false
            return
        end
        
        hum.WalkSpeed = cfg.WALK_SPEED_NORMAL
        hum:MoveTo(targetPos)
        
        local walkTime = distance / cfg.WALK_SPEED_NORMAL + 0.5
        task.wait(walkTime)
        
        -- Walk back naturally
        hum.WalkSpeed = cfg.WALK_SPEED_FAST
        hum:MoveTo(savedCF.Position)
        
        local returnTime = distance / cfg.WALK_SPEED_FAST + 0.5
        task.wait(returnTime)
        
        -- Brief pause
        task.wait(math.random(15, 35) / 10)
        
        -- Face center and validate position
        hum.WalkSpeed = cfg.WALK_SPEED_NORMAL
        root.CFrame = createLookAtCFrame(root.Position)
        task.wait(0.1)
        
        if not validatePosition(root, savedCF) then
            if cfg.DEBUG_MODE then
                print("⚠️ Position validation failed")
            end
            
            st.consecutiveFailures = st.consecutiveFailures + 1
            
            if st.consecutiveFailures >= 3 then
                if getgenv().MasploitzUI then
                    getgenv().MasploitzUI.updateStatus("Position lost! Respawning...", Color3.fromRGB(255, 100, 100))
                end
                task.wait(0.5)
                if hum then hum.Health = 0 end
                st.consecutiveFailures = 0
            else
                -- Try to walk back
                hum:MoveTo(savedCF.Position)
                task.wait(2)
            end
        else
            st.consecutiveFailures = 0
            if getgenv().MasploitzUI then
                getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
            end
        end
    end)
    
    if not success and cfg.DEBUG_MODE then
        print("⚠️ Movement error occurred")
    end
    
    st.moving = false
end

-- Relocation System (NO TWEENING)
local function relocatePosition()
    if st.relocating or st.moving or st.isRespawning then return end
    
    local c, hum, root = getCharacterParts()
    if not c or not hum or not root then return end
    
    local currentCF = root.CFrame
    local playerInFront = checkPlayerInFront(currentCF, cfg.FRONT_CHECK_DISTANCE, cfg.FRONT_CHECK_ANGLE)
    local playerTooClose = checkPlayerTooClose(root.Position, cfg.BLOCK_CHECK_DISTANCE)
    
    -- Immediate relocation if blocked
    if playerInFront or playerTooClose then
        st.relocating = true
        
        if getgenv().MasploitzUI then
            local reason = playerInFront and "Player in front!" or "Player too close!"
            getgenv().MasploitzUI.updateStatus(reason .. " Relocating...", Color3.fromRGB(255, 150, 50))
        end
        
        local bestSpot, playerCount, usedPathfinding = findBestSpot(root.Position, currentCF)
        
        if bestSpot and isValidPosition(bestSpot.Position) then
            local success = pcall(function()
                if usedPathfinding then
                    -- Use pathfinding for crowded areas
                    local PFS = game:GetService("PathfindingService")
                    local path = PFS:CreatePath({
                        AgentRadius = 2,
                        AgentHeight = 5,
                        AgentCanJump = true
                    })
                    
                    local pathSuccess = pcall(function()
                        path:ComputeAsync(root.Position, bestSpot.Position)
                    end)
                    
                    if pathSuccess and path.Status == Enum.PathStatus.Success then
                        local waypoints = path:GetWaypoints()
                        for _, waypoint in pairs(waypoints) do
                            if hum.Health <= 0 then break end
                            if waypoint.Action == Enum.PathWaypointAction.Jump then
                                hum.Jump = true
                            end
                            hum:MoveTo(waypoint.Position)
                            hum.MoveToFinished:Wait()
                        end
                    else
                        hum:MoveTo(bestSpot.Position)
                        task.wait(3)
                    end
                else
                    -- Direct walk
                    hum.WalkSpeed = cfg.WALK_SPEED_NORMAL
                    hum:MoveTo(bestSpot.Position)
                    local walkDist = (root.Position - bestSpot.Position).Magnitude
                    task.wait(walkDist / cfg.WALK_SPEED_NORMAL + 1)
                end
                
                -- Update saved position
                task.wait(0.5)
                if hum.Health > 0 then
                    st.savedPos = root.CFrame
                    
                    if getgenv().MasploitzUI then
                        getgenv().MasploitzUI.updateStatus("Relocated! (" .. playerCount .. " nearby)", Color3.fromRGB(100, 200, 255))
                    end
                end
            end)
            
            task.wait(2)
            if getgenv().MasploitzUI then
                getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
            end
        end
        
        st.relocating = false
        return
    end
    
    -- Check for better spots periodically
    local currentPlayerCount = countNearbyPlayers(root.Position, cfg.PLAYER_RADIUS)
    local bestSpot, bestCount, usedPathfinding = findBestSpot(root.Position, currentCF)
    
    if bestSpot and bestCount > currentPlayerCount + 3 then
        st.relocating = true
        
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus("Better spot found! Moving...", Color3.fromRGB(255, 200, 100))
        end
        
        local success = pcall(function()
            if usedPathfinding then
                local PFS = game:GetService("PathfindingService")
                local path = PFS:CreatePath({
                    AgentRadius = 2,
                    AgentHeight = 5,
                    AgentCanJump = true
                })
                
                local pathSuccess = pcall(function()
                    path:ComputeAsync(root.Position, bestSpot.Position)
                end)
                
                if pathSuccess and path.Status == Enum.PathStatus.Success then
                    for _, waypoint in pairs(path:GetWaypoints()) do
                        if hum.Health <= 0 then break end
                        if waypoint.Action == Enum.PathWaypointAction.Jump then
                            hum.Jump = true
                        end
                        hum:MoveTo(waypoint.Position)
                        hum.MoveToFinished:Wait()
                    end
                else
                    hum:MoveTo(bestSpot.Position)
                    task.wait(3)
                    # Face center after walking
                    root.CFrame = createLookAtCFrame(root.Position)
                end
            else
                hum.WalkSpeed = cfg.WALK_SPEED_NORMAL
                hum:MoveTo(bestSpot.Position)
                local walkDist = (root.Position - bestSpot.Position).Magnitude
                task.wait(walkDist / cfg.WALK_SPEED_NORMAL + 1)
                
                # Face center after walking
                root.CFrame = createLookAtCFrame(root.Position)
            end
            
            task.wait(0.5)
            if hum.Health > 0 then
                st.savedPos = root.CFrame
                
                if getgenv().MasploitzUI then
                    getgenv().MasploitzUI.updateStatus("Relocated! (" .. bestCount .. " nearby)", Color3.fromRGB(100, 200, 255))
                end
            end
        end)
        
        task.wait(2)
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
        end
        
        st.relocating = false
    end
end

-- Chat System
local function sendRandomChat()
    if not cfg.ENABLE_CHAT_MESSAGES then return end
    if tick() - st.lastChat < cfg.CHAT_INTERVAL_MIN then return end
    if tick() - st.lastChat > cfg.CHAT_INTERVAL_MAX and math.random() > 0.5 then return end
    
    local success = pcall(function()
        local chatEvents = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvents then
            local sayMessage = chatEvents:FindFirstChild("SayMessageRequest")
            if sayMessage then
                local message = cfg.CHAT_MESSAGES[math.random(1, #cfg.CHAT_MESSAGES)]
                sayMessage:FireServer(message, "All")
                st.lastChat = tick()
            end
        end
    end)
end

-- Emote System
local function triggerRandomEmote()
    if not cfg.ENABLE_EMOTES then return end
    if tick() - st.lastEmote < cfg.EMOTE_INTERVAL_MIN then return end
    
    local c, hum, root = getCharacterParts()
    if hum then
        local success = pcall(function()
            local tracks = hum:GetPlayingAnimationTracks()
            if #tracks > 0 and math.random() > 0.7 then
                tracks[math.random(1, #tracks)]:Stop()
            end
            st.lastEmote = tick()
        end)
    end
end

-- Camera Movement
local function moveCamera()
    if not cfg.ENABLE_CAMERA_MOVE then return end
    if tick() - st.lastCamera < cfg.CAMERA_INTERVAL_MIN then return end
    
    local success = pcall(function()
        local camera = workspace.CurrentCamera
        if camera then
            local currentCF = camera.CFrame
            local angleOffset = CFrame.Angles(
                math.rad(math.random(-15, 15)),
                math.rad(math.random(-30, 30)),
                0
            )
            
            TS:Create(
                camera,
                TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                {CFrame = currentCF * angleOffset}
            ):Play()
            
            st.lastCamera = tick()
        end
    end)
end

-- Tool Re-equip
local function reequipTool()
    if not cfg.AUTO_RE_EQUIP then return end
    
    local c, hum, root = getCharacterParts()
    if not c or not hum then return end
    
    -- Check if tool is already equipped
    if c:FindFirstChild(cfg.AUTO_EQUIP_TOOL) then return end
    
    local success = pcall(function()
        local backpack = P:FindFirstChild("Backpack")
        if backpack then
            local tool = backpack:FindFirstChild(cfg.AUTO_EQUIP_TOOL)
            if tool then
                hum:EquipTool(tool)
                
                if getgenv().MasploitzUI then
                    getgenv().MasploitzUI.updateStatus("Tool Re-equipped", Color3.fromRGB(100, 255, 150))
                    task.wait(1)
                    getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
                end
            end
        end
    end)
end

-- Anti-AFK System
local vu = game:GetService('VirtualUser')
P.Idled:Connect(function()
    if st.enabled then
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
        
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus("Kick Blocked!", Color3.fromRGB(255, 200, 0))
            task.wait(2)
            getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
        end
    end
end)

-- Main Loops
task.spawn(function()
    while true do
        task.wait(math.random(cfg.RANDOM_MOVE_MIN, cfg.RANDOM_MOVE_MAX))
        if st.enabled and not st.isRespawning then
            performMovement()
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(cfg.REGULAR_MOVE_INTERVAL)
        if st.enabled and not st.isRespawning and P.Character then
            performMovement()
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(math.random(cfg.MICRO_MOVE_MIN, cfg.MICRO_MOVE_MAX))
        if st.enabled then
            pcall(function()
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(cfg.SPOT_CHECK_INTERVAL)
        if st.enabled and not st.relocating and not st.moving and not st.isRespawning then
            relocatePosition()
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(cfg.BLOCK_CHECK_INTERVAL)
        if st.enabled and not st.relocating and not st.moving and not st.isRespawning then
            local c, hum, root = getCharacterParts()
            if c and hum and root then
                local blocked = checkPlayerInFront(root.CFrame, cfg.FRONT_CHECK_DISTANCE, cfg.FRONT_CHECK_ANGLE)
                local tooClose = checkPlayerTooClose(root.Position, cfg.BLOCK_CHECK_DISTANCE)
                
                if blocked or tooClose then
                    relocatePosition()
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(12)
        if st.enabled and not st.isRespawning then
            sendRandomChat()
            triggerRandomEmote()
            moveCamera()
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(cfg.RE_EQUIP_INTERVAL)
        if st.enabled and cfg.AUTO_RE_EQUIP and not st.isRespawning then
            reequipTool()
        end
    end
end)

task.spawn(function()
    task.wait(cfg.AUTO_HOP_TIME)
    task.wait(2)
    serverHop()
end)

-- Character Management
P.CharacterAdded:Connect(function(character)
    st.isRespawning = true
    st.consecutiveFailures = 0
    
    task.wait(2)
    
    if st.savedPos and st.enabled then
        local root = character:WaitForChild("HumanoidRootPart", 5)
        local hum = character:WaitForChild("Humanoid", 5)
        
        if root and hum and isValidPosition(st.savedPos.Position) then
            -- Use natural movement to return to position
            hum:MoveTo(st.savedPos.Position)
            task.wait(2)
            
            if getgenv().MasploitzUI then
                getgenv().MasploitzUI.updateStatus("Respawned", Color3.fromRGB(100, 200, 255))
            end
        end
    end
    
    -- Equip tool
    task.spawn(function()
        task.wait(1)
        for attempts = 1, 15 do
            if equipTool() then
                break
            end
            task.wait(0.5)
        end
    end)
    
    task.wait(2)
    st.isRespawning = false
    
    if st.enabled and getgenv().MasploitzUI then
        getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
    end
end)

-- Initial Setup
task.spawn(function()
    repeat task.wait() until P.Character and P.Character:FindFirstChild("HumanoidRootPart")
    
    task.wait(1)
    
    local c, hum, root = getCharacterParts()
    if not c or not hum or not root then return end
    
    local bestSpot, playerCount, usedPathfinding = findBestSpot(nil, nil)
    
    if not bestSpot then
        local randomSpawn = cfg.SPAWN_POSITIONS[math.random(1, #cfg.SPAWN_POSITIONS)]
        bestSpot = createLookAtCFrame(randomSpawn)
        playerCount = 0
        usedPathfinding = false
    end
    
    if bestSpot and isValidPosition(bestSpot.Position) then
        if usedPathfinding then
            local PFS = game:GetService("PathfindingService")
            local path = PFS:CreatePath({
                AgentRadius = 2,
                AgentHeight = 5,
                AgentCanJump = true
            })
            
            local pathSuccess = pcall(function()
                path:ComputeAsync(root.Position, bestSpot.Position)
            end)
            
            if pathSuccess and path.Status == Enum.PathStatus.Success then
                for _, waypoint in pairs(path:GetWaypoints()) do
                    if hum.Health <= 0 then break end
                    if waypoint.Action == Enum.PathWaypointAction.Jump then
                        hum.Jump = true
                    end
                    hum:MoveTo(waypoint.Position)
                    hum.MoveToFinished:Wait()
                end
            end
        else
            hum:MoveTo(bestSpot.Position)
            task.wait(2)
            # Face center after positioning
            root.CFrame = createLookAtCFrame(root.Position)
        end
        
        st.savedPos = root.CFrame
        
        -- Wait for UI
        for i = 1, 20 do
            if getgenv().MasploitzUI then break end
            task.wait(0.1)
        end
        
        if getgenv().MasploitzUI then
            local statusMsg = usedPathfinding and "Crowded area! (" .. playerCount .. ")" or "Best spot (" .. playerCount .. ")"
            getgenv().MasploitzUI.updateStatus(statusMsg, Color3.fromRGB(100, 200, 255))
            task.spawn(function()
                getgenv().MasploitzUI.showSavedPos()
            end)
        end
        
        task.wait(1)
        equipTool()
        task.wait(2)
        
        if getgenv().MasploitzUI then
            getgenv().MasploitzUI.updateStatus("Active", Color3.fromRGB(0, 255, 100))
        end
    end
end)

print("✅ Masploitz Backend (Improved) initialized")

-- API
getgenv().MasploitzFunctions = {
    serverHop = serverHop,
    savePosition = function()
        local c, hum, root = getCharacterParts()
        if root then
            st.savedPos = root.CFrame
            st.consecutiveFailures = 0
            return true
        end
        return false
    end,
    toggleEnabled = function()
        st.enabled = not st.enabled
        return st.enabled
    end,
    reEquipTool = reequipTool,
    validatePosition = function()
        local c, hum, root = getCharacterParts()
        if root and st.savedPos then
            return validatePosition(root, st.savedPos)
        end
        return false
    end
}
