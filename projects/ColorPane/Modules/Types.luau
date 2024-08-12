--!strict
-- Common Luau types used in ColorPane

local root = script.Parent.Parent
local Common = root.Common
local CommonIncludes = Common.Includes
local Color = require(CommonIncludes.Color)

---

export type table = {[any]: any}
export type Color = Color.Color
export type Gradient = Color.Gradient

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
    color: Color
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

export type ColorPromptInfoArgument = {
    PromptTitle: string?,
    InitialColor: (Color | Color3)?,
    ColorType: ("Color" | "Color3")?,
    OnColorChanged: (((Color) -> ()) | ((Color3) -> ()))?
}

export type GradientPromptInfoArgument = {
    PromptTitle: string?,
    InitialGradient: (Gradient | ColorSequence)?,
    InitialColorSpace: Color.MixableColorType?,
    InitialHueAdjustment: Color.HueAdjustment?,
    InitialPrecision: number?,
    GradientType: ("Gradient" | "ColorSequence")?,
    OnGradientChanged: (((Gradient) -> ()) | ((ColorSequence) -> ()))?
}

---

return {}