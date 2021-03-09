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
local Pages = require(Components:FindFirstChild("Pages"))
local Slider = require(Components:FindFirstChild("Slider"))

---

local RGBSLIDER_KEY = "rgbslider"
local CMYKSLIDER_KEY = "cmykslider"
local HSBSLIDER_KEY = "hsbslider"
local HSLSLIDER_KEY = "hslslider"
local GREYSLIDER_KEY = "greyslider"

local SliderPages
local RGBSliderPage = Roact.Component:extend("RGBSliderPage")
local CMYKSliderPage = Roact.Component:extend("CMYKSliderPage")
local HSBSliderPage = Roact.Component:extend("HSBSliderPage")
local HSLSliderPage = Roact.Component:extend("HSLSliderPage")
local GreyscaleSliderPage = Roact.Component:extend("GreyscaleSliderPage")
local KelvinSliderPage = require(Components:FindFirstChild("KelvinSliderPage"))

local shallowCompare = util.shallowCompare

local ConnectStore = RoactRodux.connect(function(state)
    return {
        theme = state.theme,

        color = state.colorEditor.color,
        editor = state.colorEditor.authoritativeEditor,
    }
end, function(dispatch)
    return {
        setColor = function(newColor, editor)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_SetColor,
                color = newColor,
                editor = editor
            })
        end
    }
end)

local sliderShouldUpdateFactory = function(key)
    return function(self, nextProps, nextState)
        local propsDiff = shallowCompare(self.props, nextProps)
        local stateDiff = shallowCompare(self.state, nextState)
    
        if (#stateDiff > 0) then return true end
    
        if (#propsDiff == 1) then
            if (propsDiff[1] == "color") then
                return (nextProps.editor ~= key)
            else
                return true
            end
        elseif (#propsDiff > 1) then
            return true
        end
    
        return false
    end
end

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

local rgbValueToText, rgbTextToValue = valueToTextFactory(255), textToValueFactory(255)
local percentValueToText, percentTextToValue = valueToTextFactory(100), textToValueFactory(100)

---

RGBSliderPage.init = function(self, initProps)
    self.setColor = function(newColor)
        initProps.setColor(newColor, RGBSLIDER_KEY)
    end

    local color = initProps.color
    
    self:setState({
        r = color.R,
        g = color.G,
        b = color.B,
    })
end

RGBSliderPage.shouldUpdate = sliderShouldUpdateFactory(RGBSLIDER_KEY)

RGBSliderPage.render = function(self)
    local theme = self.props.theme

    local syncStateFromStore = (self.props.editor ~= RGBSLIDER_KEY)
    local r, g, b

    if (not syncStateFromStore) then
        r, g, b = self.state.r, self.state.g, self.state.b
    else
        local color = self.props.color

        r, g, b = color.R, color.G, color.B
    end

    local markerColor = Color.toColor3(Color.getBestContrastingColor(
        Color.fromRGB(r, g, b),
        Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
        Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
    ))

    return Roact.createFragment({
        UIListLayout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, Style.MajorElementPadding),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        }),

        R = Roact.createElement(Slider, {
            value = r,
            editorInputChanged = self.props.editorInputChanged,
            layoutOrder = 0,

            sliderLabel = "Red",
            sliderGradient = ColorSequence.new(Color3.new(0, g, b), Color3.new(1, g, b)),
            markerColor = markerColor,

            valueToText = rgbValueToText,
            textToValue = rgbTextToValue,

            valueChanged = function(value)
                self:setState({
                    r = value,
                    g = syncStateFromStore and g or nil,
                    b = syncStateFromStore and b or nil
                })

                self.setColor(Color3.new(value, g, b))
            end
        }),

        G = Roact.createElement(Slider, {
            value = g,
            editorInputChanged = self.props.editorInputChanged,
            layoutOrder = 1,

            sliderLabel = "Green",
            sliderGradient = ColorSequence.new(Color3.new(r, 0, b), Color3.new(r, 1, b)),
            markerColor = markerColor,

            valueToText = rgbValueToText,
            textToValue = rgbTextToValue,

            valueChanged = function(value)
                self:setState({
                    r = syncStateFromStore and r or nil,
                    g = value,
                    b = syncStateFromStore and b or nil
                })

                self.setColor(Color3.new(r, value, b))
            end
        }),

        B = Roact.createElement(Slider, {
            value = b,
            editorInputChanged = self.props.editorInputChanged,
            layoutOrder = 2,

            sliderLabel = "Blue",
            sliderGradient = ColorSequence.new(Color3.new(r, g, 0), Color3.new(r, g, 1)),
            markerColor = markerColor,

            valueToText = rgbValueToText,
            textToValue = rgbTextToValue,

            valueChanged = function(value)
                self:setState({
                    r = syncStateFromStore and r or nil,
                    g = syncStateFromStore and g or nil,
                    b = value
                })

                self.setColor(Color3.new(r, g, value))
            end
        }),
    })
