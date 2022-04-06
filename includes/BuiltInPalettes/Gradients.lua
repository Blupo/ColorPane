local root = script.Parent.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Constants = require(PluginModules:FindFirstChild("Constants"))
local Translator = require(PluginModules:FindFirstChild("Translator"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local Color = require(includes:FindFirstChild("Color")).Color

---

return {
    {
        name = Translator.FormatByKey("BlackToWhite_BuiltInGradientName"),

        keypoints = {
            { Time = 0, Color = Color.new(0, 0, 0) },
            { Time = 1, Color = Color.new(1, 1, 1) }
        }
    },

    {
        name = Translator.FormatByKey("Hue_BuiltInGradientName"),
        colorSpace = "HSB",

        keypoints = {
            { Time = 0, Color = Color.fromHSB(0, 1, 1) },
            { Time = 1/6, Color = Color.fromHSB(60, 1, 1) },
            { Time = 2/6, Color = Color.fromHSB(120, 1, 1) },
            { Time = 3/6, Color = Color.fromHSB(180, 1, 1) },
            { Time = 4/6, Color = Color.fromHSB(240, 1, 1) },
            { Time = 5/6, Color = Color.fromHSB(300, 1, 1) },
            { Time = 1, Color = Color.fromHSB(360, 1, 1) }
        }
    },

    {
        name = Translator.FormatByKey("Temperature_BuiltInGradientName"),

        keypoints = {
            { Time = 0, Color = Color.fromTemperature(1000) },
            { Time = Util.inverseLerp(Constants.KELVIN_LOWER_RANGE, Constants.KELVIN_UPPER_RANGE, 2000), Color = Color.fromTemperature(2000) },
            { Time = Util.inverseLerp(Constants.KELVIN_LOWER_RANGE, Constants.KELVIN_UPPER_RANGE, 6000), Color = Color.fromTemperature(6000) },
            { Time = Util.inverseLerp(Constants.KELVIN_LOWER_RANGE, Constants.KELVIN_UPPER_RANGE, 6500), Color = Color.fromTemperature(6500) },
            { Time = Util.inverseLerp(Constants.KELVIN_LOWER_RANGE, Constants.KELVIN_UPPER_RANGE, 7000), Color = Color.fromTemperature(7000) },
            { Time = 1, Color = Color.fromTemperature(10000) },
        }
    }
}