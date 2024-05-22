-- TODO
-- ColorPane store
local Studio: Studio = settings().Studio

---

local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local CommonEnums = require(CommonModules.Enums)
local PluginProvider = require(CommonModules.PluginProvider)

local CommonIncludes = Common.Includes
local Cryo = require(CommonIncludes.Cryo)
local Rodux = require(CommonIncludes.RoactRodux.Rodux)

local Includes = root.Includes
local Color = require(Includes.Color).Color

local Modules = root.Modules
local Enums = require(Modules.Enums)
local ManagedUserData = require(Modules.ManagedUserData)
local Util = require(Modules.Util)

---

local plugin: Plugin = PluginProvider()

local initialState = {
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
        palettes = {},
    },

    gradientEditor = {
        snap = ManagedUserData:getValue(CommonEnums.UserDataKey.SnapValue),
        palettes = {},
    }
}

---

-- we need to convert the palettes to use the correct formats
do
    local userColorPalettes = ManagedUserData:getValue(CommonEnums.UserDataKey.UserColorPalettes)
    local userGradientPalettes = ManagedUserData:getValue(CommonEnums.UserDataKey.UserGradientPalettes)

    for i = 1, #userColorPalettes do
        local palette = userColorPalettes[i]
    
        for j = 1, #palette.colors do
            local color = palette.colors[j]
            local colorValue = color.color
    
            -- we use Color3s because we only need to display the colors,
            -- not manipulate them
            color.color = Color3.new(table.unpack(colorValue))
        end
    end

    for i = 1, #userGradientPalettes do
        local palette = userGradientPalettes[i]
        local gradients = palette.gradients

        for j = 1, #gradients do
            local gradient = gradients[j]
            local keypoints = gradient.keypoints
        
            for k = 1, #keypoints do
                local keypoint = keypoints[k]
        
                keypoints[k] = {
                    time = keypoint.time, 
                    color = Color.new(table.unpack(keypoint.color))
                }
            end
        end
    end

    initialState.colorEditor.palettes = userColorPalettes
    initialState.gradientEditor.palettes = userGradientPalettes
end

local Store = Rodux.Store.new(Rodux.createReducer(initialState, {
    --[[
        theme: StudioTheme
    ]]
    [Enums.StoreActionType.SetTheme] = function(oldState, action)
        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            theme = action.theme
        }))
    end,

    --[[
        slice: dictionary<any, any>
    ]]
    [Enums.StoreActionType.UpdateSessionData] = function(oldState, action)
        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            sessionData = Cryo.Dictionary.join(oldState.sessionData, action.slice)
        }))
    end,
    
    --[[
        color: Color
        editor: Enums.EditorKey?
    ]]
    [Enums.StoreActionType.ColorEditor_SetColor] = function(oldState, action)
        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            colorEditor = Cryo.Dictionary.join(oldState.colorEditor, {
                color = action.color,
                authoritativeEditor = action.editor or Enums.EditorKey.Default
            })
        }))
    end,

    --[[
        color: Color
    ]]
    [Enums.StoreActionType.ColorEditor_AddQuickPaletteColor] = function(oldState, action)
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
    [Enums.StoreActionType.ColorEditor_AddPalette] = function(oldState, action)
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
    [Enums.StoreActionType.ColorEditor_RemovePalette] = function(oldState, action)
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
    [Enums.StoreActionType.ColorEditor_DuplicatePalette] = function(oldState, action)
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
    [Enums.StoreActionType.ColorEditor_ChangePaletteName] = function(oldState, action)
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
    [Enums.StoreActionType.ColorEditor_AddCurrentColorToPalette] = function(oldState, action)
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
    [Enums.StoreActionType.ColorEditor_RemovePaletteColor] = function(oldState, action)
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
    [Enums.StoreActionType.ColorEditor_ChangePaletteColorName] = function(oldState, action)
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
    [Enums.StoreActionType.ColorEditor_ChangePaletteColorPosition] = function(oldState, action)
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

    [Enums.StoreActionType.GradientEditor_ResetState] = function(oldState)
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
    [Enums.StoreActionType.GradientEditor_SetKeypoints] = function(oldState, action)
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
    [Enums.StoreActionType.GradientEditor_SetGradient] = function(oldState, action)
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
    [Enums.StoreActionType.GradientEditor_SetSnapValue] = function(oldState, action)
        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = Cryo.Dictionary.join(oldState.gradientEditor, {
                snap = action.snap
            })
        }))
    end,
}))

---

local themeChanged = Studio.ThemeChanged:Connect(function()
    Store:dispatch({
        type = Enums.StoreActionType.SetTheme,
        theme = Studio.Theme,
    })
end)

plugin.Unloading:Connect(function()
    themeChanged:Disconnect()
end)

return Store