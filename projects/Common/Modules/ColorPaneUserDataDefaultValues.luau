--!strict
--[[
    Provides the default user data values for ColorPane user data.
]]

local Modules = script.Parent
local Types = require(Modules.Types)

---

return {
    SnapValue = 0.001,
    UserColorPalettes = {},
    UserGradientPalettes = {},
    AskNameBeforePaletteCreation = true,
}::Types.ColorPaneUserData