end

---

CMYKSliderPage.init = function(self, initProps)
    self.setColor = function(newColor)
        initProps.setColor(newColor, CMYKSLIDER_KEY)
    end

    local c, m, y, k = Color.toCMYK(Color.fromColor3(initProps.color))

    self:setState({
        c = c,
        m = m,
        y = y,
        k = k,
    })
end

CMYKSliderPage.shouldUpdate = sliderShouldUpdateFactory(CMYKSLIDER_KEY)

CMYKSliderPage.render = function(self)
    local theme = self.props.theme

    local syncStateFromStore = (self.props.editor ~= CMYKSLIDER_KEY)
    local c, m, y, k

    if (not syncStateFromStore) then
        c, m, y, k = self.state.c, self.state.m, self.state.y, self.state.k
    else
        c, m, y, k = Color.toCMYK(Color.fromColor3(self.props.color))
    end

    local markerColor = Color.toColor3(Color.getBestContrastingColor(
        Color.fromCMYK(c, m, y, k),
        Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
        Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
    ))

    return Roact.createFragment({
        UIListLayout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, Style.MajorElementPadding),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        }),

        C = Roact.createElement(Slider, {
            value = c,
            editorInputChanged = self.props.editorInputChanged,
            layoutOrder = 0,

            sliderLabel = "Cyan",
            unitLabel = "%",

            sliderGradient = ColorSequence.new(
                Color.toColor3(Color.fromCMYK(0, m, y, k)),
                Color.toColor3(Color.fromCMYK(1, m, y, k))
            ),
            markerColor = markerColor,

            valueToText = percentValueToText,
            textToValue = percentTextToValue,

            valueChanged = function(value)
                self:setState({
                    c = value,
                    m = syncStateFromStore and m or nil,
                    y = syncStateFromStore and y or nil,
                    k = syncStateFromStore and k or nil,
                })

                self.setColor(Color.toColor3(Color.fromCMYK(value, m, y, k)))
            end
        }),

        M = Roact.createElement(Slider, {
            value = m,
            editorInputChanged = self.props.editorInputChanged,
            layoutOrder = 1,

            sliderLabel = "Magenta",
            unitLabel = "%",

            sliderGradient = ColorSequence.new(
                Color.toColor3(Color.fromCMYK(c, 0, y, k)),
                Color.toColor3(Color.fromCMYK(c, 1, y, k))
            ),
            markerColor = markerColor,

            valueToText = percentValueToText,
            textToValue = percentTextToValue,

            valueChanged = function(value)
                self:setState({
                    c = syncStateFromStore and c or nil,
                    m = value,
                    y = syncStateFromStore and y or nil,
                    k = syncStateFromStore and k or nil,
                })

                self.setColor(Color.toColor3(Color.fromCMYK(c, value, y, k)))
            end
        }),

        Y = Roact.createElement(Slider, {
            value = y,
            editorInputChanged = self.props.editorInputChanged,
            layoutOrder = 2,

            sliderLabel = "Yellow",
            unitLabel = "%",

            sliderGradient = ColorSequence.new(
                Color.toColor3(Color.fromCMYK(c, m, 0, k)),
                Color.toColor3(Color.fromCMYK(c, m, 1, k))
            ),
            markerColor = markerColor,

            valueToText = percentValueToText,
            textToValue = percentTextToValue,

            valueChanged = function(value)
                self:setState({
                    c = syncStateFromStore and c or nil,
                    m = syncStateFromStore and m or nil,
                    y = value,
                    k = syncStateFromStore and k or nil,
                })

                self.setColor(Color.toColor3(Color.fromCMYK(c, m, value, k)))
            end
        }),

        K = Roact.createElement(Slider, {
            value = k,
            editorInputChanged = self.props.editorInputChanged,
            layoutOrder = 3,

            sliderLabel = "Key",
            unitLabel = "%",

            sliderGradient = ColorSequence.new(
                Color.toColor3(Color.fromCMYK(c, m, y, 0)),
                Color.toColor3(Color.fromCMYK(c, m, y, 1))
            ),
            markerColor = markerColor,

            valueToText = percentValueToText,
            textToValue = percentTextToValue,

            valueChanged = function(value)
                self:setState({
                    c = syncStateFromStore and c or nil,
                    m = syncStateFromStore and m or nil,
                    y = syncStateFromStore and y or nil,
                    k = value,
                })

                self.setColor(Color.toColor3(Color.fromCMYK(c, m, y, value)))
            end
        }),
    })
