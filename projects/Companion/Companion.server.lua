--!strict
-- TODO

local root = script.Parent

local Common = root.Common
local CommonModules = Common.Modules

local Modules = root.Modules

---

require(CommonModules.PluginProvider)(plugin)
require(Modules.ManagedUserData)
require(Modules.UserDataInterface)