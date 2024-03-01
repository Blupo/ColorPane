--[[
    A color picker containing a hue ring and saturation-value plane
    with color harmony guides
]]

local root = script.Parent.Parent
local Common = root.Common

local CommonPluginModules = Common.PluginModules
local Style = require(CommonPluginModules.Style)

local CommonIncludes = Common.Includes
local Color = require(CommonIncludes.Color).Color
local Roact = require(CommonIncludes.RoactRodux.Roact)
local RoactRodux = require(CommonIncludes.RoactRodux.RoactRodux)

local CommonComponents = Common.Components
local ConnectTheme = require(CommonComponents.ConnectTheme)
local StandardUICorner = require(CommonComponents.StandardComponents.UICorner)

local PluginModules = root.PluginModules
local ColorEditorInputSignals = require(PluginModules.EditorInputSignals).ColorEditor
local PluginEnums = require(PluginModules.PluginEnums)

local Components = root.Components
local ButtonBar = require(Components.ButtonBar)

---

local EDITOR_KEY = PluginEnums.EditorKey.ColorWheel
local ANALOGY_ANGLE = math.deg(math.pi / 6)

local harmonies = {
    {
        name = "None",
        image = Style.Images.NoHarmonyButtonIcon,
    },

    {
        name = "Complementary",
        image = Style.Images.ComplementaryHarmonyButtonIcon,
    },

    {
        name = "Analogous",
        image = Style.Images.AnalogousHarmonyButtonIcon,
    },

    {
        name = "Triadic",
        image = Style.Images.TriadicHarmonyButtonIcon,
    },

    {
        name = "SplitComplementary",
        image = Style.Images.SplitComplementaryButtonIcon,
    },

    {
        name = "Square",
        image = Style.Images.SquareHarmonyButtonIcon,
    },

    {
        name = "Tetradic",
        image = Style.Images.TetradicHarmonyButtonIcon,
    },

    {
        name = "Hexagon",
        image = Style.Images.HexagonalHarmonyButtonIcon,
    },
}

---

--[[
    props
        angle: number
        ringWidth: number
        wheelRadius: Binding<number>

        onActivated: () -> nil

    store props
        theme: StudioTheme
]]

local HueHarmonyMarker = Roact.PureComponent:extend("HueHarmonyMarker")

HueHarmonyMarker.render = function(self)
    local theme = self.props.theme

    local angle = self.props.angle
    local ringWidth = self.props.ringWidth

    return Roact.createElement("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = Style.UDim2.MarkerSize,

        Position = self.props.wheelRadius:map(function(wheelRadius)
            local rad = math.rad(angle)

            return UDim2.new(
                0.5, math.cos(rad) * (wheelRadius - (ringWidth / 2)),
                0.5, -math.sin(rad) * (wheelRadius - (ringWidth / 2))
            )
        end),

        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 2,

        Text = "",
        TextTransparency = 1,

        BackgroundColor3 = Color.fromHSB(angle, 1, 1):bestContrastingColor(
            Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
            Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)):invert()
        ):toColor3(),

        [Roact.Event.Activated] = self.props.onActivated,
    })
end

---

--[[
    props

        ringWidth: number

    store props

        theme: StudioTheme
        color: Color
        editor: string
        harmony: number

        setColor: (Color) -> nil
        setHarmony: (number) -> nil
]]

local ColorWheel = Roact.PureComponent:extend("ColorWheel")

