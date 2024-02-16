--!strict
-- ColorPane entry point

local PluginProvider = require(script.Common.PluginModules.PluginProvider)
local ProjectId = require(script.PluginModules.ProjectId)

---

--[[
    Initialises ColorPane and returns the API. **This function should only be called once.**
    
    The project ID is used when creating plugin widgets and in error output.
    If you do not provide an ID, it will be set to a random UUID.
    @param plugin The Plugin object of your project
    @param id (Optional) The ID of your project
    @return The ColorPane API
]]
return function(plugin: Plugin, id: string?)
    PluginProvider(plugin)
    
    if (id) then
        ProjectId(id)
    end

    return require(script.API)
end