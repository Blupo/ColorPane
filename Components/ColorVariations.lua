local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local Style = require(PluginModules:FindFirstChild("Style"))
local Translator = require(PluginModules:FindFirstChild("Translator"))

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

local uiTranslations = Translator.GenerateTranslationTable({
    "Hues_Label",
    "Shades_Label",
    "Tints_Label",
    "Tones_Label",
    "ColorSteps_Label"
})

---

--[[
    store props

        color: Color
        variationSteps: number

        setColor: (Color) -> nil
        updateVariationSteps: (number) -> nil
]]

local ColorVariations = Roact.PureComponent:extend("ColorVariations")

ColorVariations.render = function(self)
    local variationSteps = self.props.variationSteps
    local color = self.props.color

    local modifiedColors = {
        [uiTranslations["Hues_Label"]] = {},
        [uiTranslations["Shades_Label"]] = {},
        [uiTranslations["Tints_Label"]] = {},
        [uiTranslations["Tones_Label"]] = {},
    }

    for i = 1, variationSteps do
        modifiedColors[uiTranslations["Shades_Label"]][i] = color:darken(i/2):toColor3()
        modifiedColors[uiTranslations["Tints_Label"]][i] = color:brighten(i/2):toColor3()
        modifiedColors[uiTranslations["Tones_Label"]][i] = color:desaturate(i/2):toColor3()

        local h, s, b = color:toHSB()
        h = (h ~= h) and 0 or h
        h = (h + (360 / (MAX_STEPS + 1) * i)) % 360

        modifiedColors[uiTranslations["Hues_Label"]][i] = Color.fromHSB(h, s, b):toColor3()
    end

    return Roact.createFragment({
        ColorStepsPicker = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            
            Size = UDim2.new(
                0, (Style.Constants.StandardButtonHeight * 2) + (Style.Constants.MinorElementPadding * 3) + 20 + 60,
                0, Style.Constants.StandardButtonHeight
            ),
        }, {
            IncrementButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),

                displayType = "image",
                image = Style.Images.AddButtonIcon,
                disabled = (variationSteps >= MAX_STEPS),

                onActivated = function()
                    self.props.updateVariationSteps(variationSteps + 1)
                end,
            }),

            DecrementButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 60 + Style.Constants.MinorElementPadding, 0.5, 0),

                displayType = "image",
                image = Style.Images.SubtractButtonIcon,
                disabled = (variationSteps <= MIN_STEPS),

                onActivated = function()
                    self.props.updateVariationSteps(variationSteps - 1)
                end,
            }),

            StepsLabel = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 60, 1, 0),
                Position = UDim2.new(0, 0, 0.5, 0),
                Text = uiTranslations["ColorSteps_Label"],

            }),

            StepsCountLabel = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -(Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding), 0.5, 0),

                Text = variationSteps,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
            })
        }),

        Colors = Roact.createElement(ColorGrids, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, -2, 1, -(Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding + 2)),

            named = true,
            colorLists = modifiedColors,

            onColorSelected = function(index, schemeName)
                self.props.setColor(Color.fromColor3(modifiedColors[schemeName][index]))
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