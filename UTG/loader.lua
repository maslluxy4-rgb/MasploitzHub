-- Masploitz Hub Main Loader with Tab System
-- Upload this as loader.lua to your GitHub repo

local TS = game:GetService("TweenService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local MS = game:GetService("MarketplaceService")
local LP = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/maslluxy4-rgb/MasploitzHub/main/UTG/"

-- Load modules
print("[Masploitz] Loading UI and Backend modules...")
local backend = loadstring(game:HttpGet(REPO_URL .. "backend.lua"))()
local UIModule = loadstring(game:HttpGet(REPO_URL .. "ui.lua"))()

-- Initialize UI Module
local ui = UIModule.new()
ui:SetTheme("Dark")

-- Main Hub Class
local Hub = {}
Hub.Tabs = {}
Hub.ActiveTab = nil
Hub.TeleportButtons = {}

-- Helper functions
local function tween(object, duration, properties)
    TS:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties):Play()
end

-- Create main GUI structure
function Hub:CreateGUI()
    -- ScreenGui
    self.ScreenGui = Instance.new("ScreenGui", LP:WaitForChild("PlayerGui"))
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.Name = "MasploitzHub"
    
    -- Toggle Button
    self.ToggleButton = ui:CreateButton(self.ScreenGui, UDim2.new(0.5, -37.5, 0, 25), UDim2.new(0, 75, 0, 75), "🎯", 36)
    self.ToggleButton.Visible = false
    self.ToggleButton.ZIndex = 10
    
    -- Shadow
    self.Shadow = Instance.new("Frame", self.ScreenGui)
    self.Shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    self.Shadow.BackgroundTransparency = 0.4
    self.Shadow.Size = UDim2.new(0, 710, 0, 450)
    self.Shadow.Position = UDim2.new(0.5, -355, 0.5, -220)
    self.Shadow.BorderSizePixel = 0
    self.Shadow.ZIndex = 0
    Instance.new("UICorner", self.Shadow).CornerRadius = UDim.new(0, 18)
    
    -- Container
    self.Container = Instance.new("Frame", self.ScreenGui)
    self.Container.BackgroundTransparency = 1
    self.Container.Size = UDim2.new(0, 700, 0, 440)
    self.Container.Position = UDim2.new(0.5, -350, 0.5, -220)
    self.Container.ClipsDescendants = true
    self.Container.BorderSizePixel = 0
    
    -- Main Panel
    self.MainPanel = Instance.new("Frame", self.Container)
    self.MainPanel.BackgroundColor3 = ui.Theme.Primary
    self.MainPanel.Size = UDim2.new(1, 0, 1, 0)
    self.MainPanel.Position = UDim2.new(0, 0, 0, 0)
    self.MainPanel.BorderSizePixel = 0
    Instance.new("UICorner", self.MainPanel).CornerRadius = UDim.new(0, 16)
    Instance.new("UIStroke", self.MainPanel).Color = ui.Theme.Accent
    Instance.new("UIStroke", self.MainPanel).Thickness = 1
    Instance.new("UIStroke", self.MainPanel).Transparency = 0.15
    
    local grad = Instance.new("UIGradient", self.MainPanel)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, ui.Theme.Gradient1),
        ColorSequenceKeypoint.new(1, ui.Theme.Gradient2)
    })
    grad.Rotation = 180
    
    -- Top accent line
    local topLine = Instance.new("Frame", self.MainPanel)
    topLine.BackgroundColor3 = ui.Theme.Accent
    topLine.Size = UDim2.new(1, 0, 0, 2)
    topLine.Position = UDim2.new(0, 0, 0, 0)
    topLine.BorderSizePixel = 0
    topLine.ZIndex = 5
    topLine.BackgroundTransparency = 0.3
    
    self:CreateTitle()
    self:CreateTabSection()
end

