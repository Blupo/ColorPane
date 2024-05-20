--!strict

--[[
    Utility functions
]]
local Util = {}

--[[
    Table utilities
]]
Util.table = {}

--[[
    Freezes a table and its sub-tables.
    Does not freeze metatables.

    @param t The table to deep-freeze
    @return `t` itself
]]
Util.table.deepFreeze = function(t: {[any]: any}): {[any]: any}
    for _, v in pairs(t) do
        if ((type(v) == "table") and (not table.isfrozen(v))) then
            Util.table.deepFreeze(v)
        end
    end

    table.freeze(t)
    return t
end

--[[
    Creates a copy of a table with sub-tables also being copied.

    If a sub-table has a metatable, it will not be copied.
    If the root table has a metatable, an error will occur.

    @param t The table to deep-copy
    @return A deep-copy of `t`
]]
Util.table.deepCopy = function(t: {[any]: any}): {[any]: any}
    if (getmetatable(t::any) ~= nil) then
        error("Cannot copy table with metatable!")
    end

    local copy: {[any]: any} = {}

    for k: any, v: any in pairs(t) do
        if (type(v) ~= "table") then
            copy[k] = v
        else
            if (getmetatable(v) == nil) then
                copy[k] = Util.table.deepCopy(v)
            else
                copy[k] = v
            end
        end
    end

    return copy
end

--[[
    Gradient utilities
]]
Util.gradient = {}

--[[
    Returns the number of generated keypoints for a
    given number of keypoints and precision.

    @param keypoints The number of actual keypoints
    @param precision The number of generated keypoints between each actual keypoint
]]
Util.gradient.getUtilisedKeypoints = function(keypoints: number, precision: number): number
    return (precision * (keypoints - 1)) + keypoints
end

---

return Util