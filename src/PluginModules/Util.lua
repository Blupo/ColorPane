--!strict

local root = script.Parent.Parent

local includes = root:FindFirstChild("includes")
local ColorLib = require(includes:FindFirstChild("Color"))
local state = require(includes:FindFirstChild("state"))
local t = require(includes:FindFirstChild("t"))

local Color = ColorLib.Color

---

type Color = ColorLib.Color
type GradientKeypoint = ColorLib.GradientKeypoint

local paletteTypeCheck = t.strictInterface({
    name = t.string,

    colors = t.array(t.strictInterface({
        name = t.string,
        
        color = t.strictInterface({
            [1] = t.numberConstrained(0, 1),
            [2] = t.numberConstrained(0, 1),
            [3] = t.numberConstrained(0, 1),
        })
    }))
})

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
Util.palette = {}

--- TABLE UTIL

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

Util.table.numKeys = function(tbl: {[any]: any}): number
    local n: number = 0

    for _ in state.iter.pairs(tbl) do
        n = n + 1
    end

    return n
end

Util.table.merge = function(tbl: {[any]: any}, slice: {[any]: any}): {[any]: any}
    if (Util.table.numKeys(slice) < 1) then return tbl end

    for key, newValue in state.iter.pairs(slice) do
        local value: any

        if (newValue ~= nil) then
            value = newValue
        else
            value = tbl[key]
        end

        tbl[key] = value
    end

    return tbl
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

--- PALETTE UTIL

Util.palette.getNewItemName = function(items, originalName: string, selfIndex: number?): (string, number)
    local found: boolean = false
    local numDuplicates: number = 0
    local itemName: string = originalName

    repeat
        found = false

        for i, item in state.iter.ipairs(items) do
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

Util.palette.validate = function(palette: any)
    -- type check
    local typeCheckSuccess, message = paletteTypeCheck(palette)
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

--- GENERAL UTIL

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

---

return Util