--!strict

--[[
    Represents the set of values used in UserData.
]]
export type UserDataValues = {[string]: any}

--[[
    Represents a key-value pair.
]]
export type KeyValue = {
    Key: string,
    Value: any
}

--[[
    Represents a raw color palette.
]]
export type ColorPalette = {
    name: string,

    colors: {{
        name: string,
        color: {number}
    }},
}

--[[
    Represents a raw gradient palette.
]]
export type GradientPalette = {
    name: string,
    
    gradients: {{
        name: string,
        colorSpace: string,
        hueAdjustment: string,
        precision: number,

        keypoints: {{
            time: number,
            color: {number}
        }}
    }}
}

--[[
    An array of raw color palettes.
]]
export type ColorPalettes = {ColorPalette}

--[[
    An array of raw gradient palettes.
]]
export type GradientPalettes = {GradientPalette}

--[[
    User data values for ColorPane.
]]
export type ColorPaneUserData = {
    AskNameBeforePaletteCreation: boolean,
    SnapValue: number,

    UserColorPalettes: ColorPalettes,
    UserGradientPalettes: GradientPalettes,
}

---

return {}