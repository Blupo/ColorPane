--!strict

local RunService: RunService = game:GetService("RunService")

---

local PluginModules = script.Parent
local PluginProvider = require(PluginModules.PluginProvider)
local Style = require(PluginModules.Style)
local Translator = require(PluginModules.Translator)
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

local firstTimeSetupMinWidth = 84 +
    (Style.Constants.PagePadding * 2) +
    Style.Constants.SpaciousElementPadding +
    Style.Constants.StandardButtonHeight

local widgetsInfo = {
    ColorEditor = {
        Id = "ColorPane_ColorEditor",
        Title = "",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, colorEditorDefaultWidth, 400, colorEditorMinWidth, 400),
    },

    GradientEditor = {
        Id = "ColorPane_GradientEditor",
        Title = "",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, gradientEditorMinWidth, 130, gradientEditorMinWidth, 130),
    },

    ColorProperties = {
        Id = "ColorPane_ColorProperties",
        Title = Translator.FormatByKey("ColorProperties_WindowTitle"),
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, Style.Constants.EditorPageWidth, 400, Style.Constants.EditorPageWidth, 200)
    },

    Settings = {
        Id = "ColorPane_Settings",
        Title = Translator.FormatByKey("Settings_WindowTitle"),
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, Style.Constants.EditorPageWidth, 200, Style.Constants.EditorPageWidth, 200),
    },

    GradientPalette = {
        Id = "ColorPane_GradientPalette",
        Title = "",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, Style.Constants.PagePadding + 230, gradientPaletteMinHeight, Style.Constants.PagePadding + 230, gradientPaletteMinHeight),
    },

    GradientInfo = {
        Id = "ColorPane_GradientInfo",
        Title = "",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, Style.Constants.PagePadding + 230, gradientInfoMinHeight, Style.Constants.PagePadding + 230, gradientInfoMinHeight),
    },

    FirstTimeSetup = {
        Id = "ColorPane_FirstTimeSetup",
        Title = "",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 300, firstTimeSetupMinWidth, 300, firstTimeSetupMinWidth),
    },
}

---

return function(widgetInfoName: string): DockWidgetPluginGui
    if (widgets[widgetInfoName]) then return widgets[widgetInfoName] end

    local widgetInfo = widgetsInfo[widgetInfoName]
    local widget: DockWidgetPluginGui = plugin:CreateDockWidgetPluginGui(widgetInfo.Id, widgetInfo.Info)

    widget.Name = widgetInfo.Id
    widget.Title = widgetInfo.Title
    widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    widget.Archivable = false

    -- fix a bug where PluginGuis don't show up when you enable them
    if (widgetInfoName ~= "ColorProperties") then
        RunService.Heartbeat:Wait()
        widget.Enabled = true
        RunService.Heartbeat:Wait()
        RunService.Heartbeat:Wait()
        widget.Enabled = false
    end

    widgets[widgetInfoName] = widget
    return widget
end