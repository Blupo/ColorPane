local PluginModules = script.Parent
local Style = require(PluginModules:FindFirstChild("Style"))

local toolbarComponents

---

return function(plugin)
    if (toolbarComponents) then return toolbarComponents end

    local toolbar = plugin:CreateToolbar("ColorPane")
    local colorEditorButton = toolbar:CreateButton("ColorPane_ColorEditor", "Open the Color Editor", Style.Images.ColorEditorToolbarButtonIcon, "Color Editor")
    local csEditorButton = toolbar:CreateButton("ColorPane_CSEditor", "Open the Gradient Editor", Style.Images.GradientEditorToolbarButtonIcon, "Gradient Editor")
    local propertiesButton = toolbar:CreateButton("ColorPane_Properties", "Open Color Properties", Style.Images.ColorPropertiesToolbarButtonIcon, "Color Properties")
    local settingsButton = toolbar:CreateButton("ColorPane_Settings", "Open Settings", Style.Images.SettingsToolbarButtonIcon, "Settings")

    toolbarComponents = {
        Toolbar = toolbar,
        ColorEditorButton = colorEditorButton,
        ColorPropertiesButton = propertiesButton,
        SettingsButton = settingsButton,
        ColorSequenceEditorButton = csEditorButton,
    }

    return toolbarComponents
end