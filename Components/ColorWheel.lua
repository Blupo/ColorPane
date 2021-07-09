local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Color = require(PluginModules:FindFirstChild("Color"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local Style = require(PluginModules:FindFirstChild("Style"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local ButtonBar = require(Components:FindFirstChild("ButtonBar"))
local ConnectTheme = require(Components:FindFirstChild("ConnectTheme"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardUICorner = StandardComponents.UICorner

---

local ANALOGY_ANGLE = math.pi / 5

local shallowCompare = Util.shallowCompare

local harmonies = {
    {
        name = "None",
        image = Style.HarmonyNoneImage,
        order = 1,

        numAngles = 0,
        getAngles = function() return {} end,
    },

    {
        name = "Complement",
        image = Style.HarmonyComplementImage,
        order = 2,

        numAngles = 1,
        getAngles = function(angle)
            return {(angle + math.pi) % (2 * math.pi)}
        end
    },

    {
        name = "Triad",
        image = Style.HarmonyTriadImage,
        order = 4,

        numAngles = 2,
        getAngles = function(angle)
            return {
                (angle + ((2 * math.pi) / 3)) % (2 * math.pi),
                (angle + ((4 * math.pi) / 3)) % (2 * math.pi)
            }
        end
    },

    {
        name = "Square",
        image = Style.HarmonySquareImage,
        order = 6,

        numAngles = 3,
        getAngles = function(angle)
            return {
                (angle + (math.pi / 2)) % (2 * math.pi),
                (angle + ((2 * math.pi) / 2)) % (2 * math.pi),
                (angle + ((3 * math.pi) / 2)) % (2 * math.pi)
            }
        end
    },

    {
        name = "Hexagon",
        image = Style.HarmonyHexagonImage,
        order = 8,

        numAngles = 5,
        getAngles = function(angle)
            return {
                (angle + (math.pi / 3)) % (2 * math.pi),
                (angle + ((2 * math.pi) / 3)) % (2 * math.pi),
                (angle + ((3 * math.pi) / 3)) % (2 * math.pi),
                (angle + ((4 * math.pi) / 3)) % (2 * math.pi),
                (angle + ((5 * math.pi) / 3)) % (2 * math.pi),
            }
        end
    },

    {
        name = "Analogous",
        image = Style.HarmonyAnalogousImage,
        order = 3,

        numAngles = 2,
        getAngles = function(angle)
            return {
                (angle + ANALOGY_ANGLE) % (2 * math.pi),
                (angle - ANALOGY_ANGLE) % (2 * math.pi),
            }
        end
    },

    {
        name = "Split Complement",
        image = Style.HarmonySplitComplementImage,
        order = 5,
            
        numAngles = 2,
        getAngles = function(angle)
            local complementAngle = angle + math.pi

            return {
                (complementAngle + ANALOGY_ANGLE) % (2 * math.pi),
                (complementAngle - ANALOGY_ANGLE) % (2 * math.pi)
            }
        end
    },

    {
        name = "Rectangle",
        image = Style.HarmonyRectangleImage,
        order = 7,

        numAngles = 3,
        getAngles = function(angle)
            local analogy1 = angle + ANALOGY_ANGLE
            local complement = angle + math.pi
            local analogy2 = complement + ANALOGY_ANGLE

            return {
                analogy1 % (2 * math.pi),
                complement % (2 * math.pi),
                analogy2 % (2 * math.pi)
            }
        end
    }
}

---

local HueHarmonyMarker = Roact.PureComponent:extend("HueHarmonyMarker")

HueHarmonyMarker.render = function(self)
    local theme = self.props.theme

    return Roact.createElement("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, Style.MarkerSize, 0, Style.MarkerSize),

        Position = Roact.joinBindings({
            h = self.props.h,
            wheelRadius = self.props.wheelRadius,
        }):map(function(values)
            local hueAngle = values.h * (2 * math.pi)
            local harmonyAngle = harmonies[self.props.harmony].getAngles(hueAngle)[self.props.angleNum]

            return UDim2.new(
                0.5, math.cos(harmonyAngle) * (values.wheelRadius - (self.props.ringWidth / 2)),
                0.5, -math.sin(harmonyAngle) * (values.wheelRadius - (self.props.ringWidth / 2))
            )
        end),

        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 2,

        Text = "",
        TextTransparency = 1,

        BackgroundColor3 = self.props.h:map(function(h)
            local hueAngle = h * (2 * math.pi)
            local harmonyAngle = harmonies[self.props.harmony].getAngles(hueAngle)[self.props.angleNum]

            return Color.toColor3(Color.getBestContrastingColor(
                Color.fromHSB(harmonyAngle / (2 * math.pi), 1, 1),
                Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
            ))
        end),

        [Roact.Event.Activated] = function()
            local hueAngle = self.props.h:getValue() * (2 * math.pi)
            local harmonyAngle = harmonies[self.props.harmony].getAngles(hueAngle)[self.props.angleNum]
            
            self.props.updateH(harmonyAngle / (2 * math.pi))
        end,
    })
end

---

local ColorWheel = Roact.Component:extend("ColorWheel")

ColorWheel.init = function(self, initProps)
    local initH, initS, initB = Color.toHSB(Color.fromColor3(initProps.color))

    self.planeSize, self.updatePlaneSize = Roact.createBinding(Vector2.new(0, 0))
    self.wheelCenter, self.updateWheelCenter = Roact.createBinding(Vector2.new(0, 0))
    self.wheelRadius, self.updateWheelRadius = Roact.createBinding(0)

    self.components, self.updateComponents = Roact.createBinding({
        h = initH,
        s = initS,
        b = initB,
    })

    self.updateH = function(cursorPosition)
        local distanceFromWheelCenter = self.wheelCenter:getValue() - cursorPosition
        local mouseAngle = math.atan2(distanceFromWheelCenter.Y, -distanceFromWheelCenter.X)

        local components = self.components:getValue()
        local hueAngle
        local h

        -- calculate angle from [0, 2pi)
        if ((mouseAngle >= 0) and (mouseAngle <= math.pi)) then
            hueAngle = mouseAngle
        else
            hueAngle = mouseAngle + (2 * math.pi)
        end

        h = hueAngle / (2 * math.pi)

        self.updateComponents({
            h = h,
            s = components.s,
            b = components.b,
        })

        self.props.setColor(Color.toColor3(Color.fromHSB(h, components.s, components.b)))
    end

    self.updateSB = function(cursorPosition)
        local distanceFromWheelCenter = cursorPosition - self.wheelCenter:getValue()
        local planeSize = self.planeSize:getValue()
        local components = self.components:getValue()

        local s = math.clamp((distanceFromWheelCenter.X / planeSize) + 0.5, 0, 1)
        local b = 1 - math.clamp((distanceFromWheelCenter.Y / planeSize) + 0.5, 0, 1)

        self.updateComponents({
            h = components.h,
            s = s,
            b = b
        })

        self.props.setColor(Color.toColor3(Color.fromHSB(components.h, s, b)))
    end

    self:setState({
        trackingH = false,
        trackingSB = false,
    })
end

ColorWheel.shouldUpdate = function(self, nextProps, nextState)
    local propsDiff = shallowCompare(self.props, nextProps)
    local stateDiff = shallowCompare(self.state, nextState)

    if (table.find(propsDiff, "color")) then
        if (nextProps.editor ~= PluginEnums.EditorKey.ColorWheel) then
            local h, s, b = Color.toHSB(Color.fromColor3(nextProps.color))

            self.updateComponents({
                h = h,
                s = s,
                b = b,
            })
        end
    end

    if (#stateDiff > 0) then return true end

    if (#propsDiff == 1) then
        return (propsDiff[1] ~= "color")
    elseif (#propsDiff == 2) then
        if (
            ((propsDiff[1] == "color") and (propsDiff[2] == "editor")) or
            ((propsDiff[1] == "editor") and (propsDiff[2] == "color"))
        ) then
            return false
        else
            return true
        end
    elseif (#propsDiff > 2) then
        return true
    end

    return false
end

ColorWheel.didMount = function(self)
    self.inputChanged = self.props.editorInputChanged:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        if (input.UserInputType ~= Enum.UserInputType.MouseMovement) then return end
        
        local inputPosition = input.Position
        local cursorPosition = Vector2.new(inputPosition.X, inputPosition.Y)
        
        if (self.state.trackingH) then
            self.updateH(cursorPosition)
        end

        if (self.state.trackingSB) then
            self.updateSB(cursorPosition)
        end
    end)
end

ColorWheel.willUnmount = function(self)
    if (self.inputChanged) then
        self.inputChanged:Disconnect()
        self.inputChanged = nil
    end
end

ColorWheel.render = function(self)
    local theme = self.props.theme
    local harmony = self.props.harmony

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

            Position = Roact.joinBindings({
                h = self.components:map(function(components) return components.h end),
                wheelRadius = self.wheelRadius
            }):map(function(values)
                local hueAngle = values.h * (2 * math.pi)

                return UDim2.new(
                    0.5, math.cos(hueAngle) * (values.wheelRadius - (self.props.ringWidth / 2)),
                    0.5, -math.sin(hueAngle) * (values.wheelRadius - (self.props.ringWidth / 2))
                )
            end),

            BackgroundColor3 = self.components:map(function(components)
                return Color.toColor3(Color.getBestContrastingColor(
                    Color.fromHSB(components.h, 1, 1),
                    Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                    Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
                ))
            end),
        }, {
            UICorner = Roact.createElement(StandardUICorner, { circular = true }),

            Indicator = self.state.trackingH and
                Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(1, -10, 1, -10),
                    
                    BackgroundColor3 = self.components:map(function(components)
                        return Color.toColor3(Color.fromHSB(components.h, 1, 1))
                    end)
                }, {
                    UICorner = Roact.createElement(StandardUICorner, { circular = true }),
                })
            or nil
        })
    }

    if (harmonies[harmony]) then
        local numHarmonyAngles = harmonies[harmony].numAngles

        for i = 1, numHarmonyAngles do
            hueMarkers["HarmonyMarker" .. i] = Roact.createElement(HueHarmonyMarker, {
                harmony = harmony,
                angleNum = i,

                h = self.components:map(function(components) return components.h end),
                wheelRadius = self.wheelRadius,
                ringWidth = self.props.ringWidth,

                updateH = function(h)
                    local components = self.components:getValue()
                
                    self.updateComponents({
                        h = h,
                        s = components.s,
                        b = components.b
                    })

                    self.props.setColor(Color.toColor3(Color.fromHSB(h, components.s, components.b)))
                end
            })
        end
    end

    return Roact.createFragment({
        HarmonyOptions = Roact.createElement(ButtonBar, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, Style.StandardButtonSize),

            displayType = "image",
            selected = harmony,
            buttons = harmonies,
            customLayout = true,
            onButtonActivated = self.props.setHarmony,
        }),

        WheelContainer = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.new(1, 0, 1, -(Style.StandardButtonSize + Style.MajorElementPadding)),
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

                Image = Style.HueWheelImage,

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
                    Image = Style.SBPlaneImage,

                    BackgroundColor3 = Color3.new(1, 1, 1),

                    ImageColor3 = self.components:map(function(components)
                        return Color.toColor3(Color.fromHSB(components.h, 1, 1))
                    end),

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
                        Size = UDim2.new(0, 10, 0, 10),
                        BackgroundTransparency = 0,
                        BorderSizePixel = 0,

                        Position = self.components:map(function(components)
                            return UDim2.new(components.s, 0, 1 - components.b, 0)
                        end),

                        BackgroundColor3 = self.components:map(function(components)
                            return Color.toColor3(Color.getBestContrastingColor(
                                Color.fromHSB(components.h, components.s, components.b),
                                Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                                Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
                            ))
                        end),
                    }, {
                        UICorner = Roact.createElement(StandardUICorner, { circular = true }),

                        Indicator = Roact.createElement("Frame", {
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Size = UDim2.new(1, -2, 1, -2),
                            Position = UDim2.new(0.5, 0, 0.5, 0),
                            BackgroundTransparency = 0,
                            BorderSizePixel = 0,
                            
                            BackgroundColor3 = self.components:map(function(components)
                                return Color.toColor3(Color.fromHSB(components.h, components.s, components.b))
                            end),
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

        editorInputChanged = state.colorEditor.editorInputChanged,
    }
end, function(dispatch)
    return {
        setColor = function(newColor)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_SetColor,
                color = newColor,
                editor = PluginEnums.EditorKey.ColorWheel
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