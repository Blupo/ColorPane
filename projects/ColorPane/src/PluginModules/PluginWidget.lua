--!strict

local RunService: RunService = game:GetService("RunService")

---

local root = script.Parent.Parent
local Common = root.Common

local CommonPluginModules = Common.PluginModules
local PluginProvider = require(CommonPluginModules.PluginProvider)
local Style = require(CommonPluginModules.Style)

local PluginModules = script.Parent
local ProjectInfo = require(PluginModules.ProjectInfo)
local Util = require(PluginModules.Util)

---

local plugin: Plugin? = PluginProvider()
assert(plugin, Util.makeBugMessage("Plugin object is missing"))

local widgets: {[string]: DockWidgetPluginGui} = {}

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
    (Style.Constants.StandardButtonHeight * 5) +
    Style.Constants.StandardInputHeight +
    (Style.Constants.MinorElementPadding * 6) +
    (Style.Constants.SpaciousElementPadding * 2)

local widgetsInfo = {
    ColorEditor = {
        Title = "",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, colorEditorDefaultWidth, 400, colorEditorMinWidth, 400),
    },

    GradientEditor = {
        Title = "",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, gradientEditorMinWidth, 130, gradientEditorMinWidth, 130),
    },

    GradientPalette = {
        Title = "",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, Style.Constants.PagePadding + 230, gradientPaletteMinHeight, Style.Constants.PagePadding + 230, gradientPaletteMinHeight),
    },

    GradientInfo = {
        Title = "",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, Style.Constants.PagePadding + 230, gradientInfoMinHeight, Style.Constants.PagePadding + 230, gradientInfoMinHeight),
    },
}

---

type PluginWidgetType = "ColorEditor" | "GradientEditor" | "GradientPalette" | "GradientInfo"

return function(widgetInfoId: PluginWidgetType): DockWidgetPluginGui
    if (widgets[widgetInfoId]) then return widgets[widgetInfoId] end

    local widgetInfo = widgetsInfo[widgetInfoId]
    local widget: DockWidgetPluginGui = plugin:CreateDockWidgetPluginGui(widgetInfoId, widgetInfo.Info)

    widget.Name = ProjectInfo.Id .. "_" .. widgetInfoId
    widget.Title = widgetInfo.Title
    widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    widget.Archivable = false

    -- fix a bug where PluginGuis don't show up when you enable them
    RunService.Heartbeat:Wait()
    widget.Enabled = true
    RunService.Heartbeat:Wait()
    RunService.Heartbeat:Wait()
    widget.Enabled = false

    widgets[widgetInfoId] = widget
    return widget
end