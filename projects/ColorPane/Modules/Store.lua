-- TODO
-- ColorPane store
local Studio: Studio = settings().Studio

---

local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local PluginProvider = require(CommonModules.PluginProvider)

local CommonIncludes = Common.Includes
local Cryo = require(CommonIncludes.Cryo)
local Rodux = require(CommonIncludes.RoactRodux.Rodux)

local Includes = root.Includes
local Color = require(Includes.Color).Color

local Modules = root.Modules
local PluginEnums = require(Modules.PluginEnums)
--local PluginSettings = require(Modules.PluginSettings)
local Util = require(Modules.Util)

---

local plugin: Plugin = PluginProvider()
local userPalettes = {} --Util.table.deepCopy(PluginSettings.Get(PluginEnums.PluginSettingKey.UserPalettes) or {})
local userGradients = {} --Util.table.deepCopy(PluginSettings.Get(PluginEnums.PluginSettingKey.UserGradients) or {})

-- convert saved palettes into actual palettes
for i = 1, #userPalettes do
    local palette = userPalettes[i]

    for j = 1, #palette.colors do
        local color = palette.colors[j]
        local colorValue = color.color

        color.color = Color3.new(colorValue[1], colorValue[2], colorValue[3])
    end
end

-- convert saved gradients into actual gradients
for i = 1, #userGradients do
    local gradient = userGradients[i]
    local keypoints = gradient.keypoints

    for j = 1, #keypoints do
        local keypoint = keypoints[j]

        keypoints[j] = {
            Time = keypoint.Time, 
            Color = Color.new(table.unpack(keypoint.Color))
        }
    end
end

local colorPaneStoreInitialState = Util.table.deepFreeze({
    theme = Studio.Theme,

    sessionData = {
        editorPage = 1,
        lastSliderPage = {1, 1},
        lastPalettePage = {1, 1},
        lastToolPage = {1, 1},
        lastHueHarmony = 1,
        paletteLayout = "grid",

        cbDataClass = 1,
        cbNumDataClasses = 3,

        variationSteps = 10,
        colorSorterColors = {},
        picularSearchHistory = {},
    },
    
    colorEditor = {
        authoritativeEditor = "",
        
        quickPalette = {},
        palettes = userPalettes,
    },

    gradientEditor = {
        snap = 0.00001, --PluginSettings.Get(PluginEnums.PluginSettingKey.SnapValue),
        palette = userGradients,
    }
})

---

