--!strict

local root = script.Parent.Parent
local includes = root:FindFirstChild("includes")

local ColorLib = require(includes:FindFirstChild("Color"))
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

Util.table.deepCopy = function(t: {[any]: any}): {[any]: any}
    local copy: {[any]: any} = {}

    for k, v in pairs(t) do
        local newK = (type(k) == "table") and Util.table.deepCopy(k) or k
        local newV = (type(v) == "table") and Util.table.deepCopy(v) or v

        copy[newK] = newV
    end

    return copy
end

Util.table.deepCopyPreserveColors = function(t: {[any]: any}): {[any]: any}
    local copy: {[any]: any} = {}

    for k, v in pairs(t) do
        local newK = (type(k) == "table") and Util.table.deepCopyPreserveColors(k) or k
        local newV

        if ((type(v) == "table") and (not Color.isAColor(v))) then
            newV = Util.table.deepCopyPreserveColors(v)
        else
            newV = v
        end

        copy[newK] = newV
    end

    return copy
end

Util.table.numKeys = function(t: {[any]: any}): number
    local n: number = 0

    for _ in pairs(t) do
        n = n + 1
    end

    return n
end

Util.table.merge = function(t: {[any]: any}, slice: {[any]: any}): {[any]: any}
    if (Util.table.numKeys(slice) < 1) then return t end

    for key, newValue in pairs(slice) do
        local value

        if (newValue ~= nil) then
            value = newValue
        else
            value = t[key]
        end

        t[key] = value
    end

    return t
end

Util.table.shallowCompare = function(t: {[any]: any}, u: {[any]: any}): {string}
    local diff = {}

    for k, v in pairs(t) do
        if (u[k] ~= v) then
            table.insert(diff, k)
        end
    end

    for k, v in pairs(u) do
        if ((not table.find(diff, k)) and (t[k] ~= v)) then
            table.insert(diff, k)
        end
    end

    return diff
end

Util.lerp = function(a: number, b: number, t: number): number
    return ((1 - t) * a) + (t * b)
end

Util.inverseLerp = function(a: number, b: number, v: number): number
    return (v - a) / (b - a)
end

Util.round = function(n: number, optionalE: number?): number
    local e: number = optionalE or 0

    return math.floor((n / 10^e) + 0.5) * 10^e
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
            local t: number = (j + 1) / (precision + 2)

            local newKeypointTime: number = Util.lerp(thisKeypoint.Time, nextKeypoint.Time, t)
            local newKeypointColor: Color = thisKeypoint.Color:mix(nextKeypoint.Color, t, colorSpace, hueAdjustment)

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