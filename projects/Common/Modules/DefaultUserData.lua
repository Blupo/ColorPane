--!strict
-- Provides the default user data for ColorPane instances

local Modules = script.Parent
local Types = require(Modules.Types)

---

return {
    SnapValue = 0.001,
    UserColorPalettes = {},
    UserGradientPalettes = {},
    AskNameBeforePaletteCreation = true,
    AutoLoadColorPropertiesAPIData = false,
    CacheColorPropertiesAPIData = false,
}::Types.UserData