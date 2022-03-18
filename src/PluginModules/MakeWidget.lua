local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Style = require(PluginModules:FindFirstChild("Style"))

---

local colorEditorDefaultWidth = Style.Constants.PagePadding +
    (Style.Constants.EditorPageWidth + Style.Constants.MajorElementPadding) * 2 +
    Style.Constants.LargeButtonHeight +
    2 +
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
---

local widgetsInfo = {
    ColorEditor = {
        Id = "ColorPane_Editor",
        Title = "ColorPane Color Editor",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, colorEditorDefaultWidth, 400, colorEditorMinWidth, 400),
    },

    GradientEditor = {
        Id = "ColorPane_Gradient_Editor",
        Title = "ColorPane ColorSequence Editor",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, gradientEditorMinWidth, 130, gradientEditorMinWidth, 130),
    },

    ColorProperties = {
        Id = "ColorPane_Properties",
        Title = "ColorPane Color Properties",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, Style.Constants.EditorPageWidth, 400, Style.Constants.EditorPageWidth, 200)
    },

    Settings = {
        Id = "ColorPane_Settings",
        Title = "ColorPane Settings",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, Style.Constants.EditorPageWidth, 200, Style.Constants.EditorPageWidth, 200),
    },

    GradientPalette = {
        Id = "ColorPane_Gradient_Palette",
        Title = "ColorPane Gradient Palette",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, Style.Constants.PagePadding + 230, gradientPaletteMinHeight, Style.Constants.PagePadding + 230, gradientPaletteMinHeight),
    },

    GradientInfo = {
        Id = "ColorPane_Gradient_Info",
        Title = "ColorPane Gradient Info",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, Style.Constants.PagePadding + 230, gradientInfoMinHeight, Style.Constants.PagePadding + 230, gradientInfoMinHeight),
    },

    FirstTimeSetup = {
        Id = "ColorPane_FirstTimeSetup",
        Title = "ColorPane First Time Setup",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 300, 150, 300, 150),
    },
}

local widgets = {}

return function(plugin, widgetInfoName)
    if (widgets[widgetInfoName]) then return widgets[widgetInfoName] end

    local widgetInfo = widgetsInfo[widgetInfoName]
    local widget = plugin:CreateDockWidgetPluginGui(widgetInfo.Id, widgetInfo.Info)

    widget.Name = widgetInfo.Id
    widget.Title = widgetInfo.Title
    widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    widget.Archivable = false

    widgets[widgetInfoName] = widget
    return widget
end