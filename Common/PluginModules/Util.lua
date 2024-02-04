--!strict

local includes = script.Parent.Parent.includes
local ColorLib = require(includes.Color)

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

local Util = {}
Util.table = {}

-- TABLE UTIL

Util.table.deepFreeze = function(tbl: {[any]: any}): {[any]: any}
    for _, v in pairs(tbl) do
        if ((type(v) == "table") and (not table.isfrozen(v))) then
            Util.table.deepFreeze(v)
        end
    end

    table.freeze(tbl)
    return tbl
end

Util.table.deepCopy = function(tbl: {[any]: any}): {[any]: any}
    local copy: {[any]: any} = {}

    for k, v in pairs(tbl) do
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

Util.table.shallowCompare = function(tbl: {[any]: any}, u: {[any]: any}): {string}
    local diff = {}

    for k, v in pairs(tbl) do
        if (u[k] ~= v) then
            table.insert(diff, k)
        end
    end

    for k, v in pairs(u) do
        if ((not table.find(diff, k)) and (tbl[k] ~= v)) then
            table.insert(diff, k)
        end
    end

    return diff
end

-- GENERAL UTIL

Util.lerp = function(a: number, b: number, time: number): number
    return ((1 - time) * a) + (time * b)
end

Util.inverseLerp = function(a: number, b: number, v: number): number
    return (v - a) / (b - a)
end

Util.round = function(n: number, optionalE: number?): number
    local e: number = optionalE or 0
    local p: number = 10^e

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

Util.getUtilisedKeypoints = function(keypoints: number, precision: number): number
    return (precision * (keypoints - 1)) + keypoints
end

Util.generateFullKeypointList = function(keypoints: {GradientKeypoint}, colorSpace: string?, hueAdjustment: string?, precision: number): {GradientKeypoint}
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

-- DEEP FREEZE

for _, tab in pairs(Util) do
    if (type(tab) == "table") then
        table.freeze(tab)
    end
end

table.freeze(Util)

---

return Util