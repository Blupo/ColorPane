local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Color = require(PluginModules:FindFirstChild("Color"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local ColorGrids = require(Components:FindFirstChild("ColorGrids"))

---

local MIN_STEPS = 4
local MAX_STEPS = 14

local ColorTools = Roact.PureComponent:extend("ColorTools")

ColorTools.init = function(self)
    self:setState({
        colorSteps = 10
    })
end

ColorTools.render = function(self)
    local theme = self.props.theme
    local steps = self.state.colorSteps

    local modifiedColors = {
        Hues = {},
        Shades = {},
        Tints = {},
        Tones = {},
    }

    for i = 1, steps do
        local color = Color.fromColor3(self.props.color)

        modifiedColors.Shades[i] = Color.toColor3(Color.darken(color, i/2))
        modifiedColors.Tints[i] = Color.toColor3(Color.brighten(color, i/2))
        modifiedColors.Tones[i] = Color.toColor3(Color.desaturate(color, i/2))

        local h, s, b = Color.toHSB(color)
        h = (h + (i / (MAX_STEPS + 1))) % 1

        modifiedColors.Hues[i] = Color.toColor3(Color.fromHSB(h, s, b))
    end

    return Roact.createFragment({
        ColorStepsPicker = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Size = UDim2.new(0, (Style.StandardButtonSize * 2) + (Style.MinorElementPadding * 3) + 20 + 60, 0, Style.StandardButtonSize),
            Position = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            IncrementButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),

                displayType = "image",
                image = Style.AddImage,
                disabled = (steps >= MAX_STEPS),

                onActivated = function()
                    self:setState({
                        colorSteps = steps + 1
                    })
                end,
            }),

            DecrementButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 60 + Style.MinorElementPadding, 0.5, 0),

                displayType = "image",
                image = Style.RemoveImage,
                disabled = (steps <= MIN_STEPS),

                onActivated = function()
                    self:setState({
                        colorSteps = steps - 1
                    })
                end,
            }),

            StepsLabel = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 60, 1, 0),
                Position = UDim2.new(0, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = "Color Steps",
                Font = Style.StandardFont,
                TextSize = Style.StandardTextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,

                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
            }),

            StepsCountLabel = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -(Style.StandardButtonSize + Style.MinorElementPadding), 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = self.state.colorSteps,
                Font = Style.StandardFont,
                TextSize = Style.StandardTextSize,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,

                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
            })
        }),

        Colors = Roact.createElement(ColorGrids, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, -2, 1, -(Style.StandardButtonSize + Style.MinorElementPadding + 2)),

            named = true,
            colorLists = modifiedColors,

            onColorSelected = function(index, schemeName)
                self.props.setColor(modifiedColors[schemeName][index])
            end
        })
    })
end

---

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,
        color = state.colorEditor.color,
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
end)(ColorTools)