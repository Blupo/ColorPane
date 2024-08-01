--!strict
-- Provides constants used in the projects

local StudioService: StudioService = game:GetService("StudioService")

---

local CONSTANTS = {
    --[[
        The list of valid gradient color spaces.
    ]]
    VALID_GRADIENT_COLOR_SPACES = { "RGB", "CMYK", "HSB", "HWB", "HSL", "HPLuv", "HSLuv", "Lab", "Oklab", "Luv", "LChab", "LChuv", "xyY", "XYZ" },

    --[[
        The list of valid hue adjustments.
    ]]
    VALID_HUE_ADJUSTMENTS = { "Shorter", "Longer", "Increasing", "Decreasing", "Specified" },

    --[[
        The lower bound of color temperatures, in Kelvin.
    ]]
    KELVIN_LOWER_RANGE = 1000,

    --[[
        The upper bound of color temperatures, in Kelvin.
    ]]
    KELVIN_UPPER_RANGE = 10000,

    --[[
        The minimum time value that gradient keypoints must be separated by.
    ]]
    MIN_SNAP_VALUE = 0.00001,

    --[[
        The maximum time value that gradient keypoints can be separated by.
    ]]
    MAX_SNAP_VALUE = 0.25,

    --[[
        The name of the ColorPane user interface folder.
    ]]
    COLORPANE_USERDATA_INTERFACE_NAME = "ColorPaneUserData_" .. StudioService:GetUserId(),
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

    --[[
        The maximum number of ColorSequenceKeypoints that can be in a ColorSequence.
    ]]
    CONSTANTS.MAX_COLORSEQUENCE_KEYPOINTS = numKeypoints
end

---

return CONSTANTS