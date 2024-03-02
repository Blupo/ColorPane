-- A page for picking colors from gradients

local root = script.Parent.Parent
local Common = root.Common

local CommonPluginModules = Common.PluginModules
local Style = require(CommonPluginModules.Style)

local CommonIncludes = Common.Includes
local Gradient = require(CommonIncludes.Color).Gradient
local Roact = require(CommonIncludes.RoactRodux.Roact)
local RoactRodux = require(CommonIncludes.RoactRodux.RoactRodux)

local CommonComponents = Common.Components
local ConnectTheme = require(CommonComponents.ConnectTheme)

local StandardComponents = CommonComponents.StandardComponents
local StandardScrollingFrame = require(StandardComponents.ScrollingFrame)
local StandardTextLabel = require(StandardComponents.TextLabel)
local StandardUICorner = require(StandardComponents.UICorner)
local StandardUIListLayout = require(StandardComponents.UIListLayout)
local StandardUIPadding = require(StandardComponents.UIPadding)

local PluginModules = root.PluginModules
local BuiltInGradients = require(PluginModules.BuiltInGradients)
local ColorEditorInputSignals = require(PluginModules.EditorInputSignals).ColorEditor
local PluginEnums = require(PluginModules.PluginEnums)

---

--[[
    props
        LayoutOrder?

        gradientName: string
        gradient: ColorSequence

        valuePicked: (number) -> nil

    store props
        theme: StudioTheme
]]

local GradientPicker = Roact.PureComponent:extend("GradientPicker")

GradientPicker.init = function(self)
    self.center, self.updateCenter = Roact.createBinding(Vector2.new(0, 0))
    self.size, self.updateSize = Roact.createBinding(0)

    self.pickValue = function(cursorPosition)
        local distanceFromCenter = cursorPosition - self.center:getValue()
        local value = math.clamp((distanceFromCenter.X / self.size:getValue()) + 0.5, 0, 1)

        self.props.valuePicked(value)
    end

    self:setState({
        tracking = false,
    })
end

GradientPicker.didMount = function(self)
    self.mousePositionChanged = ColorEditorInputSignals.MousePositionChanged.Event:subscribe(function(cursorPosition: Vector2)
        if (not self.state.tracking) then return end

        self.pickValue(cursorPosition)
    end)
end

GradientPicker.willUnmount = function(self)
    if (self.mousePositionChanged) then
        self.mousePositionChanged:unsubscribe()
    end
end

GradientPicker.render = function(self)
    local theme = self.props.theme

    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, (
            Style.Constants.StandardTextSize +
            Style.Constants.StandardInputHeight +
            Style.Constants.MinorElementPadding
        )),

        LayoutOrder = self.props.LayoutOrder,
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, {
        NameLabel = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
            Text = self.props.gradientName,
        }),

        Border = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardInputHeight),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            BackgroundColor3 = theme:GetColor(
                Enum.StudioStyleGuideColor.InputFieldBorder,
                if self.state.tracking then Enum.StudioStyleGuideModifier.Selected else nil
            ),
        }, {
            UICorner = Roact.createElement(StandardUICorner),

            Picker = Roact.createElement("Frame", {
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

                    self.pickValue(Vector2.new(inputPosition.X, inputPosition.Y))
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

                    self.updateCenter(sliderPosition + (sliderSize / 2))
                    self.updateSize(sliderSize.X)
                end,
    
                [Roact.Change.AbsoluteSize] = function(obj)
                    local sliderPosition = obj.AbsolutePosition
                    local sliderSize = obj.AbsoluteSize

                    self.updateCenter(sliderPosition + (sliderSize / 2))
                    self.updateSize(sliderSize.X)
                end,
            }, {
                UICorner = Roact.createElement(StandardUICorner),

                UIGradient = Roact.createElement("UIGradient", {
                    Color = self.props.gradient
                }),
            }),
        }),
    })
end

---

--[[
    store props

        gradients
        setColor: (Color) -> nil
]]

local GradientPickers = Roact.PureComponent:extend("GradientPickers")

GradientPickers.init = function(self)
    self.listLength, self.updateListLength = Roact.createBinding(0)
end

GradientPickers.render = function(self)
    local userGradients = self.props.gradients
    local pickerElements = {}

    local addGradient = function(gradientInfo)
        local gradient = Gradient.new(gradientInfo.keypoints)

        table.insert(pickerElements, Roact.createElement(GradientPicker, {
            LayoutOrder = #pickerElements + 1,

            gradientName = gradientInfo.name,
            gradient = gradient:colorSequence(nil, gradientInfo.colorSpace, gradientInfo.hueAdjustment),

            valuePicked = function(value)
                self.props.setColor(gradient:color(value, gradientInfo.colorSpace, gradientInfo.hueAdjustment))
            end,
        }))
    end

    for i = 1, #BuiltInGradients do
        addGradient(BuiltInGradients[i])
    end

    for i = 1, #userGradients do
        addGradient(userGradients[i])
    end

    pickerElements.UIPadding = Roact.createElement(StandardUIPadding, {
        paddings = {0, 0, 0, Style.Constants.SpaciousElementPadding}
    })

    pickerElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        Padding = UDim.new(0, Style.Constants.SpaciousElementPadding),

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateListLength(obj.AbsoluteContentSize.Y)
        end,

        preset = 1,
    })

    return Roact.createElement(StandardScrollingFrame, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        
        CanvasSize = self.listLength:map(function(length)
            return UDim2.new(0, 0, 0, length)
        end),
    }, pickerElements)
end

---

GradientPicker = ConnectTheme(GradientPicker)

return RoactRodux.connect(function(state)
    return {
        gradients = state.gradientEditor.palette,
    }
end, function(dispatch)
    return {
        setColor = function(color)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_SetColor,
                color = color
            })
        end,
    }
end)(GradientPickers)