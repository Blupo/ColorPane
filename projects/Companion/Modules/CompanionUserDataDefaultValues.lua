--!strict
--[[
    Provides the default user data values for Companion user data.
]]

local Modules = script.Parent
local Types = require(Modules.Types)

---

return {
    AutoLoadColorPropertiesAPIData = false,
    CacheColorPropertiesAPIData = false,
    RobloxApiDump = nil,
    RobloxApiDumpLastUpdated = nil,
}::Types.CompanionUserData