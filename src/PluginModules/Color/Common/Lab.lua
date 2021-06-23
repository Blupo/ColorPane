--[[
    Equations
        XYZ -> L*a*b*: http://www.brucelindbloom.com/index.html?Eqn_XYZ_to_Lab.html
        L*a*b* to XYZ: http://www.brucelindbloom.com/index.html?Eqn_Lab_to_XYZ.html
]]

-- D65 tristimulus values
local Xw = 95.04
local Yw = 100
local Zw = 108.88

local K = 24389/27
local E = 216/24389

local transform = function(t)
    if (t > E) then
        return t^(1/3)
    else
        return ((K * t) + 16) / 116
    end
end

---

local Lab = {}

--[[
    x [0, 1]
    y [0, 1]
    z [0, 1]

    L* [ 0, 1]
    a* [-1, 1]
    b* [-1, 1]
]]
Lab.fromXYZ = function(x, y, z)
    x, y, z = x * 100, y * 100, z * 100

    local l = (116 * transform(y / Yw)) - 16
    local a = 500 * (transform(x / Xw) - transform(y / Yw))
    local b = 200 * (transform(y / Yw) - transform(z / Zw))

    return
        l / 100,
        a / 100,
        b / 100
end

--[[
    L* [ 0, 1]
    a* [-1, 1]
    b* [-1, 1]

    x [0, 1]
    y [0, 1]
    z [0, 1]
]]
Lab.toXYZ = function(l, a, b)
    l, a, b = l * 100, a * 100, b * 100

    local fy = (l + 16) / 116
    local fx = (a / 500) + fy
    local fz = fy - (b / 200)

    local xr
    local yr
    local zr

    if ((fx^3) > E) then
        xr = fx^3
    else
        xr = ((116 * fx) - 16) / K
    end

    if (l > (K * E)) then
        yr = fy^3
    else
        yr = l / K
    end

    if ((fz^3) > E) then
        zr = fz^3
    else
        zr = ((116 * fz) - 16) / K
    end

    local x = xr * Xw
    local y = yr * Yw
    local z = zr * Zw

    return
        x / 100,
        y / 100,
        z / 100
end

return Lab