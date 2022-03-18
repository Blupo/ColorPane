local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Style = require(PluginModules:FindFirstChild("Style"))

---

local widgetsInfo = {
    ColorEditor = {
        Id = "ColorPane_Editor",
        Title = "ColorPane Color Editor",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true,
            Style.PagePadding + ((Style.EditorPageWidth + Style.MajorElementPadding) * 2) + Style.LargeButtonSize + 2 + Style.PagePadding, 400,
            Style.PagePadding + Style.EditorPageWidth + Style.MajorElementPadding + Style.LargeButtonSize + 2 + Style.PagePadding, 400
        ),
    },

    GradientEditor = {
        Id = "ColorPane_Gradient_Editor",
        Title = "ColorPane ColorSequence Editor",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true,
            Style.PagePadding + ((Style.EditorPageWidth + Style.MajorElementPadding) * 2) + Style.LargeButtonSize + 2 + Style.PagePadding, 130,
            Style.PagePadding + ((Style.EditorPageWidth + Style.MajorElementPadding) * 2) + Style.LargeButtonSize + 2 + Style.PagePadding, 130
        ),
    },

    ColorProperties = {
        Id = "ColorPane_Properties",
        Title = "ColorPane Color Properties",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, Style.EditorPageWidth, 400, Style.EditorPageWidth, 200)
    },

    Settings = {
        Id = "ColorPane_Settings",
        Title = "ColorPane Settings",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, Style.EditorPageWidth, 200, Style.EditorPageWidth, 200),
    },

    GradientPalette = {
        Id = "ColorPane_Gradient_Palette",
        Title = "ColorPane Gradient Palette",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true,
            Style.PagePadding + 230, (Style.PagePadding * 2) + Style.StandardInputHeight + Style.MinorElementPadding + (((Style.StandardButtonSize * 1) + (Style.MinorElementPadding * 2)) * 6) + 2,
            Style.PagePadding + 230, (Style.PagePadding * 2) + Style.StandardInputHeight + Style.MinorElementPadding + (((Style.StandardButtonSize * 1) + (Style.MinorElementPadding * 2)) * 6) + 2
        ),
    },

    GradientInfo = {
        Id = "ColorPane_Gradient_Info",
        Title = "ColorPane Gradient Info",
        Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true,
            Style.PagePadding + 230, (Style.PagePadding * 2) + (Style.StandardTextSize * 3) + (Style.StandardButtonSize * 5) + Style.StandardInputHeight + (Style.MinorElementPadding * 6) + (Style.SpaciousElementPadding * 2),
            Style.PagePadding + 230, (Style.PagePadding * 2) + (Style.StandardTextSize * 3) + (Style.StandardButtonSize * 5) + Style.StandardInputHeight + (Style.MinorElementPadding * 6) + (Style.SpaciousElementPadding * 2)
        ),
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