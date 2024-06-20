--!strict
-- Common Luau types used in the projects

export type KeyValue = {
    Key: string,
    Value: any
}

export type ColorPalette = {
    name: string,

    colors: {{
        name: string,
        color: {number}
    }},
}

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

export type ColorPalettes = {ColorPalette}
export type GradientPalettes = {GradientPalette}

export type UserData = {
    AskNameBeforePaletteCreation: boolean,
    SnapValue: number,

    UserColorPalettes: ColorPalettes,
    UserGradientPalettes: GradientPalettes,

    AutoLoadColorPropertiesAPIData: boolean,
    CacheColorPropertiesAPIData: boolean,
}

---

return {}