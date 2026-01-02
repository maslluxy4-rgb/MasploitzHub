-- Masploitz Hub Backend
-- Upload this as backend.lua to your GitHub repo

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local Backend = {}
Backend.settings = {autoReturn = true, distance = 3}
Backend.state = {
    tpOn = false,
    selTeam = nil,
    curPlayer = nil,
    origPos = nil,
    updateConn = nil
}

-- Core teleport logic
function Backend.tpToTeam(teamColor)
    local playersOnTeam = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local torso = player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso")
            if torso and torso.BrickColor.Name == teamColor then
                table.insert(playersOnTeam, player)
            end
        end
    end
    
    if #playersOnTeam > 0 then
        Backend.state.curPlayer = playersOnTeam[math.random(1, #playersOnTeam)]
        if not Backend.state.origPos and LP.Character then
            local rootPart = LP.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                Backend.state.origPos = rootPart.CFrame
            end
        end
        return true
    end
    return false
end

-- Follow player logic
function Backend.followPlayer()
    if not (Backend.state.tpOn and Backend.state.curPlayer and Backend.state.curPlayer.Character and LP.Character) then
        return
    end
    
    local rootPart = LP.Character:FindFirstChild("HumanoidRootPart")
    local targetRootPart = Backend.state.curPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if rootPart and targetRootPart then
        rootPart.CFrame = targetRootPart.CFrame * CFrame.new(0, 0, Backend.settings.distance)
    end
end

-- Check if player joined target team
function Backend.checkTeamJoined()
    if not LP.Character then return false end
    
    local localTorso = LP.Character:FindFirstChild("Torso") or LP.Character:FindFirstChild("UpperTorso")
    if localTorso and localTorso.BrickColor.Name == Backend.state.selTeam then
        return true
    end
    return false
end

-- Get all teams
function Backend.getTeams()
    local teams = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local torso = player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso")
            if torso then
                local color = torso.BrickColor.Name
                teams[color] = teams[color] or {Count = 0, Color = torso.BrickColor.Color}
                teams[color].Count = teams[color].Count + 1
            end
        end
    end
    return teams
end

-- Start teleporting
function Backend.startTeleport(teamColor, onTeamJoined)
    Backend.state.tpOn = true
    Backend.state.selTeam = teamColor
    
    if not Backend.tpToTeam(teamColor) then
        Backend.state.tpOn = false
        return false
    end
    
    -- Main teleport loop
    if Backend.state.updateConn then
        Backend.state.updateConn:Disconnect()
    end
    
    Backend.state.updateConn = RunService.Heartbeat:Connect(function()
        if Backend.state.tpOn and Backend.state.selTeam then
            -- Check if player joined the team
            if Backend.checkTeamJoined() then
                Backend.stopTeleport()
                if onTeamJoined then
                    onTeamJoined()
                end
                
                -- Auto return if enabled
                if Backend.settings.autoReturn and Backend.state.origPos and LP.Character then
                    local rootPart = LP.Character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        rootPart.CFrame = Backend.state.origPos
                        Backend.state.origPos = nil
                    end
                end
                return
            end
            
            -- Follow current player or find new one
            if Backend.state.curPlayer and Backend.state.curPlayer.Character then
                local torso = Backend.state.curPlayer.Character:FindFirstChild("Torso") or Backend.state.curPlayer.Character:FindFirstChild("UpperTorso")
                if torso and torso.BrickColor.Name == Backend.state.selTeam then
                    Backend.followPlayer()
                else
                    Backend.tpToTeam(Backend.state.selTeam)
                end
            else
                Backend.tpToTeam(Backend.state.selTeam)
            end
        end
    end)
    
    return true
end

-- Stop teleporting
function Backend.stopTeleport()
    Backend.state.tpOn = false
    Backend.state.selTeam = nil
    Backend.state.curPlayer = nil
end

-- Return to spawn
function Backend.returnToSpawn()
    if Backend.state.origPos and LP.Character then
        local rootPart = LP.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = Backend.state.origPos
            Backend.state.origPos = nil
        end
        return true
    end
    return false
end

-- Cleanup
function Backend.cleanup()
    Backend.stopTeleport()
    if Backend.state.updateConn then
        Backend.state.updateConn:Disconnect()
        Backend.state.updateConn = nil
    end
    if Backend.state.origPos and LP.Character then
        local rootPart = LP.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = Backend.state.origPos
        end
    end
end

return Backend
