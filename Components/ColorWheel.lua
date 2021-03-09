local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Color = require(PluginModules:FindFirstChild("Color"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local Style = require(PluginModules:FindFirstChild("Style"))
local util = require(PluginModules:FindFirstChild("util"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local ButtonBar = require(Components:FindFirstChild("ButtonBar"))

---

local ANALOGY_ANGLE = math.pi / 5
local EDITOR_KEY = "wheel"

local shallowCompare = util.shallowCompare

local harmonies = {
    {
        name = "None",
        image = Style.HarmonyNoneImage,
        order = 1,
        getAngles = function() return {} end,
    },

    {
        name = "Complement",
        image = Style.HarmonyComplementImage,
        order = 2,

        getAngles = function(angle)
            return {(angle + math.pi) % (2 * math.pi)}
        end
    },

    {
        name = "Triad",
        image = Style.HarmonyTriadImage,
        order = 4,

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

local ColorWheel = Roact.Component:extend("ColorWheel")

ColorWheel.init = function(self, initProps)
    self.wheel = Roact.createRef()
    self.plane = Roact.createRef()

    self.makeMarker = function(angle)
        local theme = self.props.theme

        return Roact.createElement("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, Style.MarkerSize, 0, Style.MarkerSize),
            Position = self.state.wheelRadius and UDim2.new(0.5, math.cos(angle) * (self.state.wheelRadius - (self.props.ringWidth / 2)), 0.5, -math.sin(angle) * (self.state.wheelRadius - (self.props.ringWidth / 2))) or UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = 2,

            Text = "",
            TextTransparency = 1,

            BackgroundColor3 = Color.toColor3(Color.getBestContrastingColor(
                Color.fromHSB(angle / (2 * math.pi), 1, 1),
                Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
            )),

            [Roact.Event.Activated] = function()
                local hue = angle / (2 * math.pi)

                self:setState({
                    h = hue
                })

                self.props.setColor(Color.toColor3(Color.fromHSB(hue, self.state.s, self.state.b)))
            end
        })
    end

    self.updateH = function(cursorPosition)
        local distanceFromWheelCenter = self.state.wheelCenter - cursorPosition
        local mouseAngle = math.atan2(distanceFromWheelCenter.Y, -distanceFromWheelCenter.X)
        local hueAngle

        -- calculate angle from [0, 2pi)
        if ((mouseAngle >= 0) and (mouseAngle <= math.pi)) then
            hueAngle = mouseAngle
        else
            hueAngle = mouseAngle + (2 * math.pi)
        end

        local h, s, b
        h = hueAngle / (2 * math.pi)

        if (self.props.editor == EDITOR_KEY) then
            s, b = self.state.s, self.state.b
        else
            _, s, b = Color.toHSB(Color.fromColor3(self.props.color))
        end

        self:setState({
            h = h,
            s = (self.props.editor ~= EDITOR_KEY) and s or nil,
            b = (self.props.editor ~= EDITOR_KEY) and b or nil,
        })

        self.props.setColor(Color.toColor3(Color.fromHSB(h, s, b)))
    end

    self.updateSV = function(cursorPosition)
        local distanceFromWheelCenter = cursorPosition - self.state.wheelCenter

        local h
        local s = math.clamp((distanceFromWheelCenter.X / self.state.planeSize) + 0.5, 0, 1)
        local b = 1 - math.clamp((distanceFromWheelCenter.Y / self.state.planeSize) + 0.5, 0, 1)

        if (self.props.editor == EDITOR_KEY) then
            h = self.state.h
        else
            h = Color.toHSB(Color.fromColor3(self.props.color))
        end

        self:setState({
            h = (self.props.editor ~= EDITOR_KEY) and h or nil,
            s = s,
            b = b
        })

        self.props.setColor(Color.toColor3(Color.fromHSB(h, s, b)))
    end
    
    local h, s, b = Color.toHSB(Color.fromColor3(initProps.color))

    self:setState({
        trackingH = false,
        trackingSV = false,

        h = h,
        s = s,
        b = b
    })
end

ColorWheel.shouldUpdate = function(self, nextProps, nextState)
    local propsDiff = shallowCompare(self.props, nextProps)
    local stateDiff = shallowCompare(self.state, nextState)

    if (#stateDiff > 0) then return true end

    if (#propsDiff == 1) then
        if (propsDiff[1] == "color") then
            return (nextProps.editor ~= EDITOR_KEY)
        else
            return true
        end
    elseif (#propsDiff > 1) then
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

        if (self.state.trackingSV) then
            self.updateSV(cursorPosition)
        end
    end)

    do
        local wheel = self.wheel:getValue()
        local hueWheelPosition = wheel.AbsolutePosition
        local hueWheelSize = wheel.AbsoluteSize

        local plane = self.plane:getValue()

        self:setState({
            wheelCenter = hueWheelPosition + (hueWheelSize / 2), -- top-left + (GUI size / 2)
            wheelRadius = hueWheelSize.X / 2,
            planeSize = plane.AbsoluteSize.X
        })
    end
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

    local h, s, b
    local hueAngle

    if (self.props.editor == EDITOR_KEY) then
        h, s, b = self.state.h, self.state.s, self.state.b
    else
        h, s, b = Color.toHSB(Color.fromColor3(self.props.color))
    end

    hueAngle = h * (2 * math.pi)

    local hueMarkers = {
        PrimaryMarker = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = self.state.trackingH and UDim2.new(0, self.props.ringWidth + 10, 0, self.props.ringWidth + 10) or UDim2.new(0, self.props.ringWidth - 10, 0, self.props.ringWidth - 10),
            Position = self.state.wheelRadius and
                UDim2.new(0.5, math.cos(hueAngle) * (self.state.wheelRadius - (self.props.ringWidth / 2)), 0.5, -math.sin(hueAngle) * (self.state.wheelRadius - (self.props.ringWidth / 2)))
            or UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = 2,

            BackgroundColor3 = Color.toColor3(Color.getBestContrastingColor(
                Color.fromHSB(h, 1, 1),
                Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
            ))
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(1, 0)
            }),

            Indicator = self.state.trackingH and
                Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(1, -10, 1, -10),
                    
                    BackgroundColor3 = Color.toColor3(Color.fromHSB(h, 1, 1)),
                }, {
                    UICorner = Roact.createElement("UICorner", {
                        CornerRadius = UDim.new(1, 0)
                    })
                })
            or nil
        })
    }

    if (harmonies[harmony]) then
        local harmonyAngles = harmonies[harmony].getAngles(hueAngle)

        for i = 1, #harmonyAngles do
            local harmonyAngle = harmonyAngles[i]

            hueMarkers["HarmonyMarker" .. i] = self.makeMarker(harmonyAngle)
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

            onButtonActivated = function(i)
                self.props.setHarmony(i)
            end
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

                [Roact.Ref] = self.wheel,

                [Roact.Event.InputBegan] = function(obj, input)
                    if (input.UserInputType ~= Enum.UserInputType.MouseButton1) then return end
                    
                    local inputPosition = input.Position
                    local mousePosition = Vector2.new(inputPosition.X, inputPosition.Y)

                    local hueWheelSize = obj.AbsoluteSize
                    local upperRadius = hueWheelSize.X / 2
                    local lowerRadius =  upperRadius - self.props.ringWidth

                    local distanceFromWheelCenter = mousePosition - self.state.wheelCenter
                    
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

                    self:setState({
                        wheelCenter = hueWheelPosition + (hueWheelSize / 2), -- top-left + (GUI size / 2)
                        wheelRadius = hueWheelSize.X / 2,
                    })
                end,

                [Roact.Change.AbsoluteSize] = function(obj)
                    local hueWheelPosition = obj.AbsolutePosition
                    local hueWheelSize = obj.AbsoluteSize

                    self:setState({
                        wheelCenter = hueWheelPosition + (hueWheelSize / 2), -- top-left + (GUI size / 2)
                        wheelRadius = hueWheelSize.X / 2,
                    })
                end,
            }, {
                UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
                    AspectRatio = 1,
                    AspectType = Enum.AspectType.FitWithinMaxSize,
                    DominantAxis = Enum.DominantAxis.Width
                }),

                UICorner = Roact.createElement("UICorner", {
                    CornerRadius = UDim.new(1, 0)
                }),

                RingOverlay = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Size = UDim2.new(1, -(self.props.ringWidth * 2), 1, -(self.props.ringWidth * 2)),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,

                    BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)
                }, {
                    UICorner = Roact.createElement("UICorner", {
                        CornerRadius = UDim.new(1, 0)
                    }),
                }),

                Markers = Roact.createFragment(hueMarkers)
            }),

            SVPlaneContainer = Roact.createElement("Frame", {
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

                SVPlane = Roact.createElement("ImageLabel", {
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
                    Image = Style.SVPlaneImage,

                    BackgroundColor3 = Color3.new(1, 1, 1),
                    ImageColor3 = Color.toColor3(Color.fromHSB(h, 1, 1)),

                    [Roact.Ref] = self.plane,

                    [Roact.Event.InputBegan] = function(_, input)
                        if (input.UserInputType ~= Enum.UserInputType.MouseButton1) then return end
                        if (self.state.trackingH) then return end
                        
                        self:setState({
                            trackingSV = true,
                        })
                    end,

                    [Roact.Event.InputEnded] = function(_, input)
                        if (input.UserInputType ~= Enum.UserInputType.MouseButton1) then return end
                        if (not self.state.trackingSV) then return end

                        local inputPosition = input.Position

                        self:setState({
                            trackingSV = false,
                        })

                        self.updateSV(Vector2.new(inputPosition.X, inputPosition.Y))
                    end,

                    [Roact.Change.AbsoluteSize] = function(obj)
                        self:setState({
                            planeSize = obj.AbsoluteSize.X,
                        })
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
                        Position = UDim2.new(s, 0, 1 - b, 0),
                        BackgroundTransparency = 0,
                        BorderSizePixel = 0,

                        BackgroundColor3 = Color.toColor3(Color.getBestContrastingColor(
                            Color.fromHSB(h, s, b),
                            Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                            Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
                        ))
                    }, {
                        UICorner = Roact.createElement("UICorner", {
                            CornerRadius = UDim.new(1, 0)
                        }),

                        Indicator = Roact.createElement("Frame", {
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Size = UDim2.new(1, -2, 1, -2),
                            Position = UDim2.new(0.5, 0, 0.5, 0),
                            BackgroundTransparency = 0,
                            BorderSizePixel = 0,
                            
                            BackgroundColor3 = Color.toColor3(Color.fromHSB(h, s, b)),
                        }, {
                            UICorner = Roact.createElement("UICorner", {
                                CornerRadius = UDim.new(1, 0)
                            })
                        })
                    })
                })
            })
        }),
    })
end

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