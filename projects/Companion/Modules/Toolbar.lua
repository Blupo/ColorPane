--!strict
--[[
    Constructs the plugin toolbar and buttons.
]]

local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local PluginProvider = require(CommonModules.PluginProvider)
local Style = require(CommonModules.Style)
local Translator = require(CommonModules.Translator)

---

local plugin: Plugin = PluginProvider()
local toolbar: PluginToolbar = plugin:CreateToolbar("ColorPane Companion")

---

return {
    --[[
        The plugin toolbar.
    ]]
    Toolbar = toolbar,

    --[[
        Button for opening the color editor.
    ]]
    ColorEditButton = toolbar:CreateButton(
        "CPCompanion_ColorEditor",
        Translator.FormatByKey("ColorEditor_ToolbarButtonHintText"),
        Style.Images.ColorEditorToolbarButtonIcon,
        Translator.FormatByKey("ColorEditor_ToolbarButtonText")
    ),

    --[[
        Button for opening the gradient editor.
    ]]
    GradientEditButton = toolbar:CreateButton(
        "CPCompanion_CSEditor",
        Translator.FormatByKey("GradientEditor_ToolbarButtonHintText"),
        Style.Images.GradientEditorToolbarButtonIcon,
        Translator.FormatByKey("GradientEditor_ToolbarButtonText")
    ),

    --[[
        Button to configure certain settings.
    ]]
    SettingsButton = toolbar:CreateButton(
        "CPCompanion_Settings",
        Translator.FormatByKey("Settings_ToolbarButtonHintText"),
        Style.Images.SettingsToolbarButtonIcon,
        Translator.FormatByKey("Settings_ToolbarButtonText")
    ),
}