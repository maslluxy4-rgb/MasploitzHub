-- Masploitz Hub UI Module
-- Upload this as ui.lua to your GitHub repo

local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

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
    return self
end

-- Set Theme
function UIModule:SetTheme(themeName)
    self.Theme = Themes[themeName] or Themes.Dark
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

-- Create Dropdown
function UIModule:CreateDropdown(parent, position, size, options, defaultIndex)
    local dropdown = create("Frame", {
        Parent = parent,
        BackgroundColor3 = self.Theme.Secondary,
        Size = size or UDim2.new(0, 150, 0, 32),
        Position = position,
        BorderSizePixel = 0,
        ZIndex = 4
    })
    corner(dropdown, 10)
    stroke(dropdown, self.Theme.Accent, 1, 0.25)
    
    local label = create("TextLabel", {
        Parent = dropdown,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Text = options[defaultIndex or 1] or "Select",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5
    })
    
    local arrow = create("TextLabel", {
        Parent = dropdown,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -25, 0, 0),
        Text = "▼",
        TextColor3 = self.Theme.SubText,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        ZIndex = 5
    })
    
    local button = create("TextButton", {
        Parent = dropdown,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        ZIndex = 6
    })
    
    local dropdownObj = {
        Frame = dropdown,
        Label = label,
        Options = options,
        SelectedIndex = defaultIndex or 1,
        SelectedValue = options[defaultIndex or 1] or options[1]
    }
    
    -- Simple cycling dropdown (expand to full dropdown menu if needed)
    button.MouseButton1Click:Connect(function()
        dropdownObj.SelectedIndex = (dropdownObj.SelectedIndex % #options) + 1
        dropdownObj.SelectedValue = options[dropdownObj.SelectedIndex]
        label.Text = dropdownObj.SelectedValue
    end)
    
    return dropdownObj
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

return UIModule
