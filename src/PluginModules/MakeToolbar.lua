local PluginModules = script.Parent
local Style = require(PluginModules:FindFirstChild("Style"))

return function(plugin)
    local toolbar = plugin:CreateToolbar("ColorPane")
    local editorButton = toolbar:CreateButton("ColorPane_OpenEditor", "Open the color editor", "", "Editor")

    return {
        Toolbar = toolbar,
        ColorEditorButton = editorButton,
    }
end