local HEX_RADIX = "0123456789abcdef"

local toHex = function(n, r, padding): string?
    if (r < 2) then return end
    
    local t = ""
    
    repeat
        t = t .. string.sub(HEX_RADIX, ((n % r) + 1), ((n % r) + 1))
        n = math.floor(n / r)
    until (n == 0)
    
    return string.rep("0", padding - string.len(t)) .. string.reverse(t)
end

---

local Hex = {}

Hex.fromRGB = function(r, g, b)
    r, g, b = math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)

    local rHex = toHex(r, 16, 2)
    local gHex = toHex(g, 16, 2)
    local bHex = toHex(b, 16, 2)

    return rHex .. gHex .. bHex
end

Hex.toRGB = function(hex)
    hex = string.gsub(hex, "%X", "")

    local r, g, b

    local length = string.len(hex)
    if ((length ~= 3) and (length ~= 6)) then return end

    if (length == 3) then
        local r1, g1, b1 = string.match(hex, "(%x)(%x)(%x)")
        if (not (r1 and g1 and b1)) then return end

        r, g, b = r1 .. r1, g1 .. g1, b1 .. b1
    else
        r, g, b = string.match(hex, "(%x%x)(%x%x)(%x%x)")
        if (not (r and g and b)) then return end
    end
    
    return 
        tonumber(r, 16) / 255,
        tonumber(g, 16) / 255,
        tonumber(b, 16) / 255
end

return Hex