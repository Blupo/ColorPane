local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Color = require(includes:FindFirstChild("Color")).Color
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local ColorGrids = require(Components:FindFirstChild("ColorGrids"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardTextLabel = StandardComponents.TextLabel

---

local MIN_STEPS = 4
local MAX_STEPS = 14

---

--[[
    store props

        color: Color3
        variationSteps: number

        setColor: (Color3) -> nil
        updateVariationSteps: (number) -> nil
]]

local ColorVariations = Roact.PureComponent:extend("ColorVariations")

ColorVariations.render = function(self)
    local variationSteps = self.props.variationSteps

    local modifiedColors = {
        Hues = {},
        Shades = {},
        Tints = {},
        Tones = {},
    }

    for i = 1, variationSteps do
        local color = Color.fromColor3(self.props.color)

        modifiedColors.Shades[i] = Color.darken(color, i/2):toColor3()
        modifiedColors.Tints[i] = Color.brighten(color, i/2):toColor3()
        modifiedColors.Tones[i] = Color.desaturate(color, i/2):toColor3()

        local h, s, b = color:toHSB()
        h = (h ~= h) and 0 or h
        h = (h + (360 / (MAX_STEPS + 1) * i)) % 360

        modifiedColors.Hues[i] = Color.fromHSB(h, s, b):toColor3()
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
                disabled = (variationSteps >= MAX_STEPS),

                onActivated = function()
                    self.props.updateVariationSteps(variationSteps + 1)
                end,
            }),

            DecrementButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 60 + Style.MinorElementPadding, 0.5, 0),

                displayType = "image",
                image = Style.SubtractImage,
                disabled = (variationSteps <= MIN_STEPS),

                onActivated = function()
                    self.props.updateVariationSteps(variationSteps - 1)
                end,
            }),

            StepsLabel = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 60, 1, 0),
                Position = UDim2.new(0, 0, 0.5, 0),
                Text = "Color Steps",

            }),

            StepsCountLabel = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -(Style.StandardButtonSize + Style.MinorElementPadding), 0.5, 0),

                Text = variationSteps,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
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
        color = state.colorEditor.color,
        variationSteps = state.sessionData.variationSteps,
    }
end, function(dispatch)
    return {
        setColor = function(color)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_SetColor,
                color = color
            })
        end,

        updateVariationSteps = function(steps)
            dispatch({
                type = PluginEnums.StoreActionType.UpdateSessionData,
                slice = {
                    variationSteps = steps
                }
            })
        end,
    }
end)(ColorVariations)