--!strict
--[[
    Companion store, required by Window.
    (Only keeps track of the theme.)
]]

local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local PluginProvider = require(CommonModules.PluginProvider)

local CommonIncludes = Common.Includes
local Rodux = require(CommonIncludes.RoactRodux.Rodux)

---

type table = {[any]: any}

local Studio: Studio = settings().Studio

local plugin: Plugin = PluginProvider()
local themeChanged: RBXScriptConnection

local Store = Rodux.Store.new(Rodux.createReducer({
    theme = Studio.Theme,
}, {
    SetTheme = function(_: table, action: table): table
        return {
            theme = action.theme,
        }
    end,
}))

---

themeChanged = Studio.ThemeChanged:Connect(function()
    Store:dispatch({
        type = "SetTheme",
        theme = Studio.Theme,
    })
end)

plugin.Unloading:Connect(function()
    themeChanged:Disconnect()
end)

return Store