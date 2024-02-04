--!strict

local PluginModules = script.Parent
local Util = require(PluginModules.Util)

---

local PluginEnums = {
    StoreActionType = {
        SetTheme = "SetTheme",
        UpdateSessionData = "UpdateSessionData",

        ColorEditor_SetColor = "ColorEditor_SetColor",
        ColorEditor_AddQuickPaletteColor = "ColorEditor_AddQuickPaletteColor",

        GradientEditor_ResetState = "GradientEditor_ResetState",
        GradientEditor_SetKeypoints = "GradientEditor_SetKeypoints",
        GradientEditor_SetGradient = "GradientEditor_SetGradient",
        GradientEditor_SetSnapValue = "GradientEditor_SetSnapValue",
    },

    EditorKey = {
        ColorWheel = "ColorWheel",
        RGBSlider = "RGBSlider",
        CMYKSlider = "CMYKSlider",
        HSBSlider = "HSBSlider",
        HSLSlider = "HSLSlider",
        GreyscaleSlider = "GreyscaleSlider",
        KelvinSlider = "KelvinSlider",

        Default = "Default",
    },

    PromptError = {
        InvalidPromptOptions = "InvalidPromptOptions",
        PromptAlreadyOpen = "PromptAlreadyOpen",
        ReservationProblem = "ReservationProblem",
        PromptCancelled = "PromptCancelled"
    },
}

---

Util.table.deepFreeze(PluginEnums)
return PluginEnums