end

---

HSBSliderPage.init = function(self, initProps)
    self.setColor = function(newColor)
        initProps.setColor(newColor, HSBSLIDER_KEY)
    end

    local h, s, b = Color.toHSB(Color.fromColor3(initProps.color))

    self:setState({
        h = h,
        s = s,
        b = b,
    })
end

HSBSliderPage.shouldUpdate = sliderShouldUpdateFactory(HSBSLIDER_KEY)

HSBSliderPage.render = function(self)
    local theme = self.props.theme

    local syncStateFromStore = (self.props.editor ~= HSBSLIDER_KEY)
    local h, s, b

    if (not syncStateFromStore) then
        h, s, b = self.state.h, self.state.s, self.state.b
    else
        h, s, b = Color.toHSB(Color.fromColor3(self.props.color))
    end

    local pureHueMarkerColor = Color.toColor3(Color.getBestContrastingColor(
        Color.fromHSB(h, 1, 1),
        Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
        Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
    ))

    local markerColor = Color.toColor3(Color.getBestContrastingColor(
        Color.fromHSB(h, s, b),
        Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
        Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
    ))

    return Roact.createFragment({
        UIListLayout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, Style.MajorElementPadding),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        }),

        H = Roact.createElement(Slider, {
            value = h,
            editorInputChanged = self.props.editorInputChanged,
            layoutOrder = 0,

            sliderLabel = "Hue",
            unitLabel = "°",

            sliderGradient = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                ColorSequenceKeypoint.new(1/6, Color3.fromHSV(1/6, 1, 1)),
                ColorSequenceKeypoint.new(2/6, Color3.fromHSV(2/6, 1, 1)),
                ColorSequenceKeypoint.new(3/6, Color3.fromHSV(3/6, 1, 1)),
                ColorSequenceKeypoint.new(4/6, Color3.fromHSV(4/6, 1, 1)),
                ColorSequenceKeypoint.new(5/6, Color3.fromHSV(5/6, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
            }),
            markerColor = pureHueMarkerColor,

            valueToText = valueToTextFactory(360),
            textToValue = textToValueFactory(360),

            valueChanged = function(value)
                self:setState({
                    h = value,
                    s = syncStateFromStore and s or nil,
                    b = syncStateFromStore and b or nil,
                })

                self.setColor(Color.toColor3(Color.fromHSB(value, s, b)))
            end
        }),

        S = Roact.createElement(Slider, {
            value = s,
            editorInputChanged = self.props.editorInputChanged,
            layoutOrder = 1,

            sliderLabel = "Saturation",
            unitLabel = "%",
            sliderGradient = ColorSequence.new(Color3.fromHSV(h, 0, b), Color3.fromHSV(h, 1, b)),
            markerColor = markerColor,

            valueToText = percentValueToText,
            textToValue = percentTextToValue,

            valueChanged = function(value)
                self:setState({
                    h = syncStateFromStore and h or nil,
                    s = value,
                    b = syncStateFromStore and b or nil,
                })

                self.setColor(Color.toColor3(Color.fromHSB(h, value, b)))
            end
        }),

        V = Roact.createElement(Slider, {
            value = b,
            editorInputChanged = self.props.editorInputChanged,
            layoutOrder = 2,

            sliderLabel = "Brightness",
            unitLabel = "%",
            sliderGradient = ColorSequence.new(Color3.fromHSV(h, s, 0), Color3.fromHSV(h, s, 1)),
            markerColor = markerColor,

            valueToText = percentValueToText,
            textToValue = percentTextToValue,

            valueChanged = function(value)
                self:setState({
                    h = syncStateFromStore and h or nil,
                    s = syncStateFromStore and s or nil,
                    b = value,
                })

                self.setColor(Color.toColor3(Color.fromHSB(h, s, value)))
            end
        }),
    })