ColorWheel.init = function(self, initProps)
    local initH, initS, initB = initProps.color:toHSB()

    self.planeSize, self.updatePlaneSize = Roact.createBinding(Vector2.new(0, 0))
    self.wheelCenter, self.updateWheelCenter = Roact.createBinding(Vector2.new(0, 0))
    self.wheelRadius, self.updateWheelRadius = Roact.createBinding(0)

    self.updateH = function(cursorPosition)
        local distanceFromWheelCenter = self.wheelCenter:getValue() - cursorPosition
        local mouseAngle = math.atan2(distanceFromWheelCenter.Y, -distanceFromWheelCenter.X)

        local hueAngle
        local h

        -- calculate angle from [0, 2pi)
        if ((mouseAngle >= 0) and (mouseAngle <= math.pi)) then
            hueAngle = mouseAngle
        else
            hueAngle = mouseAngle + (2 * math.pi)
        end

        h = math.deg(hueAngle)

        self:setState({
            captureFocus = (self.props.editor ~= EDITOR_KEY) and true or nil,
            h = h,
        })

        self.props.setColor(Color.fromHSB(h, self.state.s, self.state.b))
    end

    self.updateSB = function(cursorPosition)
        local distanceFromWheelCenter = cursorPosition - self.wheelCenter:getValue()
        local planeSize = self.planeSize:getValue()

        local s = math.clamp((distanceFromWheelCenter.X / planeSize) + 0.5, 0, 1)
        local b = 1 - math.clamp((distanceFromWheelCenter.Y / planeSize) + 0.5, 0, 1)

        self:setState({
            captureFocus = (self.props.editor ~= EDITOR_KEY) and true or nil,
            s = s,
            b = b
        })

        self.props.setColor(Color.fromHSB(self.state.h, s, b))
    end

    self:setState({
        trackingH = false,
        trackingSB = false,

        h = (initH ~= initH) and 0 or initH,
        s = initS,
        b = initB,
    })
end

ColorWheel.getDerivedStateFromProps = function(props, state)
    if (props.editor == EDITOR_KEY) then return end
    
    if (state.captureFocus) then
        return {
            captureFocus = Roact.None,
        }
    end

    local h, s, b = props.color:toHSB()
    if ((h == state.h) and (s == state.s) and (b == state.b)) then return end

    return {
        h = (h ~= state.h) and ((h ~= h) and 0 or h) or nil,
        s = (s ~= state.s) and s or nil,
        b = (b ~= state.b) and b or nil,
    }
end

ColorWheel.didMount = function(self)
    self.cursorPositionChanged = ColorEditorInputSignals.CursorPositionChanged:subscribe(function(cursorPosition: Vector2)
        if (self.state.trackingH) then
            self.updateH(cursorPosition)
        end

        if (self.state.trackingSB) then
            self.updateSB(cursorPosition)
        end
    end)
end

ColorWheel.willUnmount = function(self)
    if (self.cursorPositionChanged) then
        self.cursorPositionChanged:unsubscribe()
        self.cursorPositionChanged = nil
    end
end

