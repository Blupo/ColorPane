-- A Pages container for various color sliders in various color spaces

local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local Translator = require(CommonModules.Translator)

local CommonIncludes = Common.Includes
local Roact = require(CommonIncludes.RoactRodux.Roact)
local RoactRodux = require(CommonIncludes.RoactRodux.RoactRodux)

local Includes = root.Includes
local Color = require(Includes.Color).Color

local Modules = root.Modules
local PluginEnums = require(Modules.PluginEnums)

local Components = root.Components
local GreyscaleSliderPage = require(Components.GreyscaleSliderPage)
local Pages = require(Components.Pages)
local SliderPage = require(Components.SliderPage)
local TemperatureSliderPage = require(Components.TemperatureSliderPage)

---

local uiTranslations = Translator.GenerateTranslationTable({
    "RGB_ColorType",
    "CMYK_ColorType",
    "HSB_ColorType",
    "HSL_ColorType",
    
    "Hue_Component",
    "Saturation_Component",

    "HSB_Brightness_Component",
    "HSL_Lightness_Component",

    "RGB_Red_Component",
    "RGB_Green_Component",
    "RGB_Blue_Component",

    "CMYK_Cyan_Component",
    "CMYK_Magenta_Component",
    "CMYK_Yellow_Component",
    "CMYK_Key_Component",

    "Monochrome_Slider",
    "Temperature_Label",
})

---

--[[
    store props

        lastSliderPage: number
        updateSliderPage: (number) -> nil
]]

local SliderPages = Roact.PureComponent:extend("SliderPages")

