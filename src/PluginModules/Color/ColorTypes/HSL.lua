local root = script.Parent.Parent

local Common = root:FindFirstChild("Common")
local HSXUtil = require(Common:FindFirstChild("HSXUtil"))

---

local HSL = {}

HSL.fromRGB = function(r, g, b)
    local maxComponent = math.max(r, g, b)
    local minComponent = math.min(r, g, b)
    local chroma = maxComponent - minComponent
    local lightness = (maxComponent + minComponent) / 2

    local h, s = HSXUtil.getHue(chroma, maxComponent, r, g, b)

    if ((lightness == 0) or (lightness == 1)) then
        s = 0
    else
        s = chroma / (1 - math.abs((2 * maxComponent) - chroma - 1))
    end

    return h, s, lightness
end

HSL.toRGB = function(h, s, l)
    local chroma = (1 - math.abs((2 * l) - 1)) * s
    local h2 = (h * 360) / 60
    local match = l - (chroma / 2)
    local secondLargestComponent = chroma * (1 - math.abs((h2 % 2) - 1))

    local r1, g1, b1 = HSXUtil.getIntermediateRGB(h2, chroma, secondLargestComponent)

    return
        r1 + match,
        g1 + match,
        b1 + match
end

return HSL