--!strict
-- Provides access to the plugin object throughout the project

local savedPlugin: Plugin?

return function(plugin: Plugin?): Plugin?
    if (not plugin) then return savedPlugin end
    
    savedPlugin = plugin
    return plugin
end