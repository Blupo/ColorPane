local PluginModules = script.Parent
local PluginProvider = require(PluginModules.PluginProvider)
local Style = require(PluginModules.Style)
local Translator = require(PluginModules.Translator)
local Util = require(PluginModules.Util)

---

local plugin: Plugin? = PluginProvider()
assert(plugin, Util.makeBugMessage("Plugin object is missing"))

---

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

---

local Toolbar = {
    Toolbar = toolbar,
    ColorEditorButton = colorEditorButton,
    ColorPropertiesButton = propertiesButton,
    SettingsButton = settingsButton,
    ColorSequenceEditorButton = csEditorButton,
}

return Toolbar