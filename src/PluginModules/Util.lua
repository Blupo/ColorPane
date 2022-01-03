--!strict

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
        copy[(type(k) == "table") and Util.table.deepCopy(k) or k] = (type(v) == "table") and Util.table.deepCopy(v) or v
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
        t[key] = newValue or t[key]
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

Util.noYield = function(callback: (...any) -> any, ...: any)
    local routine = coroutine.create(callback)
    
    return noYieldReturnHandler(routine, coroutine.resume(routine, ...))
end

Util.escapeText = function(s: string): string
    return (string.gsub(s, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%0"))
end

return Util