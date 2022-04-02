local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Translator = require(PluginModules:FindFirstChild("Translator"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local BuiltInPalettes = require(includes:FindFirstChild("BuiltInPalettes"))
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local ColorBrewerPalettes = require(Components:FindFirstChild("ColorBrewerPalettes"))
local Palette = require(Components:FindFirstChild("Palette"))

local BrickColors = BuiltInPalettes.BrickColors
local CopicColors = BuiltInPalettes.CopicColors
local WebColors = BuiltInPalettes.WebColors

---

return {
    {
        name = "BrickColors",
        
        getContent = function()
            return Roact.createElement(Palette, {
                palette = Util.typeColorPalette(BrickColors, "Color3"),
                paletteIndex = -1,
                readOnly = true
            })
        end
    },

    {
        name = "ColorBrewer",

        getContent = function()
            return Roact.createElement(ColorBrewerPalettes)
        end
    },

    {
        name = Translator.FormatByKey("Copic_BuiltInPaletteName"),
        
        getContent = function()
            return Roact.createElement(Palette, {
                palette = Util.typeColorPalette(CopicColors, "Color3"),
                paletteIndex = -2,
                readOnly = true
            })
        end
    },

    {
        name = Translator.FormatByKey("Web_BuiltInPaletteName"),

        getContent = function()
            return Roact.createElement(Palette, {
                palette = Util.typeColorPalette(WebColors, "Color3"),
                paletteIndex = -3,
                readOnly = true
            })
        end
    }
}