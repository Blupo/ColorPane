-- Equations: https://www.rapidtables.com/convert/color/rgb-to-cmyk.html

local CMYK = {}

CMYK.fromRGB = function(r, g, b)
    local c = 1 - r
    local m = 1 - g
    local y = 1 - b
    local k = math.min(c, m, y)

    c = (k < 1) and ((c - k) / (1 - k)) or 0
    m = (k < 1) and ((m - k) / (1 - k)) or 0
    y = (k < 1) and ((y - k) / (1 - k)) or 0

    return c, m, y, k
end

--[[
    c [0, 1]
    y [0, 1]
    m [0, 1]
    k [0, 1]
]]
CMYK.toRGB = function(c, m, y, k)
    return
        (1 - c) * (1 - k),
        (1 - m) * (1 - k),
        (1 - y) * (1 - k)
end

return CMYK