--!strict
-- Run-time validators for API call parameters

local root = script.Parent.Parent
local Common = root.Common
local CommonIncludes = Common.Includes

local ColorLib = require(CommonIncludes.Color)
local t = require(CommonIncludes.t)

local Color = ColorLib.Color
local Gradient = ColorLib.Gradient

---

local APITypeValidators = {}

--[[
    Checks that a ColorPromptInfoArgument is valid.
    Note that this cannot check if ColorType and the
    argument type to OnColorChanged match.

    @param value The value to check
    @return If the value is a ColorPromptInfoArgument
    @return An error message if the value is not a ColorPromptInfoArgument
]]
APITypeValidators.ColorPromptInfoArgument = t.optional(t.interface({
    PromptTitle = t.optional(t.string),
    InitialColor = t.optional(t.union(Color.isAColor, t.Color3)),
    ColorType = t.optional(t.literal("Color", "Color3")),
    OnColorChanged = t.optional(t.callback)
}))

--[[
    Checks that a ColorPromptInfoArgument is valid.
    Note that this doesn't check if the number of keypoints
    and the provided precision is a valid combination, and
    cannot check if GradientType and the argument type to
    OnGradientChanged match.

    @param value The value to check
    @return If the value is a GradientPromptInfoArgument
    @return An error message if the value is not a GradientPromptInfoArgument
]]
APITypeValidators.GradientPromptInfoArgument = t.optional(t.interface({
    PromptTitle = t.optional(t.string),
    InitialGradient = t.optional(t.union(Gradient.isAGradient, t.ColorSequence)),
    InitialColorSpace = t.optional(t.literal("CMYK", "HPLuv", "HSB", "HSL", "HSLuv", "HSV", "HWB", "LCh", "LChab", "LChuv", "Lab", "Luv", "Oklab", "RGB", "xyY", "XYZ")),
    InitialHueAdjustment = t.optional(t.literal("Shorter", "Longer", "Increasing", "Decreasing", "Raw", "Specified")),
    InitialPrecision = t.optional(t.integer),
    GradientType = t.optional(t.literal("Gradient", "ColorSequence")),
    OnGradientChanged = t.optional(t.callback)
}))

return APITypeValidators