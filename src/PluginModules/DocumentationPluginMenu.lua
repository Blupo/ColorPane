local savedPlugin

---

local DocumentationPluginMenu = {}

DocumentationPluginMenu.init = function(plugin)
    DocumentationPluginMenu.init = nil

    local pluginMenu = plugin:CreatePluginMenu("ColorPane", "ColorPane")
    local action = pluginMenu:AddNewAction("ColorProperties_ShowDocumentation", "Show Documentation")

    DocumentationPluginMenu.Menu = pluginMenu
    DocumentationPluginMenu.Action = action

    plugin.Unloading:Connect(function()
        DocumentationPluginMenu.Menu = nil
        DocumentationPluginMenu.Action = nil

        savedPlugin = nil
    end)

    savedPlugin = plugin
end

DocumentationPluginMenu.ShowPropertyDocumentation = function(className: string, propertyName: string)
    if (not savedPlugin) then return end

    savedPlugin:OpenWikiPage("api-reference/property/" .. className .. "/" .. propertyName)
end

---

return DocumentationPluginMenu