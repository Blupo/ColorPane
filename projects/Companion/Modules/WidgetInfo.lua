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
    },

    ColorProperties = {
        Id = "CPCompanion_ColorProperties",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, Style.Constants.EditorPageWidth, 400, Style.Constants.EditorPageWidth, 200),
    },

    ImportSettings = {
        Id = "CPCompanion_SettingsImport",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 240, 260, 240, 260),
    },

    ExportSettings = {
        Id = "CPCompanion_SettingsExport",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 200, 100, 200, 100),
    },

    ConfirmImportSettingsPrompt = {
        Id = "CPCompanion_SettingsImportConfirm",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 220, 200, 200, 200),
    }
}