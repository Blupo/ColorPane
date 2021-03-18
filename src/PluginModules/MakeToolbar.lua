local PluginModules = script.Parent
local Style = require(PluginModules:FindFirstChild("Style"))

local toolbarComponents

---

return function(plugin)
    if (toolbarComponents) then return toolbarComponents end

    local toolbar = plugin:CreateToolbar("ColorPane")
    local editorButton = toolbar:CreateButton("ColorPane_OpenEditor", "Open the Color Editor", Style.ToolbarColorEditorButtonImage, "Color Editor")
    local propertiesButton = toolbar:CreateButton("ColorPane_Properties", "Open the Color Properties window", Style.ToolbarColorPropertiesButtonImage, "Color Properties")
    local loadButton = toolbar:CreateButton("ColorPane_LoadAPI", "Load the API script (requires script injection)", Style.ToolbarLoadAPIButtonImage, "Load API")
    local settingsButton = toolbar:CreateButton("ColorPane_Settings", "Open the Settings window", Style.ToolbarSettingsButtonImage, "Settings")

    toolbarComponents = {
        Toolbar = toolbar,
        ColorEditorButton = editorButton,
        ColorPropertiesButton = propertiesButton,
        LoadAPIButton = loadButton,
        SettingsButton = settingsButton,
    }

    return toolbarComponents
end