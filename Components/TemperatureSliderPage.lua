local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Constants = require(PluginModules:FindFirstChild("Constants"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local Style = require(PluginModules:FindFirstChild("Style"))
local Translator = require(PluginModules:FindFirstChild("Translator"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local Color = require(includes:FindFirstChild("Color")).Color
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local SimpleList = require(Components:FindFirstChild("SimpleList"))
local Slider = require(Components:FindFirstChild("Slider"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardTextLabel = StandardComponents.TextLabel
local StandardUIPadding = StandardComponents.UIPadding

---

local EDITOR_KEY = PluginEnums.EditorKey.KelvinSlider

local valueToText = function(value)
    return math.floor(Util.lerp(Constants.KELVIN_LOWER_RANGE, Constants.KELVIN_UPPER_RANGE, value))
end

local textToValue = function(text)
    local n = tonumber(text)
    if (not n) then return end
    if ((n < Constants.KELVIN_LOWER_RANGE) or (n > Constants.KELVIN_UPPER_RANGE)) then return end

    return Util.inverseLerp(Constants.KELVIN_LOWER_RANGE, Constants.KELVIN_UPPER_RANGE, n)
end

local temperatureGradient = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color.fromTemperature(1000):toColor3()),
    ColorSequenceKeypoint.new(Util.inverseLerp(Constants.KELVIN_LOWER_RANGE, Constants.KELVIN_UPPER_RANGE, 2000), Color.fromTemperature(2000):toColor3()),
    ColorSequenceKeypoint.new(Util.inverseLerp(Constants.KELVIN_LOWER_RANGE, Constants.KELVIN_UPPER_RANGE, 6000), Color.fromTemperature(6000):toColor3()),
    ColorSequenceKeypoint.new(Util.inverseLerp(Constants.KELVIN_LOWER_RANGE, Constants.KELVIN_UPPER_RANGE, 6500), Color.fromTemperature(6500):toColor3()),
    ColorSequenceKeypoint.new(Util.inverseLerp(Constants.KELVIN_LOWER_RANGE, Constants.KELVIN_UPPER_RANGE, 7000), Color.fromTemperature(7000):toColor3()),
    ColorSequenceKeypoint.new(1, Color.fromTemperature(10000):toColor3()),
})

local uiTranslations = Translator.GenerateTranslationTable({
    "Temperature_Label",
    "Presets_Label",
})

local temperaturePresets = {
    { name = Translator.FormatByKey("MatchFlame_Preset"), temperature = 1700 },
    { name = Translator.FormatByKey("Candlelight_Preset"), temperature = 1850 },
    { name = Translator.FormatByKey("Incandescent_Preset"), temperature = 2400 },
    { name = Translator.FormatByKey("SoftWhiteIncandescent_Preset"), temperature = 2550 },
    { name = Translator.FormatByKey("SoftWhite_Preset"), temperature = 2700 },
    { name = Translator.FormatByKey("WarmWhite_Preset"), temperature = 3000 },
    { name = Translator.FormatByKey("HorizonDaylight_Preset"), temperature = 5000 },
    { name = Translator.FormatByKey("Daylight_Preset"), temperature = 6500 },
    { name = Translator.FormatByKey("ClearSky_Preset"), temperature = 10000 },
}

---

--[[
    store props

        theme: StudioTheme
        color: Color
        editor: string

        setColor: (Color) -> nil
]]

local TemperatureSliderPage = Roact.PureComponent:extend("TemperatureSliderPage")

TemperatureSliderPage.init = function(self, initProps)
    self:setState({
        temperature = initProps.color:toTemperature()
    })
end

TemperatureSliderPage.getDerivedStateFromProps = function(props, state)
    if (props.editor == EDITOR_KEY) then return end
    
    if (state.captureFocus) then
        return {
            captureFocus = Roact.None,
        }
    end

    local temperature = props.color:toTemperature()
    if (temperature == state.temperature) then return end

    return {
        temperature = temperature
    }
end

TemperatureSliderPage.render = function(self)
    local theme = self.props.theme
    local editor = self.props.editor
    local temperature = self.state.temperature

    local presetItems = {}

    for i = 1, #temperaturePresets do
        local preset = temperaturePresets[i]
        local presetTemperature = preset.temperature

        presetItems[i] = {
            name = preset.name,

            onActivated = function()
                self:setState({
                    captureFocus = (editor ~= EDITOR_KEY) and true or nil,
                    temperature = presetTemperature
                })

                self.props.setColor(Color.fromTemperature(presetTemperature))
            end,

            [Roact.Children] = {
                UIPadding = Roact.createElement(StandardUIPadding, {0, Style.Constants.SpaciousElementPadding}),

                KelvinLabel = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(1, 0, 1, 0),

                    Text = preset.temperature,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextYAlignment = Enum.TextYAlignment.Center,
                })
            }
        }
    end

    return Roact.createFragment({
        Slider = Roact.createElement(Slider, {
            value = Util.inverseLerp(Constants.KELVIN_LOWER_RANGE, Constants.KELVIN_UPPER_RANGE, temperature),
            layoutOrder = 0,

            sliderLabel = uiTranslations["Temperature_Label"],
            sliderGradient = temperatureGradient,
            unitLabel = "K",

            markerColor = Color.fromTemperature(temperature):bestContrastingColor(
                Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)):invert()
            ):toColor3(),

            valueToText = valueToText,
            textToValue = textToValue,

            isTextAValidValue = function(text)
                return textToValue(text) and true or false
            end,

            valueChanged = function(value)
                local newTemperature = Util.lerp(Constants.KELVIN_LOWER_RANGE, Constants.KELVIN_UPPER_RANGE, value)

                self:setState({
                    captureFocus = (editor ~= EDITOR_KEY) and true or nil,
                    temperature = newTemperature
                })

                self.props.setColor(Color.fromTemperature(newTemperature))
            end
        }),

        ScaleLowerLimitLabel = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 0, 0, 40),
            Size = UDim2.new(0, 100, 0, Style.Constants.StandardTextSize),
            Text = Constants.KELVIN_LOWER_RANGE,
        }),

        ScaleUpperLimitLabel = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -(60 + Style.Constants.MinorElementPadding), 0, 40),
            Size = UDim2.new(0, 100, 0, Style.Constants.StandardTextSize),

            Text = Constants.KELVIN_UPPER_RANGE,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextYAlignment = Enum.TextYAlignment.Center,
        }),

        PresetsContainer = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, 0, 1, -58),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            PresetsLabel = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
                Text = uiTranslations["Presets_Label"],
            }),

            PresetsList = Roact.createElement(SimpleList, {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, 0),
                Size = UDim2.new(1, -2, 1, -18),
                TextSize = Style.Constants.StandardTextSize,

                itemHeight = Style.Constants.StandardButtonHeight,
                
                sections = {
                    {
                        name = "",
                        items = presetItems
                    }
                }
            }),
        }),
    })
end

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,
        color = state.colorEditor.color,
        editor = state.colorEditor.authoritativeEditor,
    }
end, function(dispatch)
    return {
        setColor = function(newColor)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_SetColor,
                color = newColor,
                editor = EDITOR_KEY
            })
        end
    }
end)(TemperatureSliderPage)