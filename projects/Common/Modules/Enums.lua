--!strict
--[[
    Enums used by more than one project.
]]

return {
    UserDataKey = {
        SnapValue = "SnapValue",
        UserColorPalettes = "UserColorPalettes",
        UserGradientPalettes = "UserGradientPalettes",
        AskNameBeforePaletteCreation = "AskNameBeforePaletteCreation",
        AutoLoadColorPropertiesAPIData = "AutoLoadColorPropertiesAPIData",
        CacheColorPropertiesAPIData = "CacheColorPropertiesAPIData",
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