SliderPages.render = function(self)
    return Roact.createElement(Pages, {
        selectedPage = self.props.lastSliderPage,
        onPageChanged = self.props.updateSliderPage,

        pageSections = {
            {
                name = "",

                items = {
                    {
                        name = uiTranslations["RGB_ColorType"],

                        content = Roact.createElement(SliderPage, {
                            colorSpace = "RGB",
                            editorKey = PluginEnums.EditorKey.RGBSlider,
                            componentKeys = {"R", "G", "B"},

                            componentRanges = {
                                R = {0, 255},
                                G = {0, 255},
                                B = {0, 255}
                            },

                            componentLabels = {
                                R = uiTranslations["RGB_Red_Component"],
                                G = uiTranslations["RGB_Green_Component"],
                                B = uiTranslations["RGB_Blue_Component"]
                            },

                            componentUnitLabels = {
                                R = nil,
                                G = nil,
                                B = nil
                            },

                            componentSliderGradientGenerators = {
                                R = function(components)
                                    return ColorSequence.new(Color3.fromRGB(0, components.G, components.B), Color3.fromRGB(255, components.G, components.B))
                                end,

                                G = function(components)
                                    return ColorSequence.new(Color3.fromRGB(components.R, 0, components.B), Color3.fromRGB(components.R, 255, components.B))
                                end,

                                B = function(components)
                                    return ColorSequence.new(Color3.fromRGB(components.R, components.G, 0), Color3.fromRGB(components.R, components.G, 255))
                                end,
                            },
                        })
                    },

                    {
                        name = uiTranslations["CMYK_ColorType"],

                        content = Roact.createElement(SliderPage, {
                            colorSpace = "CMYK",
                            editorKey = PluginEnums.EditorKey.CMYKSlider,
                            componentKeys = {"C", "M", "Y", "K"},

                            componentRanges = {
                                C = {0, 1},
                                M = {0, 1},
                                Y = {0, 1},
                                K = {0, 1}
                            },

                            componentDisplayRanges = {
                                C = {0, 100},
                                M = {0, 100},
                                Y = {0, 100},
                                K = {0, 100}
                            },

                            componentLabels = {
                                C = uiTranslations["CMYK_Cyan_Component"],
                                M = uiTranslations["CMYK_Magenta_Component"],
                                Y = uiTranslations["CMYK_Yellow_Component"],
                                K = uiTranslations["CMYK_Key_Component"],
                            },

                            componentUnitLabels = {
                                C = "%",
                                M = "%",
                                Y = "%",
                                K = "%",
                            },

                            componentSliderGradientGenerators = {
                                C = function(components)
                                    return ColorSequence.new(
                                        Color.fromCMYK(0, components.M, components.Y, components.K):toColor3(),
                                        Color.fromCMYK(1, components.M, components.Y, components.K):toColor3()
                                    )
                                end,

                                M = function(components)
                                    return ColorSequence.new(
                                        Color.fromCMYK(components.C, 0, components.Y, components.K):toColor3(),
                                        Color.fromCMYK(components.C, 1, components.Y, components.K):toColor3()
                                    )
                                end,

                                Y = function(components)
                                    return ColorSequence.new(
                                        Color.fromCMYK(components.C, components.M, 0, components.K):toColor3(),
                                        Color.fromCMYK(components.C, components.M, 1, components.K):toColor3()
                                    )
                                end,

                                K = function(components)
                                    return ColorSequence.new(
                                        Color.fromCMYK(components.C, components.M, components.Y, 0):toColor3(),
                                        Color.fromCMYK(components.C, components.M, components.Y, 1):toColor3()
                                    )
                                end,
                            },
                        })
                    },

                    {
                        name = uiTranslations["HSB_ColorType"],

                        content = Roact.createElement(SliderPage, {
                            colorSpace = "HSB",
                            editorKey = PluginEnums.EditorKey.HSBSlider,
                            componentKeys = {"H", "S", "B"},

                            componentRanges = {
                                H = {0, 360},
                                S = {0, 1},
                                B = {0, 1}
                            },

                            componentDisplayRanges = {
                                S = {0, 100},
                                B = {0, 100},
                            },

                            componentLabels = {
                                H = uiTranslations["Hue_Component"],
                                S = uiTranslations["Saturation_Component"],
                                B = uiTranslations["HSB_Brightness_Component"]
                            },

                            componentUnitLabels = {
                                H = "°",
                                S = "%",
                                B = "%"
                            },

                            componentSliderGradientGenerators = {
                                H = function()
                                    return ColorSequence.new({
                                        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                                        ColorSequenceKeypoint.new(1/6, Color3.fromHSV(1/6, 1, 1)),
                                        ColorSequenceKeypoint.new(2/6, Color3.fromHSV(2/6, 1, 1)),
                                        ColorSequenceKeypoint.new(3/6, Color3.fromHSV(3/6, 1, 1)),
                                        ColorSequenceKeypoint.new(4/6, Color3.fromHSV(4/6, 1, 1)),
                                        ColorSequenceKeypoint.new(5/6, Color3.fromHSV(5/6, 1, 1)),
                                        ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
                                    })
                                end,

                                S = function(components)
                                    return ColorSequence.new(
                                        Color3.fromHSV(components.H / 360, 0, components.B),
                                        Color3.fromHSV(components.H / 360, 1, components.B)
                                    )
                                end,

                                B = function(components)
                                    return ColorSequence.new(
                                        Color3.fromHSV(components.H / 360, components.S, 0),
                                        Color3.fromHSV(components.H / 360, components.S, 1)
                                    )
                                end,
                            },

                            sliderMarkerColorGenerators = {
                                H = function(components, theme)
                                    return Color.fromHSB(components.H / 360, 1, 1):bestContrastingColor(
                                        Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                                        Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)):invert()
                                    ):toColor3()
                                end
                            }
                        })
                    },

                    {
                        name = uiTranslations["HSL_ColorType"],

                        content = Roact.createElement(SliderPage, {
                            colorSpace = "HSL",
                            editorKey = PluginEnums.EditorKey.HSLSlider,
                            componentKeys = {"H", "S", "L"},

                            componentRanges = {
                                H = {0, 360},
                                S = {0, 1},
                                L = {0, 1}
                            },

                            componentDisplayRanges = {
                                S = {0, 100},
                                L = {0, 100},
                            },

                            componentLabels = {
                                H = uiTranslations["Hue_Component"],
                                S = uiTranslations["Saturation_Component"],
                                L = uiTranslations["HSL_Lightness_Component"]
                            },

                            componentUnitLabels = {
                                H = "°",
                                S = "%",
                                L = "%"
                            },

                            componentSliderGradientGenerators = {
                                H = function()
                                    return ColorSequence.new({
                                        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                                        ColorSequenceKeypoint.new(1/6, Color3.fromHSV(1/6, 1, 1)),
                                        ColorSequenceKeypoint.new(2/6, Color3.fromHSV(2/6, 1, 1)),
                                        ColorSequenceKeypoint.new(3/6, Color3.fromHSV(3/6, 1, 1)),
                                        ColorSequenceKeypoint.new(4/6, Color3.fromHSV(4/6, 1, 1)),
                                        ColorSequenceKeypoint.new(5/6, Color3.fromHSV(5/6, 1, 1)),
                                        ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
                                    })
                                end,

                                S = function(components)
                                    return ColorSequence.new({
                                        ColorSequenceKeypoint.new(0, Color.fromHSL(components.H, 0, components.L):toColor3()),
                                        ColorSequenceKeypoint.new(0.5, Color.fromHSL(components.H, 0.5, components.L):toColor3()),
                                        ColorSequenceKeypoint.new(1, Color.fromHSL(components.H, 1, components.L):toColor3())
                                    })
                                end,

                                L = function(components)
                                    return ColorSequence.new({
                                        ColorSequenceKeypoint.new(0, Color.fromHSL(components.H, components.S, 0):toColor3()),
                                        ColorSequenceKeypoint.new(0.5, Color.fromHSL(components.H, components.S, 0.5):toColor3()),
                                        ColorSequenceKeypoint.new(1, Color.fromHSL(components.H, components.S, 1):toColor3())
                                    })
                                end,
                            },

                            sliderMarkerColorGenerators = {
                                H = function(components, theme)
                                    return Color.fromHSB(components.H / 360, 1, 1):bestContrastingColor(
                                        Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                                        Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)):invert()
                                    ):toColor3()
                                end
                            }
                        })
                    },

                    {
                        name = uiTranslations["Monochrome_Slider"],
                        content = Roact.createElement(GreyscaleSliderPage)
                    },

                    {
                        name = uiTranslations["Temperature_Label"],
                        content = Roact.createElement(TemperatureSliderPage)
                    },
                }
            }
        }
    })
end

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