end

---

HSLSliderPage.init = function(self, initProps)
    self.setColor = function(newColor)
        initProps.setColor(newColor, HSLSLIDER_KEY)
    end

    local h, s, l = Color.toHSL(Color.fromColor3(initProps.color))

    self:setState({
        h = h,
        s = s,
        l = l,
    })
end

HSLSliderPage.shouldUpdate = sliderShouldUpdateFactory(HSLSLIDER_KEY)

HSLSliderPage.render = function(self)
    local theme = self.props.theme

    local syncStateFromStore = (self.props.editor ~= HSLSLIDER_KEY)
    local h, s, l

    if (not syncStateFromStore) then
        h, s, l = self.state.h, self.state.s, self.state.l
    else
        h, s, l = Color.toHSL(Color.fromColor3(self.props.color))
    end

    local pureHueMarkerColor = Color.toColor3(Color.getBestContrastingColor(
        Color.fromHSL(h, 1, 0.5),
        Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
        Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
    ))

    local markerColor = Color.toColor3(Color.getBestContrastingColor(
        Color.fromHSL(h, s, l),
        Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
        Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
    ))

    return Roact.createFragment({
        UIListLayout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, Style.MajorElementPadding),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        }),

        H = Roact.createElement(Slider, {
            value = h,
            editorInputChanged = self.props.editorInputChanged,
            layoutOrder = 0,

            sliderLabel = "Hue",
            unitLabel = "°",

            sliderGradient = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                ColorSequenceKeypoint.new(1/6, Color3.fromHSV(1/6, 1, 1)),
                ColorSequenceKeypoint.new(2/6, Color3.fromHSV(2/6, 1, 1)),
                ColorSequenceKeypoint.new(3/6, Color3.fromHSV(3/6, 1, 1)),
                ColorSequenceKeypoint.new(4/6, Color3.fromHSV(4/6, 1, 1)),
                ColorSequenceKeypoint.new(5/6, Color3.fromHSV(5/6, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
            }),
            markerColor = pureHueMarkerColor,

            valueToText = valueToTextFactory(360),
            textToValue = textToValueFactory(360),

            valueChanged = function(value)
                self:setState({
                    h = value,
                    s = syncStateFromStore and s or nil,
                    l = syncStateFromStore and l or nil,
                })

                self.setColor(Color.toColor3(Color.fromHSL(value, s, l)))
            end
        }),

        S = Roact.createElement(Slider, {
            value = s,
            editorInputChanged = self.props.editorInputChanged,
            layoutOrder = 1,

            sliderLabel = "Saturation",
            unitLabel = "%",
            sliderGradient = ColorSequence.new(
                Color.toColor3(Color.fromHSL(h, 0, l)),
                Color.toColor3(Color.fromHSL(h, 1, l))
            ),
            markerColor = markerColor,

            valueToText = percentValueToText,
            textToValue = percentTextToValue,

            valueChanged = function(value)
                self:setState({
                    h = syncStateFromStore and h or nil,
                    s = value,
                    l = syncStateFromStore and l or nil,
                })

                self.setColor(Color.toColor3(Color.fromHSL(h, value, l)))
            end
        }),

        L = Roact.createElement(Slider, {
            value = l,
            editorInputChanged = self.props.editorInputChanged,
            layoutOrder = 2,

            sliderLabel = "Lightness",
            unitLabel = "%",
            sliderGradient = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color.toColor3(Color.fromHSL(h, s, 0))),
                ColorSequenceKeypoint.new(0.5, Color.toColor3(Color.fromHSL(h, s, 0.5))),
                ColorSequenceKeypoint.new(1, Color.toColor3(Color.fromHSL(h, s, 1)))
            }),
            markerColor = markerColor,

            valueToText = percentValueToText,
            textToValue = percentTextToValue,

            valueChanged = function(value)
                self:setState({
                    h = syncStateFromStore and h or nil,
                    s = syncStateFromStore and s or nil,
                    l = value,
                })

                self.setColor(Color.toColor3(Color.fromHSL(h, s, value)))
            end
        }),
    })
