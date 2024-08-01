--!strict

local root = script.Parent.Parent
local Common = root.Common
local CommonModules = Common.Modules
local PluginProvider = require(CommonModules.PluginProvider)

---

local plugin: Plugin = PluginProvider()
local pluginMenu = plugin:CreatePluginMenu("ColorPane", "ColorPane")
local showDocumentationPluginAction = pluginMenu:AddNewAction("ColorProperties_ShowDocumentation", "Show Documentation")

---

local DocumentationPluginMenu = {}
DocumentationPluginMenu.Menu = pluginMenu
DocumentationPluginMenu.Action = showDocumentationPluginAction

DocumentationPluginMenu.ShowPropertyDocumentation = function(className: string, propertyName: string)
    -- The URL that actually opens is developer.roblox.com (the old wiki)
    -- and not create.roblox.com/docs (the current wiki)
    -- For properties on the old wiki, the URL is
    --   developer.roblox/com/api-reference/property/CLASS_NAME/PROPERTY_NAME
    -- which will be properly redirected (for now)
    plugin:OpenWikiPage("api-reference/property/" .. className .. "/" .. propertyName)
end

---

return DocumentationPluginMenu