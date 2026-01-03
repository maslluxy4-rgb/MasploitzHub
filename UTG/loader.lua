-- Masploitz Hub Main Loader
-- Usage: loadstring(game:HttpGet("https://raw.githubusercontent.com/maslluxy4-rgb/MasploitzHub/main/UTG/loader.lua"))()

local REPO_URL = "https://raw.githubusercontent.com/maslluxy4-rgb/MasploitzHub/main/UTG/"

-- Load modules
print("[Masploitz] Loading UI and Backend modules...")
local backend = loadstring(game:HttpGet(REPO_URL .. "backend.lua"))()
local UIModule = loadstring(game:HttpGet(REPO_URL .. "ui.lua"))()

-- Initialize UI Module
local ui = UIModule.new()
ui:SetTheme("Dark")

print("[Masploitz] Creating GUI...")
ui:CreateGUI()

-- Helper function for tweening
local function tween(object, duration, properties)
    game:GetService("TweenService"):Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties):Play()
end

-- Create tabs
local teleportTab = ui:AddTab("Teleport", "🎯")
local settingsTab = ui:AddTab("Settings", "⚙️")

-- ===== TELEPORT TAB =====

-- Status Display
ui:CreateStatusDisplay(teleportTab)

-- Control Buttons
ui:CreateControlButtons(teleportTab, 
    function() -- Stop callback
        backend.stopTeleport()
        ui:UpdateStatus("Inactive", ui.Theme.Error)
        for _, btn in pairs(ui.TeleportButtons) do
            btn.Text = "Join"
            tween(btn, 0.2, {BackgroundColor3 = game:GetService("RunService"):IsStudio() and Color3.fromRGB(30, 64, 175) or Color3.fromRGB(30, 64, 175)})
        end
    end,
    function() -- Return callback
        backend.returnToSpawn()
    end
)

-- Team Header
ui:CreateTeamHeader(teleportTab)

-- Function to update teams list
local function updateTeams()
    ui:ClearTeamButtons(teleportTab)
    
    local teams = backend.getTeams()
    for color, info in pairs(teams) do
        ui:CreateTeamButton(teleportTab, color, info.Count, info.Color, function(button, teamColor)
            local active = button.Text == "Active"
            
            if active then
                button.Text = "Join"
                tween(button, 0.2, {BackgroundColor3 = Color3.fromRGB(30, 64, 175)})
                backend.stopTeleport()
                ui:UpdateStatus("Inactive", ui.Theme.Error)
            else
                -- Deactivate all other buttons
                for _, btn in pairs(ui.TeleportButtons) do
                    btn.Text = "Join"
                    tween(btn, 0.2, {BackgroundColor3 = Color3.fromRGB(30, 64, 175)})
                end
                
                button.Text = "Active"
                tween(button, 0.2, {BackgroundColor3 = Color3.fromRGB(6, 78, 59)})
                
                local success = backend.startTeleport(teamColor, function()
                    -- On team joined callback
                    ui:UpdateStatus("Team Joined!", ui.Theme.Success)
                    for _, btn in pairs(ui.TeleportButtons) do
                        btn.Text = "Join"
                        tween(btn, 0.2, {BackgroundColor3 = Color3.fromRGB(30, 64, 175)})
                    end
                    
                    -- Auto return if enabled
                    if backend.settings.autoReturn then
                        wait(0.3)
                        backend.returnToSpawn()
                        wait(0.2)
                    end
                    
                    ui:UpdateStatus("Inactive", ui.Theme.Error)
                end)
                
                if success then
                    ui:UpdateStatus("Active - " .. teamColor, ui.Theme.Success)
                else
                    ui:UpdateStatus("No players found", ui.Theme.Warning)
                    button.Text = "Join"
                    tween(button, 0.2, {BackgroundColor3 = Color3.fromRGB(30, 64, 175)})
                end
            end
        end)
    end
end

-- Initial teams update
updateTeams()

-- Auto update teams every 2 seconds
spawn(function()
    while ui.ScreenGui and ui.ScreenGui.Parent do
        wait(2)
        updateTeams()
    end
end)

-- ===== SETTINGS TAB =====

-- Auto Return Toggle
ui:AddToggle(settingsTab, "Auto Return", "Return to spawn after joining team", backend.settings.autoReturn, function(value)
    backend.settings.autoReturn = value
end)

-- Follow Distance Input
ui:AddNumberInput(settingsTab, "Follow Distance", "Distance behind target (0-100 studs)", backend.settings.distance, 0, 100, function(value)
    backend.settings.distance = value
end)

-- Hide Own Team Toggle
ui:AddToggle(settingsTab, "Hide Own Team", "Don't show your current team in the list", backend.settings.excludeOwnTeam, function(value)
    backend.settings.excludeOwnTeam = value
    updateTeams() -- Refresh team list immediately
end)

-- Stop On Team Join Toggle
ui:AddToggle(settingsTab, "Stop On Team Join", "Stop teleporting when you join the target team", backend.settings.stopOnTeamJoin, function(value)
    backend.settings.stopOnTeamJoin = value
end)

-- Info section
local infoSection = ui:CreateSection(settingsTab.Content, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 85), nil)
infoSection.BackgroundColor3 = Color3.fromRGB(6, 78, 59)
infoSection.BackgroundTransparency = 0.65

local infoStroke = infoSection:FindFirstChildOfClass("UIStroke")
if infoStroke then
    infoStroke.Color = ui.Theme.Success
    infoStroke.Transparency = 0.35
end

local infoLabel = ui:CreateLabel(infoSection, UDim2.new(0, 10, 0, 7), UDim2.new(1, -20, 1, -14), "💡 Tip: Lower distances keep you closer to the target. Higher distances give you more space. You'll always face the same direction as your target!", 12, false)
infoLabel.Font = Enum.Font.Gotham

settingsTab.Content.CanvasSize = UDim2.new(0, 0, 0, settingsTab.Content.UIListLayout.AbsoluteContentSize.Y)

-- ===== BUTTON CONNECTIONS =====

-- Hide button
ui.HideButton.MouseButton1Click:Connect(function()
    ui:ToggleVisibility(false)
end)

-- Close button
ui.CloseButton.MouseButton1Click:Connect(function()
    backend.cleanup()
    ui:Cleanup()
end)

-- Toggle button
ui.ToggleButton.MouseButton1Click:Connect(function()
    ui:ToggleVisibility(true)
end)

print("[Masploitz] Hub initialized successfully!")
