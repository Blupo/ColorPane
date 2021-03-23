local copy
copy = function(t)
    local tCopy = {}

    for k, v in pairs(t) do
        tCopy[(type(k) == "table") and copy(k) or k] = (type(v) == "table") and copy(v) or v
    end

    return tCopy
end

local dictionaryCount = function(t)
    local count = 0

    for _ in pairs(t) do
        count = count + 1
    end

    return count
end

local mergeTable = function(t, slice)
    if (dictionaryCount(slice) < 1) then return t end

    for key, newValue in pairs(slice) do
        t[key] = newValue or t[key]
    end

    return t
end

local shallowCompare = function(t1, t2)
    local diff = {}

    for k, v in pairs(t1) do
        if (t2[k] ~= v) then
            diff[#diff + 1] = k
        end
    end

    for k, v in pairs(t2) do
        if ((not table.find(diff, k)) and (t1[k] ~= v)) then
            diff[#diff + 1] = k
        end
    end

    return diff
end

local noYieldReturnHandler = function(routine, success, ...)
    if (not success) then
		error(debug.traceback(routine, (...)))
	end

	if (coroutine.status(routine) ~= "dead") then
		error(debug.traceback("OnColorChanged must not yield"))
	end

	return ...
end

local noYield = function(callback, ...)
    local routine = coroutine.create(callback)
    
    return noYieldReturnHandler(routine, coroutine.resume(routine, ...))
end

return {
    copy = copy,
    mergeTable = mergeTable,
    shallowCompare = shallowCompare,
    noYield = noYield,
}