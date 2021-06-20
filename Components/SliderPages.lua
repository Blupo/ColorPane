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
local Pages = require(Components:FindFirstChild("Pages"))
local Slider = require(Components:FindFirstChild("Slider"))

---

local SliderPages
local RGBSliderPage = Roact.Component:extend("RGBSliderPage")
local CMYKSliderPage = Roact.Component:extend("CMYKSliderPage")
local HSBSliderPage = Roact.Component:extend("HSBSliderPage")
local HSLSliderPage = Roact.Component:extend("HSLSliderPage")
local GreyscaleSliderPage = Roact.Component:extend("GreyscaleSliderPage")
local KelvinSliderPage = require(Components:FindFirstChild("KelvinSliderPage"))

local shallowCompare = Util.shallowCompare

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

local sliderShouldUpdateFactory = function(key, updateComponents)
    return function(self, nextProps, nextState)
        local propsDiff = shallowCompare(self.props, nextProps)
        local stateDiff = shallowCompare(self.state, nextState)
    
        if (table.find(propsDiff, "color")) then
            if (nextProps.editor ~= key) then
                updateComponents(self, nextProps.color)
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
    local initColor = initProps.color

    self.components, self.updateComponents = Roact.createBinding({
        r = initColor.R,
        g = initColor.G,
        b = initColor.B
    })

    self.markerColor = self.components:map(function(components)
        local theme = self.props.theme

        return Color.toColor3(Color.getBestContrastingColor(
            Color.fromRGB(components.r, components.g, components.b),
            Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
            Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
        ))
    end)

    self.setColor = function(newColor)
        initProps.setColor(newColor, PluginEnums.EditorKey.RGBSlider)
    end
end

RGBSliderPage.shouldUpdate = sliderShouldUpdateFactory(PluginEnums.EditorKey.RGBSlider, function(self, color)
    self.updateComponents({
        r = color.R,
        g = color.G,
        b = color.B
    })
end)

RGBSliderPage.render = function(self)
    return Roact.createFragment({
        UIListLayout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, Style.MajorElementPadding),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        }),

        R = Roact.createElement(Slider, {
            LayoutOrder = 0,

            sliderLabel = "Red",
            markerColor = self.markerColor,
            editorInputChanged = self.props.editorInputChanged,

            sliderGradient = self.components:map(function(components)
                return ColorSequence.new(Color3.new(0, components.g, components.b), Color3.new(1, components.g, components.b))
            end),

            value = self.components:map(function(components) return components.r end),
            valueToText = rgbValueToText,
            textToValue = rgbTextToValue,

            valueChanged = function(value)
                local components = self.components:getValue()

                self.updateComponents({
                    r = value,
                    g = components.g,
                    b = components.b,
                })

                self.setColor(Color3.new(value, components.g, components.b))
            end
        }),

        G = Roact.createElement(Slider, {
            LayoutOrder = 1,            

            sliderLabel = "Green",
            markerColor = self.markerColor,
            editorInputChanged = self.props.editorInputChanged,

            sliderGradient = self.components:map(function(components)
                return ColorSequence.new(Color3.new(components.r, 0, components.b), Color3.new(components.r, 1, components.b))
            end),

            value = self.components:map(function(components) return components.g end),
            valueToText = rgbValueToText,
            textToValue = rgbTextToValue,

            valueChanged = function(value)
                local components = self.components:getValue()

                self.updateComponents({
                    r = components.r,
                    g = value,
                    b = components.b,
                })

                self.setColor(Color3.new(components.r, value, components.b))
            end
        }),

        B = Roact.createElement(Slider, {
            LayoutOrder = 2,

            sliderLabel = "Blue",
            markerColor = self.markerColor,
            editorInputChanged = self.props.editorInputChanged,

            sliderGradient = self.components:map(function(components)
                return ColorSequence.new(Color3.new(components.r, components.g, 0), Color3.new(components.r, components.g, 1))
            end),

            value = self.components:map(function(components) return components.b end),
            valueToText = rgbValueToText,
            textToValue = rgbTextToValue,

            valueChanged = function(value)
                local components = self.components:getValue()

                self.updateComponents({
                    r = components.r,
                    g = components.g,
                    b = value,
                })

                self.setColor(Color3.new(components.r, components.g, value))
            end
        }),
    })