local Store = Rodux.Store.new(Rodux.createReducer(colorPaneStoreInitialState, {
    --[[
        theme: StudioTheme
    ]]
    [PluginEnums.StoreActionType.SetTheme] = function(oldState, action)
        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            theme = action.theme
        }))
    end,

    --[[
        slice: dictionary<any, any>
    ]]
    [PluginEnums.StoreActionType.UpdateSessionData] = function(oldState, action)
        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            sessionData = Cryo.Dictionary.join(oldState.sessionData, action.slice)
        }))
    end,
    
    --[[
        color: Color
        editor: PluginEnums.EditorKey?
    ]]
    [PluginEnums.StoreActionType.ColorEditor_SetColor] = function(oldState, action)
        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            colorEditor = Cryo.Dictionary.join(oldState.colorEditor, {
                color = action.color,
                authoritativeEditor = action.editor or PluginEnums.EditorKey.Default
            })
        }))
    end,

    --[[
        color: Color
    ]]
    [PluginEnums.StoreActionType.ColorEditor_AddQuickPaletteColor] = function(oldState, action)
        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            colorEditor = Cryo.Dictionary.join(oldState.colorEditor, {
                quickPalette = Cryo.List.join({action.color}, oldState.colorEditor.quickPalette)
            })
        }))
    end,

    --[[
        palette: Palette?
        name: string?
    ]]
    [PluginEnums.StoreActionType.ColorEditor_AddPalette] = function(oldState, action)
        local newPalette
        local palettes = oldState.colorEditor.palettes

        if (action.palette) then
            newPalette = action.palette
        else
            local desiredPaletteName = action.name or "New Palette"
            local actualPaletteName = Util.palette.getNewItemName(palettes, desiredPaletteName)

            newPalette = {
                name = actualPaletteName,
                colors = {}
            }
        end

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            colorEditor = Cryo.Dictionary.join(oldState.colorEditor, {
                palettes = Cryo.List.join(palettes, {newPalette})
            })
        }))
    end,

    --[[
        index: number
    ]]
    [PluginEnums.StoreActionType.ColorEditor_RemovePalette] = function(oldState, action)
        local palettes = oldState.colorEditor.palettes
        local index = action.index
        if (not palettes[index]) then return oldState end

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            colorEditor = Cryo.Dictionary.join(oldState.colorEditor, {
                palettes = Cryo.List.removeIndex(palettes, index)
            })
        }))
    end,

    --[[
        index: number
    ]]
    [PluginEnums.StoreActionType.ColorEditor_DuplicatePalette] = function(oldState, action)
        local palettes = oldState.colorEditor.palettes
        local index = action.index

        local palette = palettes[index]
        if (not palette) then return oldState end

        local matchStart = string.find(palette.name, "%s*%(%d+%)$")
        local nameWithoutCounter = if (matchStart) then string.sub(palette.name, 1, matchStart - 1) else palette.name

        local newPaletteName = Util.palette.getNewItemName(palettes, nameWithoutCounter)
        local newPalette = Util.table.deepCopy(palette)
        newPalette.name = newPaletteName

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            colorEditor = Cryo.Dictionary.join(oldState.colorEditor, {
                palettes = Cryo.List.join(palettes, {newPalette})
            })
        }))
    end,

    --[[
        index: number
        newName: string
    ]]
    [PluginEnums.StoreActionType.ColorEditor_ChangePaletteName] = function(oldState, action)
        local palettes = oldState.colorEditor.palettes
        local index = action.index

        local palette = palettes[index]
        if (not palette) then return oldState end

        local newPaletteName = Util.palette.getNewItemName(palettes, action.newName, index)
        if (newPaletteName == palette.name) then return oldState end

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            colorEditor = Cryo.Dictionary.join(oldState.colorEditor, {
                palettes = Cryo.List.replaceIndex(palettes, index, Cryo.Dictionary.join(palette, {
                    name = newPaletteName
                }))
            })
        }))
    end,

    --[[
        paletteIndex: number,
        newName: string?
    ]]
    [PluginEnums.StoreActionType.ColorEditor_AddCurrentColorToPalette] = function(oldState, action)
        local palettes = oldState.colorEditor.palettes
        local paletteIndex = action.paletteIndex
        
        local palette = palettes[paletteIndex]
        if (not palette) then return oldState end

        local paletteColors = palette.colors
        local newColorName = Util.palette.getNewItemName(paletteColors, action.newName or "New Color")

        local newColor = {
            name = newColorName,
            color = oldState.colorEditor.color:toColor3(),
        }

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            colorEditor = Cryo.Dictionary.join(oldState.colorEditor, {
                palettes = Cryo.List.replaceIndex(palettes, paletteIndex, Cryo.Dictionary.join(palette, {
                    colors = Cryo.List.join(paletteColors, {newColor})
                }))
            })
        }))
    end,

    --[[
        paletteIndex: number,
        colorIndex: number
    ]]
    [PluginEnums.StoreActionType.ColorEditor_RemovePaletteColor] = function(oldState, action)
        local palettes = oldState.colorEditor.palettes
        local paletteIndex = action.paletteIndex
        
        local palette = palettes[paletteIndex]
        if (not palette) then return oldState end

        local paletteColors = palette.colors
        local colorIndex = action.colorIndex

        local color = paletteColors[colorIndex]
        if (not color) then return oldState end

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            colorEditor = Cryo.Dictionary.join(oldState.colorEditor, {
                palettes = Cryo.List.replaceIndex(palettes, paletteIndex, Cryo.Dictionary.join(palette, {
                    colors = Cryo.List.removeIndex(paletteColors, colorIndex)
                }))
            })
        }))
    end,

    --[[
        paletteIndex: number,
        colorIndex: number,
        newName: string
    ]]
    [PluginEnums.StoreActionType.ColorEditor_ChangePaletteColorName] = function(oldState, action)
        local palettes = oldState.colorEditor.palettes
        local paletteIndex = action.paletteIndex
        
        local palette = palettes[paletteIndex]
        if (not palette) then return oldState end

        local paletteColors = palette.colors
        local colorIndex = action.colorIndex

        local color = paletteColors[colorIndex]
        if (not color) then return oldState end

        local newColorName = Util.palette.getNewItemName(paletteColors, action.newName, colorIndex)
        if (newColorName == color.name) then return oldState end

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            colorEditor = Cryo.Dictionary.join(oldState.colorEditor, {
                palettes = Cryo.List.replaceIndex(palettes, paletteIndex, Cryo.Dictionary.join(palette, {
                    colors = Cryo.List.replaceIndex(paletteColors, colorIndex, Cryo.Dictionary.join(color, {
                        name = newColorName
                    }))
                }))
            })
        }))
    end,

    --[[
        paletteIndex: number,
        colorIndex: number,
        offset: number,
    ]]
    [PluginEnums.StoreActionType.ColorEditor_ChangePaletteColorPosition] = function(oldState, action)
        local palettes = oldState.colorEditor.palettes
        local paletteIndex = action.paletteIndex
        
        local palette = palettes[paletteIndex]
        if (not palette) then return oldState end

        local paletteColors = palette.colors
        local colorIndex = action.colorIndex
        local otherColorIndex = colorIndex + action.offset
        if (not (paletteColors[colorIndex] and paletteColors[otherColorIndex])) then return oldState end

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            colorEditor = Cryo.Dictionary.join(oldState.colorEditor, {
                palettes = Cryo.List.replaceIndex(palettes, paletteIndex, Cryo.Dictionary.join(palette, {
                    colors = Cryo.Dictionary.join(paletteColors, {
                        [colorIndex] = paletteColors[otherColorIndex],
                        [otherColorIndex] = paletteColors[colorIndex]
                    })
                }))
            })
        }))
    end,

    [PluginEnums.StoreActionType.GradientEditor_ResetState] = function(oldState)
        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = {
                snap = oldState.gradientEditor.snap,
                palette = oldState.gradientEditor.palette,
            }
        }))
    end,

    --[[
        keypoints: array<GradientKeypoint>?
        selectedKeypoint: number?
    ]]
    [PluginEnums.StoreActionType.GradientEditor_SetKeypoints] = function(oldState, action)
        local gradientEditorState = oldState.gradientEditor

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = Cryo.Dictionary.join(gradientEditorState, {
                keypoints = action.keypoints,
                selectedKeypoint = if (action.selectedKeypoint ~= -1) then action.selectedKeypoint else Cryo.None,

                displayKeypoints = Util.generateFullKeypointList(
                    action.keypoints or gradientEditorState.keypoints,
                    gradientEditorState.colorSpace,
                    gradientEditorState.hueAdjustment,
                    gradientEditorState.precision or 0
                )
            })
        }))
    end,

    --[[
        keypoints: array<GradientKeypoint>?,
        colorSpace: string?,
        hueAdjustment: string?,
        precision: number?
    ]]
    [PluginEnums.StoreActionType.GradientEditor_SetGradient] = function(oldState, action)
        local newKeypointInfo = Cryo.Dictionary.join(oldState.gradientEditor, {
            keypoints = action.keypoints,
            colorSpace = action.colorSpace,
            hueAdjustment = action.hueAdjustment,
            precision = action.precision,
        })

        local newDisplayKeypoints = Util.generateFullKeypointList(
            newKeypointInfo.keypoints,
            newKeypointInfo.colorSpace,
            newKeypointInfo.hueAdjustment,
            newKeypointInfo.precision or 0
        )

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = Cryo.Dictionary.join(oldState.gradientEditor, newKeypointInfo, {
                displayKeypoints = newDisplayKeypoints
            }),
        }))
    end,

    --[[
        snap: number
    ]]
    [PluginEnums.StoreActionType.GradientEditor_SetSnapValue] = function(oldState, action)
        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = Cryo.Dictionary.join(oldState.gradientEditor, {
                snap = action.snap
            })
        }))
    end,

    --[[
        name: string

        keypoints: array<GradientKeypoint>
        colorSpace: string?
        hueAdjustment: string?
        precision: number?
    ]]
    [PluginEnums.StoreActionType.GradientEditor_AddPaletteColor] = function(oldState, action)
        local gradientPalette = oldState.gradientEditor.palette
        local newColorName = Util.palette.getNewItemName(gradientPalette, action.name or "New Gradient")

        local newColor = {
            name = newColorName,

            keypoints = action.keypoints,
            colorSpace = action.colorSpace,
            hueAdjustment = action.hueAdjustment,
            precision = action.precision,
        }

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = Cryo.Dictionary.join(oldState.gradientEditor, {
                palette = Cryo.List.join(gradientPalette, {newColor}),
            })
        }))
    end,

    --[[
        index: number
    ]]
    [PluginEnums.StoreActionType.GradientEditor_RemovePaletteColor] = function(oldState, action)
        local gradientPalette = oldState.gradientEditor.palette
        local index = action.index
        if (not gradientPalette[index]) then return oldState end

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = Cryo.Dictionary.join(oldState.gradientEditor, {
                palette = Cryo.List.removeIndex(gradientPalette, index)
            })
        }))
    end,

    --[[
        index: number,
        newName: string
    ]]
    [PluginEnums.StoreActionType.GradientEditor_ChangePaletteColorName] = function(oldState, action)
        local gradientPalette = oldState.gradientEditor.palette
        local index = action.index

        local color = gradientPalette[index]
        if (not color) then return oldState end

        local newColorName = Util.palette.getNewItemName(gradientPalette, action.newName, index)
        if (newColorName == color.name) then return oldState end

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = Cryo.Dictionary.join(oldState.gradientEditor, {
                palette = Cryo.List.replaceIndex(gradientPalette, index, Cryo.Dictionary.join(color, {
                    name = newColorName
                })),
            })
        }))
    end,

    --[[
        index: number,
        offset: number,
    ]]
    [PluginEnums.StoreActionType.GradientEditor_ChangePaletteColorPosition] = function(oldState, action)
        local gradientPalette = oldState.gradientEditor.palette
        local index = action.index
        if (not gradientPalette[index]) then return oldState end

        local newColorIndex = index + action.offset
        if (not gradientPalette[newColorIndex]) then return oldState end

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = Cryo.Dictionary.join(oldState.gradientEditor, {
                palette = Cryo.Dictionary.join(gradientPalette, {
                    [index] = gradientPalette[newColorIndex],
                    [newColorIndex] = gradientPalette[index],
                })
            })
        }))
    end,
}))

---

local themeChanged = Studio.ThemeChanged:Connect(function()
    Store:dispatch({
        type = PluginEnums.StoreActionType.SetTheme,
        theme = Studio.Theme,
    })
end)

plugin.Unloading:Connect(function()
    themeChanged:Disconnect()
end)

return Store