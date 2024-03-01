--!strict
-- Provides enum types

return {
    StoreActionType = {
        SetTheme = "SetTheme",
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

        GradientEditor_ResetState = "GradientEditor_ResetState",
        GradientEditor_SetKeypoints = "GradientEditor_SetKeypoints",
        GradientEditor_SetGradient = "GradientEditor_SetGradient",
        GradientEditor_SetSnapValue = "GradientEditor_SetSnapValue",
        GradientEditor_AddPaletteColor = "GradientEditor_AddPaletteColor",
        GradientEditor_RemovePaletteColor = "GradientEditor_RemovePaletteColor",
        GradientEditor_ChangePaletteColorName = "GradientEditor_ChangePaletteColorName",
        GradientEditor_ChangePaletteColorPosition = "GradientEditor_ChangePaletteColorPosition",
    },

    PluginSettingKey = {
        UserPalettes = "UserPalettes",
        SnapValue = "SnapValue",
        AutoLoadColorProperties = "AutoLoadColorProperties",
        AskNameBeforePaletteCreation = "AskNameBeforePaletteCreation",
        AutoCheckForUpdate = "AutoCheckForUpdate",
        AutoSave = "AutoSave",
        AutoSaveInterval = "AutoSaveInterval",
        CacheAPIData = "CacheAPIData",
        UserGradients = "UserGradients",
        FirstTimeSetup = "FirstTimeSetup",
        
        -- DEPRECATED
        UserColorSequences = "UserColorSequences",
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