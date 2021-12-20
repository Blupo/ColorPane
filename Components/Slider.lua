local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local ColorEditorInputSignals = require(PluginModules:FindFirstChild("ColorEditorInputSignals"))
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local ConnectTheme = require(Components:FindFirstChild("ConnectTheme"))
local TextInput = require(Components:FindFirstChild("TextInput"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardTextLabel = StandardComponents.TextLabel
local StandardUICorner = StandardComponents.UICorner

---

--[[
    props

        AnchorPoint?
        Position?
        LayoutOrder?

        sliderLabel: string
        unitLabel: string?
        value: number

        markerColor: Color3?
        sliderGradient: ColorSequence

        keypoints: array<{
            value: number,
            color: Color3
        }>?

        valueToText: (number) -> string
        textToValue: (string) -> number?
        valueChanged: (number) -> nil

    store props

        theme: StudioTheme
]]

local Slider = Roact.PureComponent:extend("Slider")

Slider.init = function(self)
    self.sliderCenter, self.updateSliderCenter = Roact.createBinding(Vector2.new(0, 0))
    self.sliderSize, self.updateSliderSize = Roact.createBinding(0)

    self.updateValue = function(cursorPosition)
        local distanceFromCenter = cursorPosition - self.sliderCenter:getValue()
        local value = math.clamp((distanceFromCenter.X / self.sliderSize:getValue()) + 0.5, 0, 1)

        self.props.valueChanged(value)
    end

    self:setState({
        tracking = false,
    })
end

Slider.didMount = function(self)
    self.inputChanged = ColorEditorInputSignals.InputChanged:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        if (input.UserInputType ~= Enum.UserInputType.MouseMovement) then return end
        if (not self.state.tracking) then return end
        
        local inputPosition = input.Position

        self.updateValue(Vector2.new(inputPosition.X, inputPosition.Y))
    end)
end

Slider.willUnmount = function(self)
    if (self.inputChanged) then
        self.inputChanged:Disconnect()
        self.inputChanged = nil
    end
end

Slider.render = function(self)
    local theme = self.props.theme
    local value = self.props.value

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
            Size = UDim2.new(1, -(60 + Style.StandardButtonSize + Style.MinorElementPadding), 0, Style.StandardButtonSize),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, keypointComponents)
    end

    return Roact.createElement("Frame", {
        AnchorPoint = self.props.AnchorPoint,
        Position = self.props.Position,
        Size = self.props.keypoints and UDim2.new(1, 0, 0, 66) or UDim2.new(1, 0, 0, 40),
        LayoutOrder = self.props.LayoutOrder,
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, {
        NameLabel = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, 14),
            Text = self.props.sliderLabel,
        }),

        SliderBorder = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 0, 0, 18),
            Size = UDim2.new(1, -(60 + Style.MinorElementPadding), 0, Style.StandardButtonSize),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            BackgroundColor3 = theme:GetColor(
                Enum.StudioStyleGuideColor.InputFieldBorder,
                self.state.tracking and Enum.StudioStyleGuideModifier.Selected or nil
            ),
        }, {
            UICorner = Roact.createElement(StandardUICorner),

            Slider = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundTransparency = 0,
                BorderSizePixel = 1,
                ClipsDescendants = true,

                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder),

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

                    self.updateSliderCenter(sliderPosition + (sliderSize / 2))
                    self.updateSliderSize(sliderSize.X)
                end,
    
                [Roact.Change.AbsoluteSize] = function(obj)
                    local sliderPosition = obj.AbsolutePosition
                    local sliderSize = obj.AbsoluteSize

                    self.updateSliderCenter(sliderPosition + (sliderSize / 2))
                    self.updateSliderSize(sliderSize.X)
                end,
            }, {
                UICorner = Roact.createElement(StandardUICorner),

                UIGradient = Roact.createElement("UIGradient", {
                    Color = self.props.sliderGradient
                }),
                
                Marker = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(value, 0, 0.5, 0),
                    Size = UDim2.new(0, Style.MarkerSize, 0, Style.MarkerSize),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 1,

                    BackgroundColor3 = self.props.markerColor or theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)
                }, {
                    UICorner = Roact.createElement(StandardUICorner, { circular = true }),
                }),
            }),
        }),

        Keypoints = keypointsFrame,

        InputFrame = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 18),
            Size = UDim2.new(0, 60, 0, Style.StandardButtonSize),
            BackgroundTransparency = 1,
            BorderSizePixel = 0
        }, {
            Input = Roact.createElement(TextInput, {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(1, self.props.unitLabel and -(10 + Style.MinorElementPadding) or 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Center,
                Text = self.props.valueToText(value),

                selectTextOnFocus = true,
    
                isTextAValidValue = function(text)
                    return self.props.textToValue(text) and true or false
                end,

                onSubmit = function(newText)
                    local newValue = self.props.textToValue(newText)
    
                    if (type(newValue) ~= "number") then return end
                    if ((newValue < 0) or (newValue > 1)) then return end
    
                    self.props.valueChanged(newValue)
                end
            }),

            UnitLabel = self.props.unitLabel and
                Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 10, 1, 0),
                    Text = self.props.unitLabel,
                })
            or nil
        })
    })
end

---

return ConnectTheme(Slider)