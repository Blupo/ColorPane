--!strict
--[[
    Holds information for plugin widgets.
]]

local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local Style = require(CommonModules.Style)

---

return {
    Settings = {
        Id = "CPCompanion_Settings",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, Style.Constants.EditorPageWidth, 200, Style.Constants.EditorPageWidth, 200),
    },

    RestoreDefaultsPrompt = {
        Id = "CPCompanion_RestoreDefaultsPrompt",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, true, 300, 120, 300, 120),
    }
}