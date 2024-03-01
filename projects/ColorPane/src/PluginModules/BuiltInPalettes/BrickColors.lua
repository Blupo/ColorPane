-- A palette of the available brick colors

local brickColorsPalette = {
    name = "BrickColors",
    colors = {}
}

for i = 1, 1032 do
    local brickColor = BrickColor.new(i)

    -- BrickColors that don't exist default to #194
    if ((brickColor.Number ~= 194) or (i == 194)) then
        local color = brickColor.Color

        table.insert(brickColorsPalette.colors, {
            name = brickColor.Name,

            color = { color.R * 255, color.G * 255, color.B * 255 }
        })
    end
end

return brickColorsPalette