local PluginModules = script.Parent
local Style = require(PluginModules:FindFirstChild("Style"))
local Translator = require(PluginModules:FindFirstChild("Translator"))

local toolbarComponents

---

return function(plugin)
    if (toolbarComponents) then return toolbarComponents end

    local toolbar = plugin:CreateToolbar("ColorPane")

    local colorEditorButton = toolbar:CreateButton(
        "ColorPane_ColorEditor",
        Translator.FormatByKey("ColorEditor_ToolbarButtonHintText"),
        Style.Images.ColorEditorToolbarButtonIcon,
        Translator.FormatByKey("ColorEditor_ToolbarButtonText")
    )

    local csEditorButton = toolbar:CreateButton(
        "ColorPane_CSEditor",
        Translator.FormatByKey("GradientEditor_ToolbarButtonHintText"),
        Style.Images.GradientEditorToolbarButtonIcon,
        Translator.FormatByKey("GradientEditor_ToolbarButtonText")
    )

    local propertiesButton = toolbar:CreateButton(
        "ColorPane_Properties",
        Translator.FormatByKey("ColorProperties_ToolbarButtonHintText"),
        Style.Images.ColorPropertiesToolbarButtonIcon,
        Translator.FormatByKey("ColorProperties_ToolbarButtonText")
    )

    local settingsButton = toolbar:CreateButton(
        "ColorPane_Settings",
        Translator.FormatByKey("Settings_ToolbarButtonHintText"),
        Style.Images.SettingsToolbarButtonIcon,
        Translator.FormatByKey("Settings_ToolbarButtonText")
    )

    toolbarComponents = {
        Toolbar = toolbar,
        ColorEditorButton = colorEditorButton,
        ColorPropertiesButton = propertiesButton,
        SettingsButton = settingsButton,
        ColorSequenceEditorButton = csEditorButton,
    }

    return toolbarComponents
end