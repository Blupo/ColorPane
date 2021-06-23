-- Equations: https://en.wikipedia.org/wiki/HSL_and_HSV#Color_conversion_formulae

local root = script.Parent.Parent

local Common = root:FindFirstChild("Common")
local HSXUtil = require(Common:FindFirstChild("HSXUtil"))

---

local HSB = {}

HSB.fromRGB = function(r, g, b)
    local maxComponent = math.max(r, g, b)
    local minComponent = math.min(r, g, b)
    local chroma = maxComponent - minComponent

    local h, s = HSXUtil.getHue(chroma, maxComponent, r, g, b)

    if (maxComponent == 0) then
        s = 0
    else
        s = chroma / maxComponent
    end

    return h, s, maxComponent
end

--[[
    h [0, 1]
    s [0, 1]
    b [0, 1]
]]
HSB.toRGB = function(h, s, b)
    local chroma = b * s
    local h2 = (h * 360) / 60
    local match = b - chroma
    local secondLargestComponent = chroma * (1 - math.abs((h2 % 2) - 1))

    local r1, g1, b1 = HSXUtil.getIntermediateRGB(h2, chroma, secondLargestComponent)

    return
        r1 + match,
        g1 + match,
        b1 + match
end

return HSB