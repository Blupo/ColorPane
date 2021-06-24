local root = script.Parent.Parent

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local ColorBrewerPalettes = require(Components:FindFirstChild("ColorBrewerPalettes"))
local ColorVariations = require(Components:FindFirstChild("ColorVariations"))
local Palette = require(Components:FindFirstChild("Palette"))

local BrickColors = require(script:FindFirstChild("BrickColors"))
local WebColors = require(script:FindFirstChild("WebColors"))

---

return {
    {
        name = "BrickColors",
        
        getContent = function()
            return Roact.createElement(Palette, {
                palette = BrickColors,
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
        name = "Variations",
        
        getContent = function()
            return Roact.createElement(ColorVariations)
        end
    },

    {
        name = "Web Colors",

        getContent = function()
            return Roact.createElement(Palette, {
                palette = WebColors,
                readOnly = true
            })
        end
    }
}