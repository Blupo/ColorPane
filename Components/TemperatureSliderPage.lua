local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local Style = require(PluginModules:FindFirstChild("Style"))
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
local LOWER_RANGE = 1000
local UPPER_RANGE = 10000

local valueToText = function(value)
    return math.floor(Util.lerp(LOWER_RANGE, UPPER_RANGE, value))
end

local textToValue = function(text)
    local n = tonumber(text)
    if (not n) then return end
    if ((n < LOWER_RANGE) or (n > UPPER_RANGE)) then return end

    return Util.inverseLerp(LOWER_RANGE, UPPER_RANGE, n)
end

local temperatureGradient = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color.fromTemperature(1000):toColor3()),
    ColorSequenceKeypoint.new(Util.inverseLerp(LOWER_RANGE, UPPER_RANGE, 2000), Color.fromTemperature(2000):toColor3()),
    ColorSequenceKeypoint.new(Util.inverseLerp(LOWER_RANGE, UPPER_RANGE, 6000), Color.fromTemperature(6000):toColor3()),
    ColorSequenceKeypoint.new(Util.inverseLerp(LOWER_RANGE, UPPER_RANGE, 6500), Color.fromTemperature(6500):toColor3()),
    ColorSequenceKeypoint.new(Util.inverseLerp(LOWER_RANGE, UPPER_RANGE, 7000), Color.fromTemperature(7000):toColor3()),
    ColorSequenceKeypoint.new(1, Color.fromTemperature(10000):toColor3()),
})

local temperaturePresets = {
    { name = "Match Flame", temperature = 1700 },
    { name = "Candlelight", temperature = 1850 },
    { name = "Incandescent", temperature = 2400 },
    { name = "Soft White Incandescent", temperature = 2550 },
    { name = "Soft White", temperature = 2700 },
    { name = "Warm White", temperature = 3000 },
    { name = "Horizon Daylight", temperature = 5000 },
    { name = "Daylight", temperature = 6500 },
    { name = "Clear Sky", temperature = 10000 },
}

---

--[[
    store props

        theme: StudioTheme
        color: Color3
        editor: string

        setColor: (Color3) -> nil
]]

local TemperatureSliderPage = Roact.PureComponent:extend("TemperatureSliderPage")

TemperatureSliderPage.init = function(self, initProps)
    self:setState({
        temperature = Color.fromColor3(initProps.color):toTemperature()
    })
end

TemperatureSliderPage.getDerivedStateFromProps = function(props, state)
    if (props.editor == EDITOR_KEY) then return end
    
    if (state.captureFocus) then
        return {
            captureFocus = Roact.None,
        }
    end

    local temperature = Color.fromColor3(props.color):toTemperature()
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

                self.props.setColor(Color.fromTemperature(presetTemperature):toColor3())
            end,

            [Roact.Children] = {
                UIPadding = Roact.createElement(StandardUIPadding, {0, Style.SpaciousElementPadding}),

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
            value = Util.inverseLerp(LOWER_RANGE, UPPER_RANGE, temperature),
            layoutOrder = 0,

            sliderLabel = "Temperature",
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
                local newTemperature = Util.lerp(LOWER_RANGE, UPPER_RANGE, value)

                self:setState({
                    captureFocus = (editor ~= EDITOR_KEY) and true or nil,
                    temperature = newTemperature
                })

                self.props.setColor(Color.fromTemperature(newTemperature):toColor3())
            end
        }),

        ScaleLowerLimitLabel = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 0, 0, 40),
            Size = UDim2.new(0, 100, 0, Style.StandardTextSize),
            Text = LOWER_RANGE,
        }),

        ScaleUpperLimitLabel = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -(60 + Style.MinorElementPadding), 0, 40),
            Size = UDim2.new(0, 100, 0, Style.StandardTextSize),

            Text = UPPER_RANGE,
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
                Size = UDim2.new(1, 0, 0, Style.StandardTextSize),
                Text = "Presets",
            }),

            PresetsList = Roact.createElement(SimpleList, {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, 0),
                Size = UDim2.new(1, -2, 1, -18),
                TextSize = Style.StandardTextSize,

                itemHeight = Style.StandardButtonSize,
                
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