--!strict

local savedPlugin: Plugin? = nil

--[[
    Stores and/or provides a Plugin object.
    
    If called with a plugin, it will be stored for future use.
    If a plugin is already stored, the function will throw an error.

    If called without a plugin, it will return the currently-stored plugin.
    If a plugin is not stored, the function will throw an error.
    
    @param plugin The plugin to be stored
    @return The currently-stored plugin
]]
return function(plugin: Plugin?): Plugin
    if (not plugin) then
        assert(savedPlugin, "Plugin object is missing")
        return savedPlugin
    else
        if (savedPlugin) then
            error("Plugin already stored")
        end
    end
    
    savedPlugin = plugin
    return plugin
end