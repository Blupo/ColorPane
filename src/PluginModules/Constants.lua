local CONSTANTS = {
    VALID_GRADIENT_COLOR_SPACES = table.freeze({ "RGB", "CMYK", "HSB", "HWB", "HSL", "Lab", "Luv", "LChab", "LChuv", "xyY", "XYZ" }),
    VALID_HUE_ADJUSTMENTS = table.freeze({ "Shorter", "Longer", "Increasing", "Decreasing", "Specified" }),

    KELVIN_LOWER_RANGE = 1000,
    KELVIN_UPPER_RANGE = 10000,
}

do
    local n: number = 2
    local csConstructionOk: boolean = true
    
    -- in case the limit is removed, cap at 100
    while ((csConstructionOk) and (n < 101)) do
        n = n + 1

        local keypoints: {ColorSequenceKeypoint} = {}

        for i = 1, n do
            table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / (n - 1), Color3.new()))
        end

        csConstructionOk = pcall(ColorSequence.new, keypoints)
    end

    CONSTANTS.MAX_COLORSEQUENCE_KEYPOINTS = n - 1
end

---

return table.freeze(CONSTANTS)