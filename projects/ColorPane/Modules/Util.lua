--!strict

local root = script.Parent.Parent
local Common = root.Common

local CommonIncludes = Common.Includes
local ColorLib = require(CommonIncludes.Color)

local CommonModules = Common.Modules
local CommonUtil = require(CommonModules.Util)
local ColorPaneUserDataValidators = require(CommonModules.ColorPaneUserDataValidators)

local Color = ColorLib.Color

---

type Color = ColorLib.Color
type GradientKeypoint = ColorLib.GradientKeypoint

local noYieldReturnHandler = function(routine: thread, success: boolean, ...: any)
    if (not success) then
        error(debug.traceback(routine, (...)))
    end

    if (coroutine.status(routine) ~= "dead") then
        error(debug.traceback("callback must not yield"))
    end

    return ...
end

---

--[[
    Utility functions
]]
local Util = {}

--[[
    Table utilities
]]
Util.table = {}
Util.table.deepCopy = CommonUtil.table.deepCopy

--[[
    Freezes a table and its sub-tables.
    Does not freeze metatables.

    @param t The table to deep-freeze
    @return `t` itself
]]
Util.table.deepFreeze = function(tbl: {[any]: any}): {[any]: any}
    for _, v in pairs(tbl) do
        if ((type(v) == "table") and (not table.isfrozen(v))) then
            Util.table.deepFreeze(v)
        end
    end

    table.freeze(tbl)
    return tbl
end

--[[
    Compares two tables and returns a list of keys with different values.

    @param this The table to be compared to
    @param that The table to compare
    @return A list of keys that have different values between the two tables
]]
Util.table.shallowCompare = function(this: {[any]: any}, that: {[any]: any}): {any}
    local diff = {}

    for k, v in pairs(this) do
        if (that[k] ~= v) then
            table.insert(diff, k)
        end
    end

    for k, v in pairs(that) do
        if ((not table.find(diff, k)) and (this[k] ~= v)) then
            table.insert(diff, k)
        end
    end

    return diff
end

--[[
    Palette utilities
]]
Util.palette = {}

Util.palette.getNewItemName = function(items: {[any]: any}, originalName: string, selfIndex: number?): (string, number)
    local found: boolean = false
    local numDuplicates: number = 0
    local itemName: string = originalName

    repeat
        found = false

        for i, item in ipairs(items) do
            if ((item.name == itemName) and (i ~= selfIndex)) then
                found = true
                numDuplicates = numDuplicates + 1
                itemName = originalName .. " (" .. numDuplicates .. ")"

                break
            end
        end
    until (not found)

    return itemName, numDuplicates
end

Util.palette.validate = function(palette: any): (boolean, string?)
    -- type check
    local typeCheckSuccess, message = ColorPaneUserDataValidators._colorPalette(palette)
    if (not typeCheckSuccess) then return false, message end

    -- check for "blank" name
    local substitutedPaletteName = string.gsub(palette.name, "%s+", "")
    if (string.len(substitutedPaletteName) < 1) then return false, "palette name is blank" end

    -- check for colors with the same or "blank" names
    local colorNameMap = {}

    for i = 1, #palette.colors do
        local color = palette.colors[i]
        local name = color.name

        local substitutedName = string.gsub(name, "%s+", "")
        if (string.len(substitutedName) < 1) then return false, "color name is blank" end

        if (colorNameMap[name]) then
            return false, "duplicate color name"
        else
            colorNameMap[name] = true
        end
    end

    return true, nil
end

-- GENERAL UTIL

Util.lerp = function(a: number, b: number, time: number): number
    return ((1 - time) * a) + (time * b)
end

Util.inverseLerp = function(a: number, b: number, v: number): number
    return (v - a) / (b - a)
end

Util.round = function(n: number, e: number?): number
    local p: number = 10^(e or 0)

    if (p >= 0) then
        return math.floor((n / p) + 0.5) * p
    else
        return math.floor((n * p) + 0.5) / p
    end
end

Util.noYield = function(callback: (...any) -> any, ...: any)
    local routine = coroutine.create(callback)
    
    return noYieldReturnHandler(routine, coroutine.resume(routine, ...))
end

Util.escapeText = function(s: string): string
    return (string.gsub(s, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%0"))
end

Util.makeBugMessage = function(msg: string): string
    return "[ColorPane] Error: " .. msg .. "\nThis is a bug. If you're seeing this, please submit a bug report."
end

-- GRADIENT UTIL

Util.getMaxUserKeypoints = function(maxKeypoints: number, precision: number): number
    return math.floor(((maxKeypoints - 1) / (precision + 1)) + 1)
end

Util.getUtilisedKeypoints = CommonUtil.gradient.getUtilisedKeypoints

Util.generateFullKeypointList = function(keypoints: {GradientKeypoint}, colorSpace: ColorLib.MixableColorType?, hueAdjustment: ColorLib.HueAdjustment?, precision: number): {GradientKeypoint}
    local fullKeypoints: {GradientKeypoint} = {}

    for i = 1, (#keypoints - 1) do
        local thisKeypoint: GradientKeypoint = keypoints[i]
        local nextKeypoint: GradientKeypoint = keypoints[i + 1]

        table.insert(fullKeypoints, thisKeypoint)

        for j = 1, precision do
            local time: number = (j + 1) / (precision + 2)

            local newKeypointTime: number = Util.lerp(thisKeypoint.Time, nextKeypoint.Time, time)
            local newKeypointColor: Color = thisKeypoint.Color:mix(nextKeypoint.Color, time, colorSpace, hueAdjustment)

            table.insert(fullKeypoints, {
                Time = newKeypointTime,
                Color = newKeypointColor
            })
        end
    end

    table.insert(fullKeypoints, keypoints[#keypoints])
    return fullKeypoints
end

-- converts a palette's colors into the specified type
Util.typeColorPalette = function(palette, colorType: string)
    local paletteCopy = Util.table.deepCopy(palette)
    local colors = paletteCopy.colors

    for i = 1, #colors do
        local color = colors[i]
        local colorValue = color.color

        if (colorType == "Color3") then
            color.color = Color3.fromRGB(colorValue[1], colorValue[2], colorValue[3])
        elseif (colorType == "Color") then
            color.color = Color.fromRGB(colorValue[1], colorValue[2], colorValue[3])
        end
    end

    return paletteCopy
end

---

return Util