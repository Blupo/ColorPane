--!strict
-- Holds information for the common plugin widgets

local root = script.Parent.Parent
local Common = root.Common

local CommonPluginModules = Common.PluginModules
local Style = require(CommonPluginModules.Style)

local PluginModules = script.Parent
local ProjectId = require(PluginModules.ProjectId)

---

local PROJECT_ID: string = ProjectId()

local colorEditorDefaultWidth = Style.Constants.PagePadding +
    (Style.Constants.EditorPageWidth + Style.Constants.MajorElementPadding) * 2 +
    Style.Constants.LargeButtonHeight +
    4 +
    Style.Constants.PagePadding

local colorEditorMinWidth = Style.Constants.PagePadding +
    Style.Constants.EditorPageWidth +
    Style.Constants.MajorElementPadding +
    Style.Constants.LargeButtonHeight +
    2 +
    Style.Constants.PagePadding

local gradientEditorMinWidth = Style.Constants.PagePadding +
    (Style.Constants.EditorPageWidth + Style.Constants.MajorElementPadding) * 2 +
    Style.Constants.LargeButtonHeight +
    2 +
    Style.Constants.PagePadding

local gradientPaletteMinHeight = (Style.Constants.PagePadding * 2) +
    Style.Constants.StandardInputHeight +
    Style.Constants.MinorElementPadding +
    ((Style.Constants.StandardButtonHeight * 1) + (Style.Constants.MinorElementPadding * 2)) * 6 +
    2

local gradientInfoMinHeight = (Style.Constants.PagePadding * 2) +
    (Style.Constants.StandardTextSize * 3) +
    (Style.Constants.StandardButtonHeight * 6) +
    Style.Constants.StandardInputHeight +
    (Style.Constants.MinorElementPadding * 7) +
    (Style.Constants.SpaciousElementPadding * 2)

---

return {
    ColorEditor = {
        Id = PROJECT_ID .. "_ColorEditor",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, colorEditorDefaultWidth, 400, colorEditorMinWidth, 400),
    },

    GradientEditor = {
        Id = PROJECT_ID .. "_GradientEditor",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, gradientEditorMinWidth, 130, gradientEditorMinWidth, 130),
    },

    GradientPalette = {
        Id = PROJECT_ID .. "_GradientPalette",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, Style.Constants.PagePadding + 230, gradientPaletteMinHeight, Style.Constants.PagePadding + 230, gradientPaletteMinHeight),
    },

    GradientInfo = {
        Id = PROJECT_ID .. "_GradientInfo",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, Style.Constants.PagePadding + 230, gradientInfoMinHeight, Style.Constants.PagePadding + 230, gradientInfoMinHeight),
    },
}