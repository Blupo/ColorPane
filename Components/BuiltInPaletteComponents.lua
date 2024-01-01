local root = script.Parent.Parent

local PluginModules = root.PluginModules
local Translator = require(PluginModules.Translator)
local Util = require(PluginModules.Util)

local includes = root.includes
local BuiltInPalettes = require(includes.BuiltInPalettes)
local Roact = require(includes.Roact)

local Components = root.Components
local ColorBrewerPalettes = require(Components.ColorBrewerPalettes)
local PicularPalette = require(Components.PicularPalette)
local Palette = require(Components.Palette)

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
        name = "Picular",

        getContent = function()
            return Roact.createElement(PicularPalette)
        end,
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