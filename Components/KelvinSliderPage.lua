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

local LOWER_RANGE = 1000
local UPPER_RANGE = 10000

local shallowCompare = Util.shallowCompare

local getKelvinRangeValue = function(k)
    k = math.clamp(k, LOWER_RANGE, UPPER_RANGE)

    return (k - LOWER_RANGE) / (UPPER_RANGE - LOWER_RANGE)
end

local getValueRangeKelvin = function(v)
    return (v * (UPPER_RANGE - LOWER_RANGE)) + LOWER_RANGE
end

local valueToText = function(value)
    return math.floor(getValueRangeKelvin(value))
end

local textToValue = function(text)
    local n = tonumber(text)
    if (not n) then return end
    if ((n < LOWER_RANGE) or (n > UPPER_RANGE)) then return end

    return getKelvinRangeValue(n)
end

local kelvinGradient = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color.fromTemperature(1000):toColor3()),
    ColorSequenceKeypoint.new(getKelvinRangeValue(2000), Color.fromTemperature(2000):toColor3()),
    ColorSequenceKeypoint.new(getKelvinRangeValue(6000), Color.fromTemperature(6000):toColor3()),
    ColorSequenceKeypoint.new(getKelvinRangeValue(6500), Color.fromTemperature(6500):toColor3()),
    ColorSequenceKeypoint.new(getKelvinRangeValue(7000), Color.fromTemperature(7000):toColor3()),
    ColorSequenceKeypoint.new(1, Color.fromTemperature(10000):toColor3()),
})

local kelvinPresets = {
    { name = "Match Flame", kelvin = 1700 },
    { name = "Candlelight", kelvin = 1850 },
    { name = "Incandescent", kelvin = 2400 },
    { name = "Soft White Incandescent", kelvin = 2550 },
    { name = "Soft White", kelvin = 2700 },
    { name = "Warm White", kelvin = 3000 },
    { name = "Horizon Daylight", kelvin = 5000 },
    { name = "Daylight", kelvin = 6500 },
    { name = "Clear Sky", kelvin = 10000 },
}

---

local KelvinSliderPage = Roact.Component:extend("KelvinSliderPage")

KelvinSliderPage.init = function(self, initProps)
    self.kelvin, self.updateKelvin = Roact.createBinding(getKelvinRangeValue(Color.fromColor3(initProps.color):toTemperature()))
end

KelvinSliderPage.shouldUpdate = function(self, nextProps, nextState)
    local propsDiff = shallowCompare(self.props, nextProps)
    local stateDiff = shallowCompare(self.state, nextState)

    if (table.find(propsDiff, "color")) then
        if (nextProps.editor ~= PluginEnums.EditorKey.KelvinSlider) then
            self.updateKelvin(getKelvinRangeValue(Color.fromColor3(nextProps.color):toTemperature()))
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

KelvinSliderPage.render = function(self)
    local theme = self.props.theme
    local presetItems = {}

    for i = 1, #kelvinPresets do
        local preset = kelvinPresets[i]

        presetItems[i] = {
            name = preset.name,

            onActivated = function()
                self.updateKelvin(getKelvinRangeValue(preset.kelvin))
                self.props.setColor(Color.fromTemperature(preset.kelvin):toColor3())
            end,

            [Roact.Children] = {
                UIPadding = Roact.createElement(StandardUIPadding, {0, Style.SpaciousElementPadding}),

                KelvinLabel = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(1, 0, 1, 0),

                    Text = preset.kelvin,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextYAlignment = Enum.TextYAlignment.Center,
                })
            }
        }
    end

    return Roact.createFragment({
        Slider = Roact.createElement(Slider, {
            value = self.kelvin,
            layoutOrder = 0,

            sliderLabel = "Temperature",
            sliderGradient = kelvinGradient,
            unitLabel = "K",

            markerColor = self.kelvin:map(function(k)
                return Color.fromTemperature(getValueRangeKelvin(k)):bestContrastingColor(
                    Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                    Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)):invert()
                ):toColor3()
            end),

            valueToText = valueToText,
            textToValue = textToValue,

            isTextAValidValue = function(text)
                return textToValue(text) and true or false
            end,

            valueChanged = function(value)
                self.updateKelvin(value)
                self.props.setColor(Color.fromTemperature(getValueRangeKelvin(value)):toColor3())
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
                editor = PluginEnums.EditorKey.KelvinSlider
            })
        end
    }
end)(KelvinSliderPage)