ColorWheel.render = function(self)
    local theme = self.props.theme
    local editor = self.props.editor
    local harmonyIndex = self.props.harmony

    local h, s, b = self.state.h, self.state.s, self.state.b

    local color = Color.fromHSB(h, s, b)
    local pureHueColor = Color.fromHSB(h, 1, 1)

    local hRad = math.rad(h)

    local hueMarkers = {
        PrimaryMarker = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = 2,

            Size = UDim2.new(
                0, self.props.ringWidth + (self.state.trackingH and 10 or -10),
                0, self.props.ringWidth + (self.state.trackingH and 10 or -10)
            ),

            Position = self.wheelRadius:map(function(wheelRadius)
                return UDim2.new(
                    0.5, math.cos(hRad) * (wheelRadius - (self.props.ringWidth / 2)),
                    0.5, -math.sin(hRad) * (wheelRadius - (self.props.ringWidth / 2))
                )
            end),

            BackgroundColor3 = pureHueColor:bestContrastingColor(
                Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)):invert()
            ):toColor3(),
        }, {
            UICorner = Roact.createElement(StandardUICorner, { circular = true }),

            Indicator = self.state.trackingH and
                Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(1, -10, 1, -10),
                    
                    BackgroundColor3 = pureHueColor:toColor3()
                }, {
                    UICorner = Roact.createElement(StandardUICorner, { circular = true }),
                })
            or nil
        })
    }

    if (harmonies[harmonyIndex]) then
        local harmony = harmonies[harmonyIndex]
        local harmonicColors

        if (harmony.name == "None") then
            harmonicColors = {}
        elseif (harmony.name == "Hexagon") then
            harmonicColors = {}

            for i = 1, 5 do
                table.insert(harmonicColors, Color.fromHSB((h + (360 / 6 * i) % 360), 1, 1))
            end
        else
            harmonicColors = pureHueColor:harmonies(harmony.name, ANALOGY_ANGLE)
        end

        for i = 1, #harmonicColors do
            local harmonicColor = harmonicColors[i]
            local harmonicH = harmonicColor:toHSB()
            harmonicH = (harmonicH ~= harmonicH) and 0 or harmonicH

            hueMarkers[i] = Roact.createElement(HueHarmonyMarker, {
                angle = harmonicH,
                wheelRadius = self.wheelRadius,
                ringWidth = self.props.ringWidth,

                onActivated = function()
                    self:setState({
                        captureFocus = (editor ~= EDITOR_KEY) and true or nil,
                        h = harmonicH,
                    })

                    self.props.setColor(Color.fromHSB(harmonicH, s, b))
                end,
            })
        end
    end

    return Roact.createFragment({
        HarmonyOptions = Roact.createElement(ButtonBar, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = Style.UDim2.ButtonBarSize,

            displayType = "image",
            selected = harmonyIndex,
            buttons = harmonies,
            onButtonActivated = self.props.setHarmony,
        }),

        WheelContainer = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.new(1, 0, 1, -(Style.Constants.StandardButtonHeight + Style.Constants.MajorElementPadding)),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = false,
        }, {
            -- h-wheel, sv-plane
            HueWheel = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(1, -0, 1, -0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = false,

                Image = Style.Images.HueWheel,

                [Roact.Event.InputBegan] = function(obj, input)
                    if (input.UserInputType ~= Enum.UserInputType.MouseButton1) then return end
                    
                    local inputPosition = input.Position
                    local mousePosition = Vector2.new(inputPosition.X, inputPosition.Y)

                    local hueWheelSize = obj.AbsoluteSize
                    local upperRadius = hueWheelSize.X / 2
                    local lowerRadius =  upperRadius - self.props.ringWidth

                    local distanceFromWheelCenter = mousePosition - self.wheelCenter:getValue()
                    
                    if ((distanceFromWheelCenter.Magnitude >= lowerRadius) and (distanceFromWheelCenter.Magnitude <= upperRadius)) then
                        self:setState({
                            trackingH = true,
                        })

                        self.updateH(Vector2.new(inputPosition.X, inputPosition.Y))
                    end
                end,

                [Roact.Event.InputEnded] = function(_, input)
                    if (input.UserInputType ~= Enum.UserInputType.MouseButton1) then return end
                    if (not self.state.trackingH) then return end
                    
                    self:setState({
                        trackingH = false,
                    })
                end,

                [Roact.Change.AbsolutePosition] = function(obj)
                    local hueWheelPosition = obj.AbsolutePosition
                    local hueWheelSize = obj.AbsoluteSize

                    self.updateWheelCenter(hueWheelPosition + (hueWheelSize / 2))
                    self.updateWheelRadius(hueWheelSize.X / 2)
                end,

                [Roact.Change.AbsoluteSize] = function(obj)
                    local hueWheelPosition = obj.AbsolutePosition
                    local hueWheelSize = obj.AbsoluteSize

                    self.updateWheelCenter(hueWheelPosition + (hueWheelSize / 2))
                    self.updateWheelRadius(hueWheelSize.X / 2)
                end,
            }, {
                UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
                    AspectRatio = 1,
                    AspectType = Enum.AspectType.FitWithinMaxSize,
                    DominantAxis = Enum.DominantAxis.Width
                }),

                UICorner = Roact.createElement(StandardUICorner, { circular = true }),

                RingOverlay = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Size = UDim2.new(1, -(self.props.ringWidth * 2), 1, -(self.props.ringWidth * 2)),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,

                    BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)
                }, {
                    UICorner = Roact.createElement(StandardUICorner, { circular = true }),
                }),

                Markers = Roact.createFragment(hueMarkers)
            }),

            SBPlaneContainer = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(1, -(self.props.ringWidth * 2) - 0, 1, -(self.props.ringWidth * 2) - 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = false,
                ZIndex = 2,
            }, {
                UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
                    AspectRatio = 1,
                    AspectType = Enum.AspectType.FitWithinMaxSize,
                    DominantAxis = Enum.DominantAxis.Width
                }),

                SBPlane = Roact.createElement("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    --[[
                        the side length of largest square that fits inside a circle can be found with
                        sqrt(d/2), where d is the diameter of the circle
                    ]]
                    Size = UDim2.new(math.sqrt(1/2), -8, math.sqrt(1/2), -8),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    ClipsDescendants = false,
                    Image = Style.Images.SBPlane,

                    BackgroundColor3 = Color3.new(1, 1, 1),
                    ImageColor3 = pureHueColor:toColor3(),

                    [Roact.Event.InputBegan] = function(_, input)
                        if (input.UserInputType ~= Enum.UserInputType.MouseButton1) then return end
                        if (self.state.trackingH) then return end

                        local inputPosition = input.Position
                        
                        self:setState({
                            trackingSB = true,
                        })

                        self.updateSB(Vector2.new(inputPosition.X, inputPosition.Y))
                    end,

                    [Roact.Event.InputEnded] = function(_, input)
                        if (input.UserInputType ~= Enum.UserInputType.MouseButton1) then return end
                        if (not self.state.trackingSB) then return end

                        self:setState({
                            trackingSB = false,
                        })
                    end,

                    [Roact.Change.AbsoluteSize] = function(obj)
                        self.updatePlaneSize(obj.AbsoluteSize.X)
                    end,
                }, {
                    VGradient = Roact.createElement("UIGradient", {
                        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0, 0, 0)),
                        Offset = Vector2.new(0, 0),
                        Rotation = 90,
                        Transparency = NumberSequence.new(0),
                        Enabled = true,
                    }),

                    MarkerContainer = Roact.createElement("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(s, 0, 1 - b, 0),
                        Size = UDim2.new(0, 10, 0, 10),
                        BackgroundTransparency = 0,
                        BorderSizePixel = 0,

                        BackgroundColor3 = color:bestContrastingColor(
                            Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                            Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)):invert()
                        ):toColor3(),
                    }, {
                        UICorner = Roact.createElement(StandardUICorner, { circular = true }),

                        Indicator = Roact.createElement("Frame", {
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Size = UDim2.new(1, -2, 1, -2),
                            Position = UDim2.new(0.5, 0, 0.5, 0),
                            BackgroundTransparency = 0,
                            BorderSizePixel = 0,
                            
                            BackgroundColor3 = color:toColor3(),
                        }, {
                            UICorner = Roact.createElement(StandardUICorner, { circular = true }),
                        })
                    })
                })
            })
        }),
    })
end

---

HueHarmonyMarker = ConnectTheme(HueHarmonyMarker)

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,
        color = state.colorEditor.color,
        editor = state.colorEditor.authoritativeEditor,
        harmony = state.sessionData.lastHueHarmony,
    }
end, function(dispatch)
    return {
        setColor = function(newColor)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_SetColor,
                color = newColor,
                editor = EDITOR_KEY
            })
        end,

        setHarmony = function(newHarmony)
            dispatch({
                type = PluginEnums.StoreActionType.UpdateSessionData,
                slice = {
                    lastHueHarmony = newHarmony
                }
            })
        end
    }
end)(ColorWheel)