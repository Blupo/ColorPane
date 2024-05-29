--!strict
-- Provides enum types

return {
    StoreActionType = {
        SetTheme = "SetTheme",
        UpstreamAvailabilityChanged = "UpstreamAvailabilityChanged",
        UpdateSessionData = "UpdateSessionData",

        ColorEditor_SetColor = "ColorEditor_SetColor",
        ColorEditor_AddQuickPaletteColor = "ColorEditor_AddQuickPaletteColor",
        ColorEditor_AddPalette = "ColorEditor_AddPalette",
        ColorEditor_RemovePalette = "ColorEditor_RemovePalette",
        ColorEditor_DuplicatePalette = "ColorEditor_DuplicatePalette",
        ColorEditor_ChangePaletteName = "ColorEditor_ChangePaletteName",
        ColorEditor_AddPaletteColor = "ColorEditor_AddPaletteColor",
        ColorEditor_AddCurrentColorToPalette = "ColorEditor_AddCurrentColorToPalette",
        ColorEditor_RemovePaletteColor = "ColorEditor_RemovePaletteColor",
        ColorEditor_ChangePaletteColorName = "ColorEditor_ChangePaletteColorName",
        ColorEditor_ChangePaletteColorPosition = "ColorEditor_ChangePaletteColorPosition",
        ColorEditor_SetPalettes = "ColorEditor_SetPalettes",

        GradientEditor_ResetState = "GradientEditor_ResetState",
        GradientEditor_SetKeypoints = "GradientEditor_SetKeypoints",
        GradientEditor_SetGradient = "GradientEditor_SetGradient",
        GradientEditor_SetSnapValue = "GradientEditor_SetSnapValue",
        GradientEditor_RemovePaletteGradient = "GradientEditor_RemovePaletteGradient",
        GradientEditor_ChangePaletteGradientName = "GradientEditor_ChangePaletteGradientName",
        GradientEditor_ChangePaletteGradientPosition = "GradientEditor_ChangePaletteGradientPosition",
        GradientEditor_AddPalette = "GradientEditor_AddPalette",
        GradientEditor_RemovePalette = "GradientEditor_RemovePalette",
        GradientEditor_DuplicatePalette = "GradientEditor_DuplicatePalette",
        GradientEditor_ChangePaletteName = "GradientEditor_ChangePaletteName",
        GradientEditor_AddPaletteGradient = "GradientEditor_AddPaletteGradient",
        GradientEditor_AddCurrentGradientToPalette = "GradientEditor_AddCurrentGradientToPalette",
        GradientEditor_SetPalettes = "GradientEditor_SetPalettes",
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

    PromptRejection = {
        InvalidPromptOptions = "InvalidPromptOptions",
        PromptAlreadyOpen = "PromptAlreadyOpen",
        ReservationProblem = "ReservationProblem",
        PromptCancelled = "PromptCancelled",
        SameAsInitial = "SameAsInitial",
    }
}