end

---

GreyscaleSliderPage.init = function(self, initProps)
    self.setColor = function(newColor)
        initProps.setColor(newColor, GREYSLIDER_KEY)
    end

    local color = initProps.color

    self:setState({
        bw = (color.R + color.G + color.B) / 3
    })
end

GreyscaleSliderPage.shouldUpdate = sliderShouldUpdateFactory(GREYSLIDER_KEY)

GreyscaleSliderPage.render = function(self)
    local theme = self.props.theme
    local bw

    if (self.props.editor == GREYSLIDER_KEY) then
        bw = self.state.bw
    else
        local color = self.props.color

        bw = (color.R + color.G + color.B) / 3
    end

    return Roact.createFragment({
        UIListLayout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, Style.MajorElementPadding),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        }),

        Slider = Roact.createElement(Slider, {
            value = bw,
            editorInputChanged = self.props.editorInputChanged,
            layoutOrder = 0,

            sliderLabel = "Black-White",
        --  unitLabel = "%",

            sliderGradient = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(1, 1, 1)),

            markerColor = Color.toColor3(Color.getBestContrastingColor(
                Color.fromRGB(bw, bw, bw),
                Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
            )),

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
                    bw = value
                })

                self.setColor(Color3.new(value, value, value))
            end
        })
    })
end

---

SliderPages = function(props)
    return Roact.createElement(Pages, {
        initPage = props.lastSliderPage,
        onPageChanged = props.updateSliderPage,

        pages = {
            {
                name = "RGB",
                content = Roact.createElement(RGBSliderPage, {
                    editorInputChanged = props.editorInputChanged,
                })
            },

            {
                name = "CMYK",
                content = Roact.createElement(CMYKSliderPage, {
                    editorInputChanged = props.editorInputChanged,
                })
            },

            {
                name = "HSB",
                content = Roact.createElement(HSBSliderPage, {
                    editorInputChanged = props.editorInputChanged,
                })
            },

            {
                name = "HSL",
                content = Roact.createElement(HSLSliderPage, {
                    editorInputChanged = props.editorInputChanged,
                })
            },

            {
                name = "Monochrome",
                content = Roact.createElement(GreyscaleSliderPage, {
                    editorInputChanged = props.editorInputChanged,
                })
            },

            {
                name = "Temperature",
                content = Roact.createElement(KelvinSliderPage, {
                    editorInputChanged = props.editorInputChanged,
                })
            },
        }
    })
end

RGBSliderPage = ConnectStore(RGBSliderPage)
CMYKSliderPage = ConnectStore(CMYKSliderPage)
HSBSliderPage = ConnectStore(HSBSliderPage)
HSLSliderPage = ConnectStore(HSLSliderPage)
GreyscaleSliderPage = ConnectStore(GreyscaleSliderPage)

return RoactRodux.connect(function(state)
    return {
        lastSliderPage = state.sessionData.lastSliderPage,
    }
end, function(dispatch)
    return {
        updateSliderPage = function(sliderPage)
            dispatch({
                type = PluginEnums.StoreActionType.UpdateSessionData,
                slice = {
                    lastSliderPage = sliderPage
                }
            })
        end,
    }
end)(SliderPages)