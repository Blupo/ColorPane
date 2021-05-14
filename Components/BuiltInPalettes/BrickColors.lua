local brickColorsPalette = {
    name = "BrickColors",
    colors = {}
}

for i = 1, 1032 do
    local brickColor = BrickColor.new(i)

    -- BrickColors that don't exist default to #194
    if ((brickColor.Number ~= 194) or (i == 194)) then
        table.insert(brickColorsPalette.colors, {
            name = brickColor.Name,
            color = brickColor.Color
        })
    end
end

return brickColorsPalette