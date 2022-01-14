local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local BuiltInPalettes = require(includes:FindFirstChild("BuiltInPalettes"))
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local ColorBrewerPalettes = require(Components:FindFirstChild("ColorBrewerPalettes"))
local ColorVariations = require(Components:FindFirstChild("ColorVariations"))
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
        name = "Copic Colors",
        
        getContent = function()
            return Roact.createElement(Palette, {
                palette = Util.typeColorPalette(CopicColors, "Color3"),
                readOnly = true
            })
        end
    },

    {
        name = "Variations",
        
        getContent = function()
            return Roact.createElement(ColorVariations)
        end
    },

    {
        name = "Web Colors",

        getContent = function()
            return Roact.createElement(Palette, {
                palette = Util.typeColorPalette(WebColors, "Color3"),
                readOnly = true
            })
        end
    }
}