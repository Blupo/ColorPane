local widgetsInfo = {
	ColorEditor = {
		Id = "ColorPane_Editor",
		Title = "ColorPane Editor",
		Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 592, 400, 327, 400),
	},

	ColorSequenceEditor = {
		Id = "ColorPane_CS_Editor",
		Title = "ColorPane ColorSequence Editor",
	    Info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 592, 130, 592, 130),
	},
}

return function(plugin, widgetInfoName)
	local widgetInfo = widgetsInfo[widgetInfoName]

	local widget = plugin:CreateDockWidgetPluginGui(widgetInfo.Id, widgetInfo.Info)
	widget.Name = widgetInfo.Id
	widget.Title = widgetInfo.Title
	widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	widget.Archivable = false

	return widget
end