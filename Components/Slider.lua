local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local ConnectTheme = require(Components:FindFirstChild("ConnectTheme"))
local TextInput = require(Components:FindFirstChild("TextInput"))

---

local Slider = Roact.PureComponent:extend("Slider")

Slider.init = function(self)
    self.slider = Roact.createRef()

    self.updateValue = function(cursorPosition)
        local distanceFromCenter = cursorPosition - self.state.sliderCenter
        local value = math.clamp((distanceFromCenter.X / self.state.sliderSize) + 0.5, 0, 1)

        self.props.valueChanged(value)
    end

    self:setState({
        tracking = false,
    })
end

Slider.didMount = function(self)
    self.inputChanged = self.props.editorInputChanged:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        if (input.UserInputType ~= Enum.UserInputType.MouseMovement) then return end
        if (not self.state.tracking) then return end
        
        local inputPosition = input.Position

        self.updateValue(Vector2.new(inputPosition.X, inputPosition.Y))
    end)

    do
        local slider = self.slider:getValue()
        local sliderPosition = slider.AbsolutePosition
        local sliderSize = slider.AbsoluteSize

        self:setState({
            sliderCenter = sliderPosition + (sliderSize / 2),
            sliderSize = sliderSize.X
        })
    end
end

Slider.willUnmount = function(self)
    if (self.inputChanged) then
        self.inputChanged:Disconnect()
        self.inputChanged = nil
    end
end

Slider.render = function(self)
    local theme = self.props.theme
    local keypointsFrame

    if (self.props.keypoints) then
        local keypointComponents = {}

        for i = 1, #self.props.keypoints do
            local keypoint = self.props.keypoints[i]

            keypointComponents[i] = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(keypoint.value, 0, 0.5, 0),
                LayoutOrder = i,

                displayType = "color",
                color = keypoint.color,
                
                onActivated = function()
                    self.props.valueChanged(keypoint.value)
                end
            })
        end

        keypointsFrame = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, Style.StandardButtonSize / 2, 1, 0),
            Size = UDim2.new(1, -80, 0, Style.StandardButtonSize),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, keypointComponents)
    end

    return Roact.createElement("Frame", {
        AnchorPoint = self.props.AnchorPoint,
        Position = self.props.Position,
        Size = self.props.keypoints and UDim2.new(1, 0, 0, 66) or UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = self.props.layoutOrder
    }, {
        NameLabel = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Font = Style.StandardFont,
            TextSize = Style.StandardTextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Text = self.props.sliderLabel,
            TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
        }),

        SliderBorder = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 0, 0, 18),
            Size = UDim2.new(1, -58, 0, Style.StandardButtonSize),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            BackgroundColor3 = theme:GetColor(
                Enum.StudioStyleGuideColor.InputFieldBorder,
                self.state.tracking and Enum.StudioStyleGuideModifier.Selected or nil
            ),
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, 4),
            }),

            Slider = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundTransparency = 0,
                BorderSizePixel = 1,
                ClipsDescendants = true,

                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder),

                [Roact.Ref] = self.slider,

                [Roact.Event.InputBegan] = function(_, input)
                    if (self.state.inputFocused) then return end
                    if (input.UserInputType ~= Enum.UserInputType.MouseButton1) then return end

                    local inputPosition = input.Position

                    self:setState({
                        tracking = true,
                    })

                    self.updateValue(Vector2.new(inputPosition.X, inputPosition.Y))
                end,
    
                [Roact.Event.InputEnded] = function(_, input)
                    if (input.UserInputType ~= Enum.UserInputType.MouseButton1) then return end
                    if (not self.state.tracking) then return end
                    
                    self:setState({
                        tracking = false,
                    })
                end,

                [Roact.Change.AbsolutePosition] = function(obj)
                    local sliderPosition = obj.AbsolutePosition
                    local sliderSize = obj.AbsoluteSize

                    self:setState({
                        sliderCenter = sliderPosition + (sliderSize / 2),
                        sliderSize = sliderSize.X
                    })
                end,
    
                [Roact.Change.AbsoluteSize] = function(obj)
                    local sliderPosition = obj.AbsolutePosition
                    local sliderSize = obj.AbsoluteSize

                    self:setState({
                        sliderCenter = sliderPosition + (sliderSize / 2),
                        sliderSize = sliderSize.X
                    })
                end,
            }, {
                UICorner = Roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                }),

                UIGradient = Roact.createElement("UIGradient", {
                    Color = self.props.sliderGradient
                }),
                
                Marker = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(self.props.value, 0, 0.5, 0),
                    Size = UDim2.new(0, Style.MarkerSize, 0, Style.MarkerSize),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 1,

                    BackgroundColor3 = self.props.markerColor or theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)
                }, {
                    UICorner = Roact.createElement("UICorner", {
                        CornerRadius = UDim.new(1, 0),
                    }),
                }),
            }),
        }),

        Keypoints = keypointsFrame,

        InputFrame = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 18),
            Size = UDim2.new(0, 50, 0, Style.StandardButtonSize),
            BackgroundTransparency = 1,
            BorderSizePixel = 0
        }, {
            Input = Roact.createElement(TextInput, {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(1, self.props.unitLabel and -(10 + Style.MinorElementPadding) or 0, 1, 0),
    
                TextXAlignment = Enum.TextXAlignment.Center,
                Text = self.props.valueToText(self.props.value),
    
                isTextAValidValue = function(text)
                    return self.props.textToValue(text) and true or false
                end,

                canClear = false,
                onTextChanged = function(newText)
                    local newValue = self.props.textToValue(newText)
    
                    if (type(newValue) ~= "number") then return end
                    if ((newValue < 0) or (newValue > 1)) then return end
    
                    self.props.valueChanged(newValue)
                end
            }),

            UnitLabel = self.props.unitLabel and
                Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 10, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Font = Style.StandardFont,
                    TextSize = Style.StandardTextSize,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    Text = self.props.unitLabel,

                    TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
                })
            or nil
        })
    })
end

return ConnectTheme(Slider)