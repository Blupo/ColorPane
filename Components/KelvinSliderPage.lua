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
local Padding = require(Components:FindFirstChild("Padding"))
local SimpleList = require(Components:FindFirstChild("SimpleList"))
local Slider = require(Components:FindFirstChild("Slider"))

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
    ColorSequenceKeypoint.new(0, Color.toColor3(Color.fromKelvin(1000))),
    ColorSequenceKeypoint.new(getKelvinRangeValue(2000), Color.toColor3(Color.fromKelvin(2000))),
    ColorSequenceKeypoint.new(getKelvinRangeValue(6000), Color.toColor3(Color.fromKelvin(6000))),
    ColorSequenceKeypoint.new(getKelvinRangeValue(6500), Color.toColor3(Color.fromKelvin(6500))),
    ColorSequenceKeypoint.new(getKelvinRangeValue(7000), Color.toColor3(Color.fromKelvin(7000))),
    ColorSequenceKeypoint.new(1, Color.toColor3(Color.fromKelvin(10000))),
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
    self.kelvin, self.updateKelvin = Roact.createBinding(getKelvinRangeValue(Color.toKelvin(Color.fromColor3(initProps.color))))
end

KelvinSliderPage.shouldUpdate = function(self, nextProps, nextState)
    local propsDiff = shallowCompare(self.props, nextProps)
    local stateDiff = shallowCompare(self.state, nextState)

    if (table.find(propsDiff, "color")) then
        if (nextProps.editor ~= PluginEnums.EditorKey.KelvinSlider) then
            self.updateKelvin(getKelvinRangeValue(Color.toKelvin(Color.fromColor3(nextProps.color))))
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
                self.props.setColor(Color.toColor3(Color.fromKelvin(preset.kelvin)))
            end,

            [Roact.Children] = {
                UIPadding = Roact.createElement(Padding, {0, Style.SpaciousElementPadding}),

                KelvinLabel = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Font = Style.StandardFont,
                    TextSize = Style.StandardTextSize,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    Text = preset.kelvin,

                    TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ButtonText),
                })
            }
        }
    end

    return Roact.createFragment({
        Slider = Roact.createElement(Slider, {
            value = self.kelvin,
            editorInputChanged = self.props.editorInputChanged,
            layoutOrder = 0,

            sliderLabel = "Temperature",
            sliderGradient = kelvinGradient,
            unitLabel = "K",

            markerColor = self.kelvin:map(function(k)
                return Color.toColor3(Color.getBestContrastingColor(
                    Color.fromKelvin(getValueRangeKelvin(k)),
                    Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                    Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
                ))
            end),

            valueToText = valueToText,
            textToValue = textToValue,

            isTextAValidValue = function(text)
                return textToValue(text) and true or false
            end,

            valueChanged = function(value)
                self.updateKelvin(value)
                self.props.setColor(Color.toColor3(Color.fromKelvin(getValueRangeKelvin(value))))
            end
        }),

        ScaleLowerLimitLabel = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 0, 0, 40),
            Size = UDim2.new(0, 100, 0, Style.StandardTextSize),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Font = Style.StandardFont,
            TextSize = Style.StandardTextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Text = LOWER_RANGE,

            TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
        }),

        ScaleUpperLimitLabel = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -58, 0, 40),
            Size = UDim2.new(0, 100, 0, Style.StandardTextSize),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Font = Style.StandardFont,
            TextSize = Style.StandardTextSize,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextYAlignment = Enum.TextYAlignment.Center,
            Text = UPPER_RANGE,

            TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
        }),

        PresetsContainer = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, 0, 1, -58),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            PresetsLabel = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, Style.StandardTextSize),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Font = Style.StandardFont,
                TextSize = Style.StandardTextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                Text = "Presets",
                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
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