-- Create title bar
function Hub:CreateTitle()
    local titleFrame = Instance.new("Frame", self.MainPanel)
    titleFrame.BackgroundTransparency = 1
    titleFrame.Size = UDim2.new(1, 0, 0, 65)
    titleFrame.BorderSizePixel = 0
    titleFrame.ZIndex = 2
    
    local brandFrame = Instance.new("Frame", titleFrame)
    brandFrame.BackgroundTransparency = 1
    brandFrame.Size = UDim2.new(0.4, 0, 1, 0)
    brandFrame.Position = UDim2.new(0, 15, 0, 0)
    brandFrame.ZIndex = 3
    
    ui:CreateLabel(brandFrame, UDim2.new(0, 0, 0, 10), UDim2.new(1, 0, 0, 28), "MASPLOITZ HUB", 18, true)
    
    local gameName = MS:GetProductInfo(game.PlaceId).Name
    local subLabel = ui:CreateLabel(brandFrame, UDim2.new(0, 0, 0, 40), UDim2.new(1, 0, 0, 15), gameName:lower(), 10, false)
    subLabel.TextColor3 = ui.Theme.SubText
    
    -- Control buttons
    local hideBtn = ui:CreateButton(titleFrame, UDim2.new(1, -95, 0.5, -18), UDim2.new(0, 38, 0, 36), "−", 22)
    hideBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    
    local closeBtn = ui:CreateButton(titleFrame, UDim2.new(1, -50, 0.5, -18), UDim2.new(0, 38, 0, 36), "×", 22)
    closeBtn.BackgroundColor3 = Color3.fromRGB(127, 29, 29)
    
    -- Button events
    hideBtn.MouseButton1Click:Connect(function()
        self:ToggleVisibility(false)
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Cleanup()
    end)
    
    self.ToggleButton.MouseButton1Click:Connect(function()
        self:ToggleVisibility(true)
    end)
    
    -- Make draggable
    self:MakeDraggable(titleFrame)
end

-- Create tab section (left sidebar)
function Hub:CreateTabSection()
    -- Tab sidebar container
    self.TabSidebar = Instance.new("Frame", self.MainPanel)
    self.TabSidebar.BackgroundColor3 = ui.Theme.Secondary
    self.TabSidebar.Size = UDim2.new(0, 180, 1, -75)
    self.TabSidebar.Position = UDim2.new(0, 10, 0, 70)
    self.TabSidebar.BorderSizePixel = 0
    self.TabSidebar.ZIndex = 2
    Instance.new("UICorner", self.TabSidebar).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", self.TabSidebar).Color = ui.Theme.Accent
    Instance.new("UIStroke", self.TabSidebar).Thickness = 1
    Instance.new("UIStroke", self.TabSidebar).Transparency = 0.25
    
    -- Scrolling frame for tabs
    self.TabList = Instance.new("ScrollingFrame", self.TabSidebar)
    self.TabList.BackgroundTransparency = 1
    self.TabList.Size = UDim2.new(1, -10, 1, -10)
    self.TabList.Position = UDim2.new(0, 5, 0, 5)
    self.TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.TabList.ScrollBarThickness = 4
    self.TabList.BorderSizePixel = 0
    self.TabList.ScrollBarImageColor3 = ui.Theme.Accent
    self.TabList.ZIndex = 3
    
    Instance.new("UIListLayout", self.TabList).SortOrder = Enum.SortOrder.LayoutOrder
    Instance.new("UIListLayout", self.TabList).Padding = UDim.new(0, 5)
    
    -- Content area (right side)
    self.ContentArea = Instance.new("Frame", self.MainPanel)
    self.ContentArea.BackgroundColor3 = ui.Theme.Secondary
    self.ContentArea.Size = UDim2.new(0, 490, 1, -75)
    self.ContentArea.Position = UDim2.new(0, 200, 0, 70)
    self.ContentArea.BorderSizePixel = 0
    self.ContentArea.ZIndex = 2
    Instance.new("UICorner", self.ContentArea).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", self.ContentArea).Color = ui.Theme.Accent
    Instance.new("UIStroke", self.ContentArea).Thickness = 1
    Instance.new("UIStroke", self.ContentArea).Transparency = 0.25
end

-- Add a new tab
function Hub:AddTab(name, icon)
    local tab = {}
    tab.Name = name
    tab.Icon = icon or "📄"
    tab.Elements = {}
    
    -- Tab button
    tab.Button = Instance.new("TextButton", self.TabList)
    tab.Button.Size = UDim2.new(1, -10, 0, 40)
    tab.Button.BackgroundColor3 = ui.Theme.TabInactive
    tab.Button.Text = "  " .. tab.Icon .. "  " .. name
    tab.Button.TextColor3 = ui.Theme.Text
    tab.Button.Font = Enum.Font.GothamBold
    tab.Button.TextSize = 13
    tab.Button.TextXAlignment = Enum.TextXAlignment.Left
    tab.Button.BorderSizePixel = 0
    tab.Button.ZIndex = 4
    Instance.new("UICorner", tab.Button).CornerRadius = UDim.new(0, 10)
    
    -- Tab content frame
    tab.Content = Instance.new("ScrollingFrame", self.ContentArea)
    tab.Content.BackgroundTransparency = 1
    tab.Content.Size = UDim2.new(1, -20, 1, -20)
    tab.Content.Position = UDim2.new(0, 10, 0, 10)
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    tab.Content.ScrollBarThickness = 6
    tab.Content.BorderSizePixel = 0
    tab.Content.ScrollBarImageColor3 = ui.Theme.Accent
    tab.Content.ZIndex = 3
    tab.Content.Visible = false
    
    Instance.new("UIListLayout", tab.Content).SortOrder = Enum.SortOrder.LayoutOrder
    Instance.new("UIListLayout", tab.Content).Padding = UDim.new(0, 10)
    
    -- Click event
    tab.Button.MouseButton1Click:Connect(function()
        self:SwitchTab(tab)
    end)
    
    table.insert(self.Tabs, tab)
    
    -- Auto-resize tab list
    self.TabList.CanvasSize = UDim2.new(0, 0, 0, #self.Tabs * 45)
    
    -- Activate first tab
    if #self.Tabs == 1 then
        self:SwitchTab(tab)
    end
    
    return tab
end

-- Switch to a tab
function Hub:SwitchTab(tab)
    if self.ActiveTab then
        self.ActiveTab.Content.Visible = false
        tween(self.ActiveTab.Button, 0.2, {BackgroundColor3 = ui.Theme.TabInactive})
    end
    
    self.ActiveTab = tab
    tab.Content.Visible = true
    tween(tab.Button, 0.2, {BackgroundColor3 = ui.Theme.TabActive})
end

-- Add elements to tabs
function Hub:AddToggle(tab, name, description, defaultValue, callback)
    local section = ui:CreateSection(tab.Content, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 65), name)
    
    if description then
        local desc = ui:CreateLabel(section, UDim2.new(0, 14, 0, 34), UDim2.new(0.85, 0, 0, 25), description, 11, false)
        desc.TextColor3 = ui.Theme.SubText
    end
    
    local toggle = ui:CreateToggle(section, UDim2.new(1, -58, 0.5, -14), nil, defaultValue)
    
    toggle.Button.MouseButton1Click:Connect(function()
        if callback then callback(toggle.Value) end
    end)
    
    table.insert(tab.Elements, {Type = "Toggle", Element = toggle})
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, tab.Content.UIListLayout.AbsoluteContentSize.Y)
    
    return toggle
end

function Hub:AddNumberInput(tab, name, description, defaultValue, min, max, callback)
    local section = ui:CreateSection(tab.Content, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 65), name)
    
    if description then
        local desc = ui:CreateLabel(section, UDim2.new(0, 14, 0, 34), UDim2.new(0.7, 0, 0, 25), description, 11, false)
        desc.TextColor3 = ui.Theme.SubText
    end
    
    local input = ui:CreateNumberInput(section, UDim2.new(1, -66, 0.5, -16), nil, defaultValue, min, max, tostring(defaultValue))
    
    input.Box.FocusLost:Connect(function()
        if callback then callback(input.Value) end
    end)
    
    table.insert(tab.Elements, {Type = "NumberInput", Element = input})
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, tab.Content.UIListLayout.AbsoluteContentSize.Y)
    
    return input
end

function Hub:AddTextInput(tab, name, description, defaultValue, callback)
    local section = ui:CreateSection(tab.Content, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 65), name)
    
    if description then
        local desc = ui:CreateLabel(section, UDim2.new(0, 14, 0, 34), UDim2.new(0.55, 0, 0, 25), description, 11, false)
        desc.TextColor3 = ui.Theme.SubText
    end
    
    local input = ui:CreateTextInput(section, UDim2.new(1, -160, 0.5, -16), UDim2.new(0, 150, 0, 32), defaultValue, "Enter text...")
    
    input.Box.FocusLost:Connect(function()
        if callback then callback(input.Value) end
    end)
    
    table.insert(tab.Elements, {Type = "TextInput", Element = input})
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, tab.Content.UIListLayout.AbsoluteContentSize.Y)
    
    return input
end

function Hub:AddSlider(tab, name, description, min, max, defaultValue, increment, callback)
    local section = ui:CreateSection(tab.Content, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 80), name)
    
    if description then
        local desc = ui:CreateLabel(section, UDim2.new(0, 14, 0, 34), UDim2.new(0.9, 0, 0, 20), description, 11, false)
        desc.TextColor3 = ui.Theme.SubText
    end
    
    local slider = ui:CreateSlider(section, UDim2.new(0, 14, 0, 50), UDim2.new(1, -28, 0, 20), min, max, defaultValue, increment)
    
    -- Callback on value change
    local lastValue = defaultValue
    game:GetService("RunService").Heartbeat:Connect(function()
        if slider.Value ~= lastValue and callback then
            callback(slider.Value)
            lastValue = slider.Value
        end
    end)
    
    table.insert(tab.Elements, {Type = "Slider", Element = slider})
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, tab.Content.UIListLayout.AbsoluteContentSize.Y)
    
    return slider
end

function Hub:AddButton(tab, name, description, callback)
    local section = ui:CreateSection(tab.Content, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 65), nil)
    
    ui:CreateLabel(section, UDim2.new(0, 14, 0, 10), UDim2.new(0.5, 0, 0, 22), name, 14, true)
    
    if description then
        local desc = ui:CreateLabel(section, UDim2.new(0, 14, 0, 34), UDim2.new(0.55, 0, 0, 25), description, 11, false)
        desc.TextColor3 = ui.Theme.SubText
    end
    
    local button = ui:CreateButton(section, UDim2.new(1, -85, 0.5, -16), UDim2.new(0, 80, 0, 32), "Execute", 13)
    
    button.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    table.insert(tab.Elements, {Type = "Button", Element = button})
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, tab.Content.UIListLayout.AbsoluteContentSize.Y)
    
    return button
end

-- Make draggable
function Hub:MakeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        self.Container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        self.Shadow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X - 5, startPos.Y.Scale, startPos.Y.Offset + delta.Y + 5)
    end
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.Container.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Toggle visibility
function Hub:ToggleVisibility(show)
    if show then
        self.Container.Visible = true
        self.Shadow.Visible = true
        tween(self.Container, 0.4, {Size = UDim2.new(0, 700, 0, 440), Position = UDim2.new(0.5, -350, 0.5, -220)})
        tween(self.Shadow, 0.4, {Size = UDim2.new(0, 710, 0, 450), Position = UDim2.new(0.5, -355, 0.5, -225)})
        self.ToggleButton.Visible = false
    else
        tween(self.Container, 0.3, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)})
        tween(self.Shadow, 0.3, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)})
        wait(0.3)
        self.Container.Visible = false
        self.Shadow.Visible = false
        self.ToggleButton.Visible = true
    end
end

-- Cleanup
function Hub:Cleanup()
    backend.cleanup()
    tween(self.Container, 0.3, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)})
    tween(self.Shadow, 0.3, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)})
    wait(0.3)
    self.ScreenGui:Destroy()
end

-- Initialize the hub
Hub:CreateGUI()

-- Create tabs
local homeTab = Hub:AddTab("Home", "🏠")
local settingsTab = Hub:AddTab("Settings", "⚙️")
local teleportTab = Hub:AddTab("Teleport", "🎯")

-- Home Tab
Hub:AddButton(homeTab, "Welcome!", "This is the Masploitz Hub with tabbed interface", function()
    print("Welcome button clicked!")
end)

-- Settings Tab
Hub:AddToggle(settingsTab, "Auto Return", "Return to spawn after joining team", backend.settings.autoReturn, function(value)
    backend.settings.autoReturn = value
end)

Hub:AddNumberInput(settingsTab, "Follow Distance", "Distance behind target (0-100 studs)", backend.settings.distance, 0, 100, function(value)
    backend.settings.distance = value
end)

Hub:AddToggle(settingsTab, "Hide Own Team", "Don't show your current team in the list", backend.settings.excludeOwnTeam, function(value)
    backend.settings.excludeOwnTeam = value
end)

Hub:AddToggle(settingsTab, "Stop On Team Join", "Stop teleporting when you join the target team", backend.settings.stopOnTeamJoin, function(value)
    backend.settings.stopOnTeamJoin = value
end)

Hub:AddSlider(settingsTab, "Speed Multiplier", "Adjust game speed (experimental)", 1, 5, 1, 0.1, function(value)
    print("Speed:", value)
end)

-- Teleport Tab (your existing team teleport functionality would go here)
Hub:AddButton(teleportTab, "Teleport Features", "Team teleport features coming soon!", function()
    print("Teleport features!")
end)

print("[Masploitz] Hub initialized successfully with tabs!")
