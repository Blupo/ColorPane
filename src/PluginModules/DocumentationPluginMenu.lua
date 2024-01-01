--!strict

local PluginModules = script.Parent
local PluginProvider = require(PluginModules.PluginProvider)
local Util = require(PluginModules.Util)

---

local plugin: Plugin? = PluginProvider()
assert(plugin, Util.makeBugMessage("Plugin object is missing"))

local pluginMenu: PluginMenu = plugin:CreatePluginMenu("ColorPane", "ColorPane")
local action: PluginAction = pluginMenu:AddNewAction("ColorProperties_ShowDocumentation", "Show Documentation")

---

local DocumentationPluginMenu = {}

DocumentationPluginMenu.Menu = pluginMenu
DocumentationPluginMenu.Action = action

DocumentationPluginMenu.ShowPropertyDocumentation = function(className: string, propertyName: string)
    plugin:OpenWikiPage("api-reference/property/" .. className .. "/" .. propertyName)
end

return DocumentationPluginMenu