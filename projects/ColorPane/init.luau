--!strict
--[[
    v0.5.0

    ColorPane is a suite of color tools for Roblox Studio projects.
    Learn more here: https://devforum.roblox.com/t/1106112

    Please refer to the documentation for integrating these tools.
]]

local PluginProvider = require(script.Common.Modules.PluginProvider)
local ProjectId = require(script.Modules.ProjectId)
local Types = require(script.Modules.Types)

---

export type ColorPromptInfoArgument = Types.ColorPromptInfoArgument
export type GradientPromptInfoArgument = Types.GradientPromptInfoArgument

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