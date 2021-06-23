--[[
    Equations
        Lab -> LCh: http://www.brucelindbloom.com/index.html?Eqn_Lab_to_LCH.html
        LCh -> Lab: http://www.brucelindbloom.com/index.html?Eqn_LCH_to_Lab.html
]]

local LCh = {}

--[[
    L* [ 0, 1]
    a* [-1, 1]
    b* [-1, 1]

    h [0, 2pi)
]]
LCh.fromLab = function(l, a, b)
    a, b = a * 100, b * 100

    local c = math.sqrt(a^2 + b^2)
    local h = math.atan2(b, a)
    h = (h < 0) and (h + (2 * math.pi)) or h

    return l, c / 100, h
end

LCh.toLab = function(l, c, h)
    local a = c * math.cos(h)
    local b = c * math.sin(h)

    return l, a, b
end

return LCh