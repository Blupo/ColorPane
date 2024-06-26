--!strict
--[[
    Provides access to the ColorPane API throughout the project.
]]

local root = script.Parent.Parent

local Common = root.Common
local CommonModules = Common.Modules
local PluginProvider = require(CommonModules.PluginProvider)

local Includes = root.Includes
local InitColorPane = require(Includes.ColorPane)

---

local plugin: Plugin = PluginProvider()
local ColorPane = InitColorPane(plugin, "ColorPane_Companion")

---

return ColorPane