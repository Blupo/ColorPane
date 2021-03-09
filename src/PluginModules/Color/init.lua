local ColorTypes = script:FindFirstChild("ColorTypes")
local ColorTypeScripts = ColorTypes:GetChildren()

---

local FROM_KEY = "from"
local TO_KEY = "to"
local COMMON_SPACE = "RGB"

local Color = {}

local colorConstructor = function(r, g, b)
    return setmetatable({
        __r = r,
        __g = g,
        __b = b
    }, {
        __index = Color,

        __eq = function(color1, color2)
            return (color1.__r == color2.__r) and (color1.__g == color2.__g) and (color1.__b == color2.__b)
        end,

        __tostring = function(color)
            return color.__r .. ", " .. color.__g .. ", " .. color.__b
        end
    })
end

for i = 1, #ColorTypeScripts do
    local colorTypeScript = ColorTypeScripts[i]

    local colorTypeName = colorTypeScript.Name
    local colorType = require(colorTypeScript)

    Color[TO_KEY .. colorTypeName] = function(self)
        return colorType[FROM_KEY .. COMMON_SPACE](self.__r, self.__g, self.__b)
    end

    Color[FROM_KEY .. colorTypeName] = function(...)
        local r, g, b = colorType[TO_KEY .. COMMON_SPACE](...)
        if (not (r and g and b)) then return end

        return colorConstructor(r, g, b)
    end
end

-- WCAG definition of relative luminance
-- https://www.w3.org/TR/2008/REC-WCAG20-20081211/#relativeluminancedef
Color.getLuminance = function(self)
    local r1, g1, b1 = self.__r, self.__g, self.__b

    local r2 = (r1 <= 0.03928) and (r1 / 12.92) or (((r1 + 0.055) / 1.055) ^ 2.4)
    local g2 = (g1 <= 0.03928) and (g1 / 12.92) or (((g1 + 0.055) / 1.055) ^ 2.4)
    local b2 = (b1 <= 0.03928) and (b1 / 12.92) or (((b1 + 0.055) / 1.055) ^ 2.4)

    return (0.2126 * r2) + (0.7152 * g2) + (0.0722 * b2)
end

-- WCAG definition of contrast ratio
-- https://www.w3.org/TR/2008/REC-WCAG20-20081211/#contrast-ratiodef
Color.getContrast = function(color1, color2)
    local c1Luminance, c2Luminance = Color.getLuminance(color1), Color.getLuminance(color2)

    return (c1Luminance > c2Luminance) and
        ((c1Luminance + 0.05) / (c2Luminance + 0.05))
    or ((c2Luminance + 0.05) / (c1Luminance + 0.05))
end

Color.getBestContrastingColor = function(self, ...)
    local options = {...}

    table.sort(options, function(option1, option2)
        local o1Contrast = Color.getContrast(self, option1)
        local o2Contrast = Color.getContrast(self, option2)

        return (o1Contrast > o2Contrast)
    end)

    return options[1]
end

Color.invert = function(self)
    return colorConstructor(1 - self.__r, 1 - self.__g, 1 - self.__b)
end

return Color