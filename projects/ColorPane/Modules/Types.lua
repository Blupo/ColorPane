--!strict
-- Common Luau types used in ColorPane

local root = script.Parent.Parent
local Includes = root.Includes
local Color = require(Includes.Color)

---

export type table = {[any]: any}

export type ColorPaletteColor = {
    name: string,
    color: Color3
}

export type ColorPalette = {
    name: string,
    colors: {ColorPaletteColor},
}

export type GradientKeypoint = {
    time: number,
    color: Color.Color
}

export type GradientPaletteGradient = {
    name: string,
    colorSpace: string,
    hueAdjustment: string,
    precision: number,

    keypoints: {GradientKeypoint}
}

export type GradientPalette = {
    name: string,
    gradients: {GradientPaletteGradient}
}

---

return {}