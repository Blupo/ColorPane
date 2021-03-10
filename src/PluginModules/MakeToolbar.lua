local PluginModules = script.Parent
local Style = require(PluginModules:FindFirstChild("Style"))

local toolbarComponents

---

return function(plugin)
    if (toolbarComponents) then return toolbarComponents end

    local toolbar = plugin:CreateToolbar("ColorPane")
    local editorButton = toolbar:CreateButton("ColorPane_OpenEditor", "Open the Color Editor", Style.ToolbarColorEditorImage, "Color Editor")
    local reloadButton = toolbar:CreateButton("ColorPane_Reload", "Load the API script into the CoreGui if it could not be done automatically", Style.ToolbarRefreshButtonImage, "Reload API")

    toolbarComponents = {
        Toolbar = toolbar,
        ColorEditorButton = editorButton,
        ReloadButton = reloadButton,
    }

    return toolbarComponents
end