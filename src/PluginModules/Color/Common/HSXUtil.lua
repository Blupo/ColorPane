-- Equations: https://en.wikipedia.org/wiki/HSL_and_HSV#Color_conversion_formulae

local HSXUtil = {}

HSXUtil.getIntermediateRGB = function(hueSegment, chroma, secondLargestComponent)
    if ((hueSegment >= 0) and (hueSegment <= 1)) then
        return chroma, secondLargestComponent, 0
    elseif ((hueSegment > 1) and (hueSegment <= 2)) then
        return secondLargestComponent, chroma, 0
    elseif ((hueSegment > 2) and (hueSegment <= 3)) then
        return 0, chroma, secondLargestComponent
    elseif ((hueSegment > 3) and (hueSegment <= 4)) then
        return 0, secondLargestComponent, chroma
    elseif ((hueSegment > 4) and (hueSegment <= 5)) then
        return secondLargestComponent, 0, chroma
    elseif ((hueSegment > 5) and (hueSegment <= 6)) then
        return chroma, 0, secondLargestComponent
    else
        return  0, 0, 0
    end
end

HSXUtil.getHue = function(chroma, maxComponent, r, g, b)
    local h = 0

    if (chroma == 0) then
        h = 0
    elseif (maxComponent == r) then
        h = 60 * (((g - b) / chroma) % 6)
        h = h / 360
    elseif (maxComponent == g) then
        h = 60 * (2 + ((b - r) / chroma))
        h = h / 360
    elseif (maxComponent == b) then
        h = 60 * (4 + ((r - g) / chroma))
        h = h / 360
    end

    return h
end

return HSXUtil