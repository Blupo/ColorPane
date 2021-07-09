local PluginModules = script.Parent
local Style = require(PluginModules:FindFirstChild("Style"))

local toolbarComponents

---

return function(plugin)
    if (toolbarComponents) then return toolbarComponents end

    local toolbar = plugin:CreateToolbar("ColorPane")
    local colorEditorButton = toolbar:CreateButton("ColorPane_ColorEditor", "Open the Color Editor", Style.ToolbarColorEditorButtonImage, "Color Editor")
    local csEditorButton = toolbar:CreateButton("ColorPane_CSEditor", "Open the Gradient Editor", Style.ToolbarGradientEditorButtonImage, "Gradient Editor")
    local propertiesButton = toolbar:CreateButton("ColorPane_Properties", "Open Color Properties", Style.ToolbarColorPropertiesButtonImage, "Color Properties")
    local injectAPIButton = toolbar:CreateButton("ColorPane_InjectAPI", "Inject the ColorPane API script", Style.ToolbarInjectAPIButtonImage, "Inject API")
    local settingsButton = toolbar:CreateButton("ColorPane_Settings", "Open Settings", Style.ToolbarSettingsButtonImage, "Settings")

    toolbarComponents = {
        Toolbar = toolbar,
        ColorEditorButton = colorEditorButton,
        ColorPropertiesButton = propertiesButton,
        InjectAPIButton = injectAPIButton,
        SettingsButton = settingsButton,
        ColorSequenceEditorButton = csEditorButton,
    }

    return toolbarComponents
end