end

---

CMYKSliderPage.init = function(self, initProps)
    local initC, initM, initY, initK = Color.toCMYK(Color.fromColor3(initProps.color))

    self.components, self.updateComponents = Roact.createBinding({
        c = initC,
        m = initM,
        y = initY,
        k = initK,
    })

    self.markerColor = self.components:map(function(components)
        local theme = self.props.theme

        return Color.toColor3(Color.getBestContrastingColor(
            Color.fromCMYK(components.c, components.m, components.y, components.k),
            Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
            Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
        ))
    end)

    self.setColor = function(newColor)
        initProps.setColor(newColor, PluginEnums.EditorKey.CMYKSlider)
    end
end

CMYKSliderPage.shouldUpdate = sliderShouldUpdateFactory(PluginEnums.EditorKey.CMYKSlider, function(self, color)
    local c, m, y, k = Color.toCMYK(Color.fromColor3(color))

    self.updateComponents({
        c = c,
        m = m,
        y = y,
        k = k
    })
end)

CMYKSliderPage.render = function(self)
    return Roact.createFragment({
        UIListLayout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, Style.MajorElementPadding),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        }),

        C = Roact.createElement(Slider, {
            LayoutOrder = 0,
            
            value = self.components:map(function(components) return components.c end),
            editorInputChanged = self.props.editorInputChanged,
            
            sliderLabel = "Cyan",
            unitLabel = "%",
            markerColor = self.markerColor,

            sliderGradient = self.components:map(function(components)
                return ColorSequence.new(
                    Color.toColor3(Color.fromCMYK(0, components.m, components.y, components.k)),
                    Color.toColor3(Color.fromCMYK(1, components.m, components.y, components.k))
                )
            end),

            valueToText = percentValueToText,
            textToValue = percentTextToValue,

            valueChanged = function(value)
                local components = self.components:getValue()

                self.updateComponents({
                    c = value,
                    m = components.m,
                    y = components.y,
                    k = components.k
                })

                self.setColor(Color.toColor3(Color.fromCMYK(value, components.m, components.y, components.k)))
            end
        }),

        M = Roact.createElement(Slider, {
            LayoutOrder = 1,
            
            value = self.components:map(function(components) return components.m end),
            editorInputChanged = self.props.editorInputChanged,

            sliderLabel = "Magenta",
            unitLabel = "%",
            markerColor = self.markerColor,

            sliderGradient = self.components:map(function(components)
                return ColorSequence.new(
                    Color.toColor3(Color.fromCMYK(components.c, 0, components.y, components.k)),
                    Color.toColor3(Color.fromCMYK(components.c, 1, components.y, components.k))
                )
            end),

            valueToText = percentValueToText,
            textToValue = percentTextToValue,

            valueChanged = function(value)
                local components = self.components:getValue()

                self.updateComponents({
                    c = components.c,
                    m = value,
                    y = components.y,
                    k = components.k
                })

                self.setColor(Color.toColor3(Color.fromCMYK(components.c, value, components.y, components.k)))
            end
        }),

        Y = Roact.createElement(Slider, {
            LayoutOrder = 2,
            
            value = self.components:map(function(components) return components.y end),
            editorInputChanged = self.props.editorInputChanged,

            sliderLabel = "Yellow",
            unitLabel = "%",
            markerColor = self.markerColor,

            sliderGradient = self.components:map(function(components)
                return ColorSequence.new(
                    Color.toColor3(Color.fromCMYK(components.c, components.m, 0, components.k)),
                    Color.toColor3(Color.fromCMYK(components.c, components.m, 1, components.k))
                )
            end),

            valueToText = percentValueToText,
            textToValue = percentTextToValue,

            valueChanged = function(value)
                local components = self.components:getValue()

                self.updateComponents({
                    c = components.c,
                    m = components.m,
                    y = value,
                    k = components.k
                })

                self.setColor(Color.toColor3(Color.fromCMYK(components.c, components.m, value, components.k)))
            end
        }),

        K = Roact.createElement(Slider, {
            LayoutOrder = 3,
            
            value = self.components:map(function(components) return components.k end),
            editorInputChanged = self.props.editorInputChanged,

            sliderLabel = "Key",
            unitLabel = "%",
            markerColor = self.markerColor,

            sliderGradient = self.components:map(function(components)
                return ColorSequence.new(
                    Color.toColor3(Color.fromCMYK(components.c, components.m, components.y, 0)),
                    Color.toColor3(Color.fromCMYK(components.c, components.m, components.y, 1))
                )
            end),

            valueToText = percentValueToText,
            textToValue = percentTextToValue,

            valueChanged = function(value)
                local components = self.components:getValue()

                self.updateComponents({
                    c = components.c,
                    m = components.m,
                    y = components.y,
                    k = value
                })

                self.setColor(Color.toColor3(Color.fromCMYK(components.c, components.m, components.y, value)))
            end
        }),
    })
