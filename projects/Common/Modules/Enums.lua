--!strict
-- Cross-project enums

return {
    UserDataKey = {
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