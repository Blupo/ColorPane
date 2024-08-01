--!strict
--[[
    Enums used by more than one project.
]]

return {
    ColorPaneUserDataKey = {
        SnapValue = "SnapValue",
        UserColorPalettes = "UserColorPalettes",
        UserGradientPalettes = "UserGradientPalettes",
        AskNameBeforePaletteCreation = "AskNameBeforePaletteCreation",
    },

    UserDataError = {
        InvalidKey = "InvalidKey",
        InvalidValue = "InvalidValue",
        ValidatorNotFound = "ValidatorNotFound",
        InvalidUserData = "InvalidUserData",
    },

    UpstreamUserDataProviderError = {
        Unavailable = "Unavailable",
    },
}