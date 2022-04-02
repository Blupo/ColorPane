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
local Slider = require(Components:FindFirstChild("Slider"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardUIListLayout = StandardComponents.UIListLayout

---

local EDITOR_KEY = PluginEnums.EditorKey.GreyscaleSlider

local sliderLabel = Translator.FormatByKey("GreyscaleSlider_Brightness_Label")

local valueToTextFactory = function(size)
    return function(value)
        return math.floor(value * size)
    end
end

local textToValueFactory = function(size)
    return function(text)
        local n = tonumber(text)
        if (not n) then return end
        if ((n < 0) or (n > size)) then return end

        return (n / size)
    end
end

local percentValueToText, percentTextToValue = valueToTextFactory(100), textToValueFactory(100)

---

--[[
    store props

        theme: StudioTheme
        color: Color
        editor: string

        setColor: (Color) -> nil
]]

local GreyscaleSliderPage = Roact.PureComponent:extend("GreyscaleSliderPage")

GreyscaleSliderPage.init = function(self, initProps)
    local color = initProps.color
    local brightness = (color.R + color.G + color.B) / 3

    self:setState({
        brightness = brightness
    })
end

GreyscaleSliderPage.getDerivedStateFromProps = function(props, state)
    if (props.editor == EDITOR_KEY) then return end
    
    if (state.captureFocus) then
        return {
            captureFocus = Roact.None,
        }
    end

    local color = props.color
    local brightness = (color.R + color.G + color.B) / 3
    if (brightness == state.brightness) then return end

    return {
        brightness = brightness
    }
end

GreyscaleSliderPage.render = function(self)
    local theme = self.props.theme
    local editor = self.props.editor

    local brightness = self.state.brightness

    return Roact.createFragment({
        UIListLayout = Roact.createElement(StandardUIListLayout, {
            Padding = UDim.new(0, Style.Constants.MajorElementPadding),
            
            preset = 1,
        }),

        Slider = Roact.createElement(Slider, {
            value = brightness,
            sliderLabel = sliderLabel,
            sliderGradient = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(1, 1, 1)),

            markerColor = Color.gray(brightness):bestContrastingColor(
                Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)):invert()
            ):toColor3(),

            keypoints = {
                {value = 0, color = Color3.new()},
                {value = 0.25, color = Color3.new(0.25, 0.25, 0.25)},
                {value = 0.5, color = Color3.new(0.5, 0.5, 0.5)},
                {value = 0.75, color = Color3.new(0.75, 0.75, 0.75)},
                {value = 1, color = Color3.new(1, 1, 1)}
            },

            valueToText = percentValueToText,
            textToValue = percentTextToValue,

            valueChanged = function(value)
                self:setState({
                    captureFocus = (editor ~= EDITOR_KEY) and true or nil,
                    brightness = value
                })
                
                self.props.setColor(Color.gray(value))
            end
        })
    })
end

---

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
end)(GreyscaleSliderPage)