local Color3Global = Color3

---

local Color3 = {}

Color3.fromRGB = function(r, g, b)
    return Color3Global.new(r, g, b)
end

Color3.toRGB = function(color)
    return color.R, color.G, color.B
end

return Color3