end

---

HSBSliderPage.init = function(self, initProps)
    local initH, initS, initB = Color.toHSB(Color.fromColor3(initProps.color))

    self.components, self.updateComponents = Roact.createBinding({
        h = initH,
        s = initS,
        b = initB,
    })

    self.markerColor = self.components:map(function(components)
        local theme = self.props.theme

        return Color.toColor3(Color.getBestContrastingColor(
            Color.fromHSB(components.h, components.s, components.b),
            Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
            Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
        ))
    end)

    self.setColor = function(newColor)
        initProps.setColor(newColor, PluginEnums.EditorKey.HSBSlider)
    end
end

HSBSliderPage.shouldUpdate = sliderShouldUpdateFactory(PluginEnums.EditorKey.HSBSlider, function(self, color)
    local h, s, b = Color.toHSB(Color.fromColor3(color))

    self.updateComponents({
        h = h,
        s = s,
        b = b,
    })
end)

HSBSliderPage.render = function(self)
    return Roact.createFragment({
        UIListLayout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, Style.MajorElementPadding),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        }),

        H = Roact.createElement(Slider, {
            LayoutOrder = 0,
            
            value = self.components:map(function(components) return components.h end),
            editorInputChanged = self.props.editorInputChanged,

            sliderLabel = "Hue",
            unitLabel = "°",
            markerColor = self.components:map(function(components)
                local theme = self.props.theme

                return Color.toColor3(Color.getBestContrastingColor(
                    Color.fromHSB(components.h, 1, 1),
                    Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                    Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
                ))
            end),

            sliderGradient = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                ColorSequenceKeypoint.new(1/6, Color3.fromHSV(1/6, 1, 1)),
                ColorSequenceKeypoint.new(2/6, Color3.fromHSV(2/6, 1, 1)),
                ColorSequenceKeypoint.new(3/6, Color3.fromHSV(3/6, 1, 1)),
                ColorSequenceKeypoint.new(4/6, Color3.fromHSV(4/6, 1, 1)),
                ColorSequenceKeypoint.new(5/6, Color3.fromHSV(5/6, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
            }),

            valueToText = valueToTextFactory(360),
            textToValue = textToValueFactory(360),

            valueChanged = function(value)
                local components = self.components:getValue()

                self.updateComponents({
                    h = value,
                    s = components.s,
                    b = components.b
                })

                self.setColor(Color.toColor3(Color.fromHSB(value, components.s, components.b)))
            end
        }),

        S = Roact.createElement(Slider, {
            LayoutOrder = 1,

            value = self.components:map(function(components) return components.s end),
            editorInputChanged = self.props.editorInputChanged,

            sliderLabel = "Saturation",
            unitLabel = "%",
            markerColor = self.markerColor,

            sliderGradient = self.components:map(function(components)
                return ColorSequence.new(Color3.fromHSV(components.h, 0, components.b), Color3.fromHSV(components.h, 1, components.b))
            end),

            valueToText = percentValueToText,
            textToValue = percentTextToValue,

            valueChanged = function(value)
                local components = self.components:getValue()

                self.updateComponents({
                    h = components.h,
                    s = value,
                    b = components.b
                })

                self.setColor(Color.toColor3(Color.fromHSB(components.h, value, components.b)))
            end
        }),

        B = Roact.createElement(Slider, {
            LayoutOrder = 2,

            value = self.components:map(function(components) return components.b end),
            editorInputChanged = self.props.editorInputChanged,

            sliderLabel = "Brightness",
            unitLabel = "%",
            markerColor = self.markerColor,

            sliderGradient = self.components:map(function(components)
                return ColorSequence.new(Color3.fromHSV(components.h, components.s, 0), Color3.fromHSV(components.h, components.s, 1))
            end),

            valueToText = percentValueToText,
            textToValue = percentTextToValue,

            valueChanged = function(value)
                local components = self.components:getValue()

                self.updateComponents({
                    h = components.h,
                    s = components.s,
                    b = value
                })

                self.setColor(Color.toColor3(Color.fromHSB(components.h, components.s, value)))
            end
        }),
    })
