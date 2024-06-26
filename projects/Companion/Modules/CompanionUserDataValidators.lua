--!strict
--[[
    Defines the set of validators for Companion user data values.
]]

local root = script.Parent.Parent

local Common = root.Common
local CommonIncludes = Common.Includes
local t = require(CommonIncludes.t)

local Modules = root.Modules
local Enums = require(Modules.Enums)

---

return {
    --[[
        Checks if a value is valid for the AutoLoadColorPropertiesAPIData value.

        @param value The value to check
        @return If the value is valid
        @return An error message, if the value was invalid
    ]]
    [Enums.CompanionUserDataKey.AutoLoadColorPropertiesAPIData] = t.boolean,

    --[[
        Checks if a value is valid for the CacheColorPropertiesAPIData value.

        @param value The value to check
        @return If the value is valid
        @return An error message, if the value was invalid
    ]]
    [Enums.CompanionUserDataKey.CacheColorPropertiesAPIData] = t.boolean,

    --[[
        Checks if a value is valid for the RobloxApiDump value.

        @param value The value to check
        @return If the value is valid
        @return An error message, if the value was invalid
    ]]
    [Enums.CompanionUserDataKey.RobloxApiDump] = t.optional(t.table),

    --[[
        Checks if a value is valid for the RobloxApiDumpLastUpdated value.

        @param value The value to check
        @return If the value is valid
        @return An error message, if the value was invalid
    ]]
    [Enums.CompanionUserDataKey.RobloxApiDumpLastUpdated] = t.optional(t.integer),
}
