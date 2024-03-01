--!strict
-- Provides constants used in ColorPane

local CONSTANTS = {
    VALID_GRADIENT_COLOR_SPACES = { "RGB", "CMYK", "HSB", "HWB", "HSL", "HPLuv", "HSLuv", "Lab", "Oklab", "Luv", "LChab", "LChuv", "xyY", "XYZ" },
    VALID_HUE_ADJUSTMENTS = { "Shorter", "Longer", "Increasing", "Decreasing", "Specified" },

    KELVIN_LOWER_RANGE = 1000,
    KELVIN_UPPER_RANGE = 10000,
}

-- Calculate the maximum number of keypoints that can be in a ColorSequence
do
    local KEYPOINT_LIMIT: number = 102  -- set an artificial limit in case the limit imposed by the engine is removed

    local numKeypoints: number = 3
    local done: boolean = false

    while (not done) do
        local keypoints: {ColorSequenceKeypoint} = {}

        for i = 1, numKeypoints do
            table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / (numKeypoints - 1), Color3.new()))
        end

        -- pcall(ColorSequence.new, keypoints) raises a type-checking error
        local isColorSequenceOk: boolean = pcall(function()
            return ColorSequence.new(keypoints)
        end)

        if ((isColorSequenceOk) and (numKeypoints <= KEYPOINT_LIMIT)) then
            numKeypoints += 1
        else
            numKeypoints -= 1
            done = true
        end
    end

    CONSTANTS.MAX_COLORSEQUENCE_KEYPOINTS = numKeypoints
end

---

return CONSTANTS