end

---

HSLSliderPage.init = function(self, initProps)
    local initH, initS, initL = Color.toHSL(Color.fromColor3(initProps.color))

    self.components, self.updateComponents = Roact.createBinding({
        h = initH,
        s = initS,
        l = initL
    })

    self.markerColor = self.components:map(function(components)
        local theme = self.props.theme

        return Color.toColor3(Color.getBestContrastingColor(
            Color.fromHSL(components.h, components.s, components.l),
            Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
            Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
        ))
    end)

    self.setColor = function(newColor)
        initProps.setColor(newColor, PluginEnums.EditorKey.HSLSlider)
    end
end

HSLSliderPage.shouldUpdate = sliderShouldUpdateFactory(PluginEnums.EditorKey.HSLSlider, function(self, color)
    local h, s, l = Color.toHSL(Color.fromColor3(color))

    self.updateComponents({
        h = h,
        s = s,
        l = l,
    })
end)

HSLSliderPage.render = function(self)
    return Roact.createFragment({
        UIListLayout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, Style.MajorElementPadding),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        }),

        H = Roact.createElement(Slider, {
            LayoutOrder = 0,

            value = self.components:map(function(components) return components.h end),
            editorInputChanged = self.props.editorInputChanged,

            sliderLabel = "Hue",
            unitLabel = "°",

            markerColor = self.components:map(function(components)
                local theme = self.props.theme

                return Color.toColor3(Color.getBestContrastingColor(
                    Color.fromHSL(components.h, 1, 0.5),
                    Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                    Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
                ))
            end),

            sliderGradient = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                ColorSequenceKeypoint.new(1/6, Color3.fromHSV(1/6, 1, 1)),
                ColorSequenceKeypoint.new(2/6, Color3.fromHSV(2/6, 1, 1)),
                ColorSequenceKeypoint.new(3/6, Color3.fromHSV(3/6, 1, 1)),
                ColorSequenceKeypoint.new(4/6, Color3.fromHSV(4/6, 1, 1)),
                ColorSequenceKeypoint.new(5/6, Color3.fromHSV(5/6, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
            }),

            valueToText = valueToTextFactory(360),
            textToValue = textToValueFactory(360),

            valueChanged = function(value)
                local components = self.components:getValue()

                self.updateComponents({
                    h = value,
                    s = components.s,
                    l = components.l
                })

                self.setColor(Color.toColor3(Color.fromHSL(value, components.s, components.l)))
            end
        }),

        S = Roact.createElement(Slider, {
            LayoutOrder = 1,

            value = self.components:map(function(components) return components.s end),
            editorInputChanged = self.props.editorInputChanged,

            sliderLabel = "Saturation",
            unitLabel = "%",
            markerColor = self.markerColor,

            sliderGradient = self.components:map(function(components)
                return ColorSequence.new(
                    Color3.fromHSV(components.h, 0, components.l),
                    Color3.fromHSV(components.h, 1, components.l)
                )
            end),

            valueToText = percentValueToText,
            textToValue = percentTextToValue,

            valueChanged = function(value)
                local components = self.components:getValue()

                self.updateComponents({
                    h = components.h,
                    s = value,
                    l = components.l
                })

                self.setColor(Color.toColor3(Color.fromHSL(components.h, value, components.l)))
            end
        }),

        L = Roact.createElement(Slider, {
            LayoutOrder = 2,

            value = self.components:map(function(components) return components.l end),
            editorInputChanged = self.props.editorInputChanged,

            sliderLabel = "Lightness",
            unitLabel = "%",
            markerColor = self.markerColor,

            sliderGradient = self.components:map(function(components)
                return ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color.toColor3(Color.fromHSL(components.h, components.s, 0))),
                    ColorSequenceKeypoint.new(0.5, Color.toColor3(Color.fromHSL(components.h, components.s, 0.5))),
                    ColorSequenceKeypoint.new(1, Color.toColor3(Color.fromHSL(components.h, components.s, 1)))
                })
            end),

            valueToText = percentValueToText,
            textToValue = percentTextToValue,

            valueChanged = function(value)
                local components = self.components:getValue()

                self.updateComponents({
                    h = components.h,
                    s = components.s,
                    l = value
                })

                self.setColor(Color.toColor3(Color.fromHSL(components.h, components.s, value)))
            end
        }),
    })
