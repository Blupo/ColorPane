--[[
    D65 Tristimulus Values
        X = 95.04
        Y = 100
        Z = 108.88

    sRGB Chromaticity Coordinates
        r = (0.64, 0.33)
        g = (0.30, 0.60)
        b = (0.15, 0.06)

    Equations
        RGB <-> XYZ matrices: http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
        RGB -> XYZ: http://www.brucelindbloom.com/index.html?Eqn_RGB_to_XYZ.html
        XYZ -> RGB: http://www.brucelindbloom.com/index.html?Eqn_XYZ_to_RGB.html
]]

local sRGB_XYZ_MATRIX = {
    {962624/2334375, 3339089/9337500, 67391/373500},
    {165451/778125, 3339089/4668750, 67391/933750},
    {15041/778125, 3339089/28012500, 5323889/5602500}
}

local XYZ_sRGB_MATRIX = {
    {3750/1157, -23125/15041, -7500/15041},
    {-3236250/3339089, 6263750/3339089, 138750/3339089},
    {3750/67391, -13750/67391, 71250/67391}
}

---

local XYZ = {}

XYZ.fromRGB = function(r, g, b)
    local rgb = {r, g, b}

    -- gamma correction
    for i = 1, #rgb do
        local v = rgb[i]

        if (v <= 0.04045) then
            rgb[i] = v / 12.92
        else
            rgb[i] = ((v + 0.055) / 1.055)^2.4
        end
    end

    r, g, b = table.unpack(rgb)

    -- to XYZ
    return
        (sRGB_XYZ_MATRIX[1][1] * r) + (sRGB_XYZ_MATRIX[1][2] * g) + (sRGB_XYZ_MATRIX[1][3] * b),
        (sRGB_XYZ_MATRIX[2][1] * r) + (sRGB_XYZ_MATRIX[2][2] * g) + (sRGB_XYZ_MATRIX[2][3] * b),
        (sRGB_XYZ_MATRIX[3][1] * r) + (sRGB_XYZ_MATRIX[3][2] * g) + (sRGB_XYZ_MATRIX[3][3] * b)
end

--[[
    x [0, 1]
    y [0, 1]
    z [0, 1]
]]
XYZ.toRGB = function(x, y, z)
    -- to sRGB
    local rgb = {
        (XYZ_sRGB_MATRIX[1][1] * x) + (XYZ_sRGB_MATRIX[1][2] * y) + (XYZ_sRGB_MATRIX[1][3] * z),
        (XYZ_sRGB_MATRIX[2][1] * x) + (XYZ_sRGB_MATRIX[2][2] * y) + (XYZ_sRGB_MATRIX[2][3] * z),
        (XYZ_sRGB_MATRIX[3][1] * x) + (XYZ_sRGB_MATRIX[3][2] * y) + (XYZ_sRGB_MATRIX[3][3] * z),
    }

    -- gamma correction
    for i = 1, #rgb do
        local v = rgb[i]

        if (v <= 0.0031308) then
            rgb[i] = 12.92 * v
        else
            rgb[i] = (1.055 * v^(1 / 2.4)) - 0.055
        end
        
        rgb[i] = math.clamp(rgb[i], 0, 1)
    end

    return table.unpack(rgb)
end

return XYZ