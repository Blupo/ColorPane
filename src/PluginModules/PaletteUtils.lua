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

local getPalette = function(palettes, paletteName)
	for i = 1, #palettes do
		local palette = palettes[i]

		if (palette.name == paletteName) then
			return palette, i
		end
	end
end

local getPaletteColorIndex = function(paletteColors, colorName)
    for i = 1, #paletteColors do
        local color = paletteColors[i]

        if (color.name == colorName) then
            return i
        end
    end
end

---

return {
    getNewPaletteName = getNewItemName,
    getNewPaletteColorName = getNewItemName,
    getPalette = getPalette,
    getPaletteColorIndex = getPaletteColorIndex,
}