end

---

GreyscaleSliderPage.init = function(self, initProps)
    local initColor = initProps.color

    self.brightness, self.updateBrightness = Roact.createBinding((initColor.R + initColor.G + initColor.B) / 3)

    self.setColor = function(newColor)
        initProps.setColor(newColor, PluginEnums.EditorKey.GreyscaleSlider)
    end
end

GreyscaleSliderPage.shouldUpdate = sliderShouldUpdateFactory(PluginEnums.EditorKey.GreyscaleSlider, function(self, color)
    self.updateBrightness((color.R + color.G + color.B) / 3)
end)

GreyscaleSliderPage.render = function(self)
    return Roact.createFragment({
        UIListLayout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, Style.MajorElementPadding),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        }),

        Slider = Roact.createElement(Slider, {
            value = self.brightness,
            editorInputChanged = self.props.editorInputChanged,

            sliderLabel = "Brightness",
            sliderGradient = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(1, 1, 1)),

            markerColor = self.brightness:map(function(brightness)
                local theme = self.props.theme

                return Color.toColor3(Color.getBestContrastingColor(
                    Color.fromRGB(brightness, brightness, brightness),
                    Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                    Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
                ))
            end),

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
                self.updateBrightness(value)
                self.setColor(Color3.new(value, value, value))
            end
        })
    })
end

---

SliderPages = function(props)
    return Roact.createElement(Pages, {
        selectedPage = props.lastSliderPage,
        onPageChanged = props.updateSliderPage,

        pageSections = {
            {
                name = "",

                items = {
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
            }
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
        updateSliderPage = function(section, page)
            dispatch({
                type = PluginEnums.StoreActionType.UpdateSessionData,
                slice = {
                    lastSliderPage = {section, page}
                }
            })
        end,
    }
end)(SliderPages)