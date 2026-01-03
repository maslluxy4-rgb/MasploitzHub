-- Masploitz Hub UI Module
-- Upload this as ui.lua to your GitHub repo

local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local MS = game:GetService("MarketplaceService")
local LP = Players.LocalPlayer

local UIModule = {}
UIModule.__index = UIModule

-- Theme Configuration
local Themes = {
    Dark = {
        Primary = Color3.fromRGB(11, 16, 32),
        Secondary = Color3.fromRGB(2, 6, 23),
        Accent = Color3.fromRGB(59, 130, 246),
        Success = Color3.fromRGB(52, 211, 153),
        Error = Color3.fromRGB(248, 113, 113),
        Warning = Color3.fromRGB(251, 191, 36),
        Text = Color3.fromRGB(229, 231, 235),
        SubText = Color3.fromRGB(139, 147, 167),
        Gradient1 = Color3.fromRGB(11, 20, 48),
        Gradient2 = Color3.fromRGB(11, 16, 32),
        TabActive = Color3.fromRGB(30, 64, 175),
        TabInactive = Color3.fromRGB(15, 23, 42)
    }
}

-- Helper functions
local function create(type, props)
    local inst = Instance.new(type)
    for k, v in pairs(props) do
        if k ~= "Parent" then inst[k] = v end
    end
    inst.Parent = props.Parent
    return inst
end

local function corner(parent, radius)
    return create("UICorner", {CornerRadius = UDim.new(0, radius), Parent = parent})
end

local function stroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color,
        Thickness = thickness or 2,
        Transparency = transparency or 0,
        Parent = parent
    })
end

local function gradient(parent, c1, c2, rotation)
    return create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, c1),
            ColorSequenceKeypoint.new(1, c2)
        }),
        Rotation = rotation or 90,
        Parent = parent
    })
end

local function tween(object, duration, properties)
    TS:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties):Play()
end

-- UIModule Constructor
function UIModule.new()
    local self = setmetatable({}, UIModule)
    self.Theme = Themes.Dark
    self.Tabs = {}
    self.ActiveTab = nil
    self.TeleportButtons = {}
    self.StatusLabel = nil
    self.StatusDot = nil
    self.ScreenGui = nil
    self.Container = nil
    self.Shadow = nil
    self.MainPanel = nil
    self.TabSidebar = nil
    self.TabList = nil
    self.ContentArea = nil
    self.ToggleButton = nil
    return self
end

-- Set Theme
function UIModule:SetTheme(themeName)
    self.Theme = Themes[themeName] or Themes.Dark
end

-- Create main GUI structure
function UIModule:CreateGUI()
    -- ScreenGui
    self.ScreenGui = Instance.new("ScreenGui", LP:WaitForChild("PlayerGui"))
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.Name = "MasploitzHub"
    
    -- Toggle Button
    self.ToggleButton = self:CreateButton(self.ScreenGui, UDim2.new(0.5, -37.5, 0, 25), UDim2.new(0, 75, 0, 75), "🎯", 36)
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
    corner(self.Shadow, 18)
    
    -- Container
    self.Container = Instance.new("Frame", self.ScreenGui)
    self.Container.BackgroundTransparency = 1
    self.Container.Size = UDim2.new(0, 700, 0, 440)
    self.Container.Position = UDim2.new(0.5, -350, 0.5, -220)
    self.Container.ClipsDescendants = true
    self.Container.BorderSizePixel = 0
    
    -- Main Panel
    self.MainPanel = Instance.new("Frame", self.Container)
    self.MainPanel.BackgroundColor3 = self.Theme.Primary
    self.MainPanel.Size = UDim2.new(1, 0, 1, 0)
    self.MainPanel.Position = UDim2.new(0, 0, 0, 0)
    self.MainPanel.BorderSizePixel = 0
    corner(self.MainPanel, 16)
    stroke(self.MainPanel, self.Theme.Accent, 1, 0.15)
    gradient(self.MainPanel, self.Theme.Gradient1, self.Theme.Gradient2, 180)
    
    -- Top accent line
    local topLine = Instance.new("Frame", self.MainPanel)
    topLine.BackgroundColor3 = self.Theme.Accent
    topLine.Size = UDim2.new(1, 0, 0, 2)
    topLine.Position = UDim2.new(0, 0, 0, 0)
    topLine.BorderSizePixel = 0
    topLine.ZIndex = 5
    topLine.BackgroundTransparency = 0.3
    
    self:CreateTitle()
    self:CreateTabSection()
end

-- Create title bar
function UIModule:CreateTitle()
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
    
    self:CreateLabel(brandFrame, UDim2.new(0, 0, 0, 10), UDim2.new(1, 0, 0, 28), "MASPLOITZ HUB", 18, true)
    
    local gameName = MS:GetProductInfo(game.PlaceId).Name
    local subLabel = self:CreateLabel(brandFrame, UDim2.new(0, 0, 0, 40), UDim2.new(1, 0, 0, 15), gameName:lower(), 10, false)
    subLabel.TextColor3 = self.Theme.SubText
    
    -- Control buttons
    local hideBtn = self:CreateButton(titleFrame, UDim2.new(1, -95, 0.5, -18), UDim2.new(0, 38, 0, 36), "−", 22)
    hideBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    
    local closeBtn = self:CreateButton(titleFrame, UDim2.new(1, -50, 0.5, -18), UDim2.new(0, 38, 0, 36), "×", 22)
    closeBtn.BackgroundColor3 = Color3.fromRGB(127, 29, 29)
    
    -- Store for external access
    self.HideButton = hideBtn
    self.CloseButton = closeBtn
    
    -- Make draggable
    self:MakeDraggable(titleFrame)
    
    return titleFrame
end

-- Create tab section (left sidebar)
function UIModule:CreateTabSection()
    -- Tab sidebar container
    self.TabSidebar = Instance.new("Frame", self.MainPanel)
    self.TabSidebar.BackgroundColor3 = self.Theme.Secondary
    self.TabSidebar.Size = UDim2.new(0, 180, 1, -75)
    self.TabSidebar.Position = UDim2.new(0, 10, 0, 70)
    self.TabSidebar.BorderSizePixel = 0
    self.TabSidebar.ZIndex = 2
    corner(self.TabSidebar, 12)
    stroke(self.TabSidebar, self.Theme.Accent, 1, 0.25)
    
    -- Scrolling frame for tabs
    self.TabList = Instance.new("ScrollingFrame", self.TabSidebar)
    self.TabList.BackgroundTransparency = 1
    self.TabList.Size = UDim2.new(1, -10, 1, -10)
    self.TabList.Position = UDim2.new(0, 5, 0, 5)
    self.TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.TabList.ScrollBarThickness = 4
    self.TabList.BorderSizePixel = 0
    self.TabList.ScrollBarImageColor3 = self.Theme.Accent
    self.TabList.ZIndex = 3
    
    create("UIListLayout", {Parent = self.TabList, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
    
    -- Content area (right side)
    self.ContentArea = Instance.new("Frame", self.MainPanel)
    self.ContentArea.BackgroundColor3 = self.Theme.Secondary
    self.ContentArea.Size = UDim2.new(0, 490, 1, -75)
    self.ContentArea.Position = UDim2.new(0, 200, 0, 70)
    self.ContentArea.BorderSizePixel = 0
    self.ContentArea.ZIndex = 2
    corner(self.ContentArea, 12)
    stroke(self.ContentArea, self.Theme.Accent, 1, 0.25)
end

-- Add a new tab
function UIModule:AddTab(name, icon)
    local tab = {}
    tab.Name = name
    tab.Icon = icon or "📄"
    tab.Elements = {}
    
    -- Tab button
    tab.Button = Instance.new("TextButton", self.TabList)
    tab.Button.Size = UDim2.new(1, -10, 0, 40)
    tab.Button.BackgroundColor3 = self.Theme.TabInactive
    tab.Button.Text = "  " .. tab.Icon .. "  " .. name
    tab.Button.TextColor3 = self.Theme.Text
    tab.Button.Font = Enum.Font.GothamBold
    tab.Button.TextSize = 13
    tab.Button.TextXAlignment = Enum.TextXAlignment.Left
    tab.Button.BorderSizePixel = 0
    tab.Button.ZIndex = 4
    corner(tab.Button, 10)
    
    -- Tab content frame
    tab.Content = Instance.new("ScrollingFrame", self.ContentArea)
    tab.Content.BackgroundTransparency = 1
    tab.Content.Size = UDim2.new(1, -20, 1, -20)
    tab.Content.Position = UDim2.new(0, 10, 0, 10)
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    tab.Content.ScrollBarThickness = 6
    tab.Content.BorderSizePixel = 0
    tab.Content.ScrollBarImageColor3 = self.Theme.Accent
    tab.Content.ZIndex = 3
    tab.Content.Visible = false
    
    create("UIListLayout", {Parent = tab.Content, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})
    
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
function UIModule:SwitchTab(tab)
    if self.ActiveTab then
        self.ActiveTab.Content.Visible = false
        tween(self.ActiveTab.Button, 0.2, {BackgroundColor3 = self.Theme.TabInactive})
    end
    
    self.ActiveTab = tab
    tab.Content.Visible = true
    tween(tab.Button, 0.2, {BackgroundColor3 = self.Theme.TabActive})
end

-- Create Base Button
function UIModule:CreateButton(parent, position, size, text, textSize)
    local button = create("TextButton", {
        Parent = parent,
        Size = size,
        Position = position,
        BackgroundColor3 = self.Theme.TabActive,
        Text = text,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = textSize or 14,
        BorderSizePixel = 0,
        ZIndex = 3
    })
    corner(button, 12)
    stroke(button, self.Theme.Accent, 1, 0.15)
    
    button.MouseEnter:Connect(function()
        tween(button, 0.15, {Size = UDim2.new(size.X.Scale, size.X.Offset + 3, size.Y.Scale, size.Y.Offset + 2)})
        tween(button:FindFirstChildOfClass("UIStroke"), 0.15, {Transparency = 0})
    end)
    
    button.MouseLeave:Connect(function()
        tween(button, 0.15, {Size = size})
        tween(button:FindFirstChildOfClass("UIStroke"), 0.15, {Transparency = 0.15})
    end)
    
    return button
end

-- Create Toggle
function UIModule:CreateToggle(parent, position, size, defaultValue)
    local toggleFrame = create("Frame", {
        Parent = parent,
        BackgroundColor3 = defaultValue and self.Theme.Success or self.Theme.Error,
        Size = size or UDim2.new(0, 52, 0, 28),
        Position = position,
        BorderSizePixel = 0,
        ZIndex = 4
    })
    corner(toggleFrame, 14)
    stroke(toggleFrame, defaultValue and self.Theme.Success or self.Theme.Error, 1, 0.3)
    
    local circle = create("Frame", {
        Parent = toggleFrame,
        BackgroundColor3 = self.Theme.Text,
        Size = UDim2.new(0, 22, 0, 22),
        Position = defaultValue and UDim2.new(0, 27, 0.5, -11) or UDim2.new(0, 3, 0.5, -11),
        BorderSizePixel = 0,
        ZIndex = 5
    })
    corner(circle, 11)
    
    local button = create("TextButton", {
        Parent = toggleFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        ZIndex = 6
    })
    
    local toggle = {Frame = toggleFrame, Circle = circle, Button = button, Value = defaultValue}
    
    button.MouseButton1Click:Connect(function()
        toggle.Value = not toggle.Value
        if toggle.Value then
            tween(toggleFrame, 0.3, {BackgroundColor3 = self.Theme.Success})
            tween(circle, 0.3, {Position = UDim2.new(0, 27, 0.5, -11)})
        else
            tween(toggleFrame, 0.3, {BackgroundColor3 = self.Theme.Error})
            tween(circle, 0.3, {Position = UDim2.new(0, 3, 0.5, -11)})
        end
    end)
    
    return toggle
end

-- Create Number Input
function UIModule:CreateNumberInput(parent, position, size, defaultValue, min, max, placeholder)
    local inputBox = create("TextBox", {
        Parent = parent,
        BackgroundColor3 = self.Theme.Secondary,
        Size = size or UDim2.new(0, 60, 0, 32),
        Position = position,
        Text = tostring(defaultValue or ""),
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        BorderSizePixel = 0,
        ZIndex = 4,
        PlaceholderText = placeholder or "",
        TextXAlignment = Enum.TextXAlignment.Center
    })
    corner(inputBox, 10)
    stroke(inputBox, self.Theme.Accent, 1, 0.25)
    
    local input = {Box = inputBox, Value = defaultValue or 0, Min = min, Max = max}
    
    inputBox.FocusLost:Connect(function()
        local num = tonumber(inputBox.Text)
        if num then
            if input.Min and num < input.Min then num = input.Min end
            if input.Max and num > input.Max then num = input.Max end
            input.Value = num
            inputBox.Text = tostring(num)
        else
            inputBox.Text = tostring(input.Value)
        end
    end)
    
    return input
end

-- Create Text Input
function UIModule:CreateTextInput(parent, position, size, defaultValue, placeholder)
    local inputBox = create("TextBox", {
        Parent = parent,
        BackgroundColor3 = self.Theme.Secondary,
        Size = size or UDim2.new(0, 150, 0, 32),
        Position = position,
        Text = defaultValue or "",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        BorderSizePixel = 0,
        ZIndex = 4,
        PlaceholderText = placeholder or "",
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })
    corner(inputBox, 10)
    stroke(inputBox, self.Theme.Accent, 1, 0.25)
    
    -- Add padding
    create("UIPadding", {
        Parent = inputBox,
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    })
    
    local input = {Box = inputBox, Value = defaultValue or ""}
    
    inputBox.FocusLost:Connect(function()
        input.Value = inputBox.Text
    end)
    
    return input
end

-- Create Label
function UIModule:CreateLabel(parent, position, size, text, textSize, isBold)
    local label = create("TextLabel", {
        Parent = parent,
        BackgroundTransparency = 1,
        Size = size,
        Position = position,
        Text = text,
        TextColor3 = self.Theme.Text,
        Font = isBold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextSize = textSize or 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        ZIndex = 4
    })
    return label
end

-- Create Section (Container for elements)
function UIModule:CreateSection(parent, position, size, title)
    local section = create("Frame", {
        Parent = parent,
        BackgroundColor3 = self.Theme.Secondary,
        Size = size,
        Position = position,
        BorderSizePixel = 0,
        ZIndex = 3
    })
    corner(section, 12)
    stroke(section, self.Theme.Accent, 1, 0.2)
    
    if title then
        self:CreateLabel(section, UDim2.new(0, 14, 0, 10), UDim2.new(0.9, 0, 0, 22), title, 14, true)
    end
    
    return section
end

-- Create Slider
function UIModule:CreateSlider(parent, position, size, min, max, defaultValue, increment)
    local sliderFrame = create("Frame", {
        Parent = parent,
        BackgroundColor3 = self.Theme.Secondary,
        Size = size or UDim2.new(0, 200, 0, 32),
        Position = position,
        BorderSizePixel = 0,
        ZIndex = 4
    })
    corner(sliderFrame, 10)
    stroke(sliderFrame, self.Theme.Accent, 1, 0.25)
    
    local fill = create("Frame", {
        Parent = sliderFrame,
        BackgroundColor3 = self.Theme.Accent,
        Size = UDim2.new((defaultValue - min) / (max - min), 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 5
    })
    corner(fill, 10)
    
    local valueLabel = create("TextLabel", {
        Parent = sliderFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = tostring(defaultValue),
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        ZIndex = 6
    })
    
    local slider = {
        Frame = sliderFrame,
        Fill = fill,
        ValueLabel = valueLabel,
        Value = defaultValue,
        Min = min,
        Max = max,
        Increment = increment or 1
    }
    
    local dragging = false
    
    sliderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    sliderFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relativeX = math.clamp((input.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
            local value = min + (max - min) * relativeX
            value = math.floor(value / slider.Increment + 0.5) * slider.Increment
            slider.Value = math.clamp(value, min, max)
            
            fill.Size = UDim2.new((slider.Value - min) / (max - min), 0, 1, 0)
            valueLabel.Text = tostring(slider.Value)
        end
    end)
    
    return slider
end

-- Add elements to tabs
function UIModule:AddToggle(tab, name, description, defaultValue, callback)
    local section = self:CreateSection(tab.Content, UDim2.new(0, 0, 0, 0), UDim2.new(0.8, 0, 0, 65), name)
    
    if description then
        local desc = self:CreateLabel(section, UDim2.new(0, 14, 0, 34), UDim2.new(0.85, 0, 0, 25), description, 11, false)
        desc.TextColor3 = self.Theme.SubText
    end
    
    local toggle = self:CreateToggle(section, UDim2.new(1, -58, 0.5, -14), nil, defaultValue)
    
    toggle.Button.MouseButton1Click:Connect(function()
        if callback then callback(toggle.Value) end
    end)
    
    table.insert(tab.Elements, {Type = "Toggle", Element = toggle})
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, tab.Content.UIListLayout.AbsoluteContentSize.Y)
    
    return toggle
end

function UIModule:AddNumberInput(tab, name, description, defaultValue, min, max, callback)
    local section = self:CreateSection(tab.Content, UDim2.new(0, 0, 0, 0), UDim2.new(0.8, 0, 0, 65), name)
    
    if description then
        local desc = self:CreateLabel(section, UDim2.new(0, 14, 0, 34), UDim2.new(0.7, 0, 0, 25), description, 11, false)
        desc.TextColor3 = self.Theme.SubText
    end
    
    local input = self:CreateNumberInput(section, UDim2.new(1, -66, 0.5, -16), nil, defaultValue, min, max, tostring(defaultValue))
    
    input.Box.FocusLost:Connect(function()
        if callback then callback(input.Value) end
    end)
    
    table.insert(tab.Elements, {Type = "NumberInput", Element = input})
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, tab.Content.UIListLayout.AbsoluteContentSize.Y)
    
    return input
end

function UIModule:AddTextInput(tab, name, description, defaultValue, callback)
    local section = self:CreateSection(tab.Content, UDim2.new(0, 0, 0, 0), UDim2.new(0.8, 0, 0, 65), name)
    
    if description then
        local desc = self:CreateLabel(section, UDim2.new(0, 14, 0, 34), UDim2.new(0.55, 0, 0, 25), description, 11, false)
        desc.TextColor3 = self.Theme.SubText
    end
    
    local input = self:CreateTextInput(section, UDim2.new(1, -160, 0.5, -16), UDim2.new(0, 150, 0, 32), defaultValue, "Enter text...")
    
    input.Box.FocusLost:Connect(function()
        if callback then callback(input.Value) end
    end)
    
    table.insert(tab.Elements, {Type = "TextInput", Element = input})
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, tab.Content.UIListLayout.AbsoluteContentSize.Y)
    
    return input
end

function UIModule:AddSlider(tab, name, description, min, max, defaultValue, increment, callback)
    local section = self:CreateSection(tab.Content, UDim2.new(0, 0, 0, 0), UDim2.new(0.8, 0, 0, 80), name)
    
    if description then
        local desc = self:CreateLabel(section, UDim2.new(0, 14, 0, 34), UDim2.new(0.9, 0, 0, 20), description, 11, false)
        desc.TextColor3 = self.Theme.SubText
    end
    
    local slider = self:CreateSlider(section, UDim2.new(0, 14, 0, 50), UDim2.new(1, -28, 0, 20), min, max, defaultValue, increment)
    
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

function UIModule:AddButton(tab, name, description, callback)
    local section = self:CreateSection(tab.Content, UDim2.new(0, 0, 0, 0), UDim2.new(0.8, 0, 0, 65), nil)
    
    self:CreateLabel(section, UDim2.new(0, 14, 0, 10), UDim2.new(0.5, 0, 0, 22), name, 14, true)
    
    if description then
        local desc = self:CreateLabel(section, UDim2.new(0, 14, 0, 34), UDim2.new(0.55, 0, 0, 25), description, 11, false)
        desc.TextColor3 = self.Theme.SubText
    end
    
    local button = self:CreateButton(section, UDim2.new(1, -85, 0.5, -16), UDim2.new(0, 80, 0, 32), "Execute", 13)
    
    button.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    table.insert(tab.Elements, {Type = "Button", Element = button})
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, tab.Content.UIListLayout.AbsoluteContentSize.Y)
    
    return button
end

-- Update status
function UIModule:UpdateStatus(text, color)
    if self.StatusLabel and self.StatusDot then
        self.StatusLabel.Text = text
        tween(self.StatusLabel, 0.2, {TextColor3 = self.Theme.Text})
        tween(self.StatusDot, 0.2, {BackgroundColor3 = color})
    end
end

-- Create status display
function UIModule:CreateStatusDisplay(tab)
    local statusSection = self:CreateSection(tab.Content, UDim2.new(0, 0, 0, 0), UDim2.new(0.8, 0, 0, 50), nil)
    
    self.StatusDot = create("Frame", {
        Parent = statusSection,
        BackgroundColor3 = self.Theme.Error,
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 15, 0.5, -5),
        BorderSizePixel = 0,
        ZIndex = 3
    })
    corner(self.StatusDot, 5)
    
    self.StatusLabel = self:CreateLabel(statusSection, UDim2.new(0, 32, 0.5, -10), UDim2.new(1, -40, 0, 20), "Inactive", 15, true)
    
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, tab.Content.UIListLayout.AbsoluteContentSize.Y)
    
    return {Dot = self.StatusDot, Label = self.StatusLabel}
end

-- Create control buttons (Stop/Return)
function UIModule:CreateControlButtons(tab, stopCallback, returnCallback)
    local section = self:CreateSection(tab.Content, UDim2.new(0, 0, 0, 0), UDim2.new(0.8, 0, 0, 48), nil)
    
    local stopBtn = self:CreateButton(section, UDim2.new(0, 5, 0.5, -16), UDim2.new(0.48, -7, 0, 32), "Stop", 14)
    stopBtn.BackgroundColor3 = Color3.fromRGB(127, 29, 29)
    
    local returnBtn = self:CreateButton(section, UDim2.new(0.52, 2, 0.5, -16), UDim2.new(0.48, -7, 0, 32), "Return", 14)
    returnBtn.BackgroundColor3 = Color3.fromRGB(30, 64, 175)
    
    stopBtn.MouseButton1Click:Connect(function()
        if stopCallback then stopCallback() end
    end)
    
    returnBtn.MouseButton1Click:Connect(function()
        if returnCallback then returnCallback() end
    end)
    
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, tab.Content.UIListLayout.AbsoluteContentSize.Y)
    
    return {Stop = stopBtn, Return = returnBtn}
end

-- Create team header
function UIModule:CreateTeamHeader(tab)
    local header = self:CreateSection(tab.Content, UDim2.new(0, 0, 0, 0), UDim2.new(0.8, 0, 0, 32), nil)
    self:CreateLabel(header, UDim2.new(0, 12, 0.5, -10), UDim2.new(0.5, 0, 0, 20), "Available Teams", 13, true)
    
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, tab.Content.UIListLayout.AbsoluteContentSize.Y)
    
    return header
end

-- Create team button
function UIModule:CreateTeamButton(tab, teamColor, teamCount, teamColorValue, clickCallback)
    local section = self:CreateSection(tab.Content, UDim2.new(0, 0, 0, 0), UDim2.new(0.8, 0, 0, 50), nil)
    
    -- Color box
    local colorBox = Instance.new("Frame", section)
    colorBox.Size = UDim2.new(0, 26, 0, 26)
    colorBox.Position = UDim2.new(0, 8, 0.5, -13)
    colorBox.BackgroundColor3 = teamColorValue
    colorBox.BorderSizePixel = 0
    colorBox.ZIndex = 4
    corner(colorBox, 8)
    stroke(colorBox, Color3.fromRGB(255, 255, 255), 1, 0.5)
    
    -- Team name
    self:CreateLabel(section, UDim2.new(0, 40, 0.5, -10), UDim2.new(0, 85, 0, 20), teamColor, 12, true)
    
    -- Player count badge
    local badge = Instance.new("Frame", section)
    badge.BackgroundColor3 = Color3.fromRGB(30, 64, 175)
    badge.Size = UDim2.new(0, 32, 0, 20)
    badge.Position = UDim2.new(0, 130, 0.5, -10)
    badge.BorderSizePixel = 0
    badge.ZIndex = 4
    badge.BackgroundTransparency = 0.5
    corner(badge, 6)
    
    local countLabel = self:CreateLabel(badge, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), teamCount, 11, true)
    countLabel.TextXAlignment = Enum.TextXAlignment.Center
    countLabel.TextColor3 = Color3.fromRGB(147, 197, 253)
    
    -- Join button
    local joinBtn = self:CreateButton(section, UDim2.new(1, -95, 0.5, -16), UDim2.new(0, 90, 0, 32), "Join", 11)
    joinBtn.BackgroundColor3 = Color3.fromRGB(30, 64, 175)
    
    if clickCallback then
        joinBtn.MouseButton1Click:Connect(function()
            clickCallback(joinBtn, teamColor)
        end)
    end
    
    table.insert(self.TeleportButtons, joinBtn)
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, tab.Content.UIListLayout.AbsoluteContentSize.Y)
    
    return {Section = section, Button = joinBtn}
end

-- Clear team buttons
function UIModule:ClearTeamButtons(tab)
    for _, child in pairs(tab.Content:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "UIListLayout" then
            -- Check if it's a team button (has a color box as first child)
            local hasColorBox = false
            for _, subChild in pairs(child:GetChildren()) do
                if subChild:IsA("Frame") and subChild.Size == UDim2.new(0, 26, 0, 26) then
                    hasColorBox = true
                    break
                end
            end
            if hasColorBox then
                child:Destroy()
            end
        end
    end
    self.TeleportButtons = {}
end

-- Make draggable
function UIModule:MakeDraggable(frame)
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
function UIModule:ToggleVisibility(show)
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
function UIModule:Cleanup()
    if self.ScreenGui then
        tween(self.Container, 0.3, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)})
        tween(self.Shadow, 0.3, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)})
        wait(0.3)
        self.ScreenGui:Destroy()
    end
end

return UIModule
