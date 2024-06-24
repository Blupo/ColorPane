--!strict

local root = script.Parent.Parent

local Modules = root.Modules
local ColorPaneUserDataDiffs = require(Modules.ColorPaneUserDataDiffs)
local ColorPaneUserDataValidators = require(Modules.ColorPaneUserDataValidators)
local Enums = require(Modules.Enums)
local UserData = require(Modules.UserData)

---

--[[
    Helper function for creating a ColorPane UserData object.
]]
return function(initialValues)
    return UserData.new(Enums.ColorPaneUserDataKey, ColorPaneUserDataValidators, {
        [Enums.ColorPaneUserDataKey.UserColorPalettes] = ColorPaneUserDataDiffs.ColorPalettesAreDifferent,
        [Enums.ColorPaneUserDataKey.UserGradientPalettes] = ColorPaneUserDataDiffs.GradientPalettesAreDifferent,
    }, initialValues)
end