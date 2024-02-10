--!strict
-- Provides access to the plugin object throughout the project

local savedPlugin: Plugin?

--[[
    Provides a Plugin object or stores a Plugin object
    @param plugin The plugin to be stored. If this is `nil`, the currently-stored Plugin will be returned instead (which may be nil)
    @return The currently-stored Plugin (which may be nil)
]]
return function(plugin: Plugin?): Plugin?
    if (not plugin) then return savedPlugin end
    
    savedPlugin = plugin
    return plugin
end