local root = script.Parent.Parent

local includes = root:FindFirstChild("includes")
local t = require(includes:FindFirstChild("t"))


---

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

local getNewItemName = function(items, originalName, selfIndex)
    local found = false
    local numDuplicates = 0
    local itemName = originalName

    repeat
        found = false

        for i = 1, #items do
            local item = items[i]

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

local validate = function(palette)
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

---

return {
    getNewPaletteName = getNewItemName,
    getNewPaletteColorName = getNewItemName,
    validate = validate,
}