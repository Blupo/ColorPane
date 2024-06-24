--!strict

local root = script.Parent.Parent
local Includes = root.Includes
local t = require(Includes.t)

---

--[[
    Type validator for the upstream user data provider's
    physical interface to ColorPane instances.

    @param value The value to check
    @return If the value is a valid interface
    @return An error message if the value was not valid
]]
return function(value: any): (boolean, string?)
    local success: boolean, failReason: string? = t.instanceOf("Folder", {
        GetVersion = t.instanceOf("BindableFunction"),
        GetValue = t.instanceOf("BindableFunction"),
        GetAllValues = t.instanceOf("BindableFunction"),
        SetValue = t.instanceOf("BindableFunction"),
        
        ValueChanged = t.instanceOf("BindableEvent"),
    })(value)

    if (not success) then
        return success, failReason
    end

    local correctName: boolean = (value.Name == "ColorPaneUserData")

    if (not correctName) then
        return false, "Incorrect interface name"
    else
        return true
    end
end