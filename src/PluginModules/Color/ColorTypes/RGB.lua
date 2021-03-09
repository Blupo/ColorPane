local RGB = {}

RGB.fromRGB = function(r, g, b)
    return {r, g, b}
end

RGB.toRGB = function(r, g, b)
    return r, g, b
end

return RGB