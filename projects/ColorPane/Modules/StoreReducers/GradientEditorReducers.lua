--!strict

local root = script.Parent.Parent.Parent
local Common = root.Common

local CommonIncludes = Common.Includes
local Cryo = require(CommonIncludes.Cryo)

local Modules = root.Modules
local Enums = require(Modules.Enums)
local Types = require(Modules.Types)
local Util = require(Modules.Util)

---

type table = Types.table

type Gradient = Types.GradientPaletteGradient
type GradientPalette = Types.GradientPalette

---

--[[
    Rodux reducers for gradient-editor-related updates.
]]
return {
    --[[
        Clears out the working gradient's information from
        the gradient editor.

        @param oldState The previous state
        @return The next state
    ]]
    [Enums.StoreActionType.GradientEditor_ResetState] = function(oldState: table, _: table): table
        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = {
                snap = oldState.gradientEditor.snap,
                palette = oldState.gradientEditor.palette,
            }
        }))
    end,

    --[[
        Updates the working gradient's list of keypoints.

        ```
        action = {
            keypoints: {GradientKeypoint}?,
            selectedKeypoint: number?
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.GradientEditor_SetKeypoints] = function(oldState: table, action: table): table
        local gradientEditorState: table = oldState.gradientEditor

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
        Updates the working gradient's information.

        ```
        action = {
            keypoints: {GradientKeypoint}?,
            colorSpace: MixableColorType?,
            hueAdjustment: HueAdjustment?,
            precision: number?
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.GradientEditor_SetGradient] = function(oldState: table, action: table): table
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
        Updates the gradient editor's keypoint snap value.

        ```
        action = {
            snap: number
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.GradientEditor_SetSnapValue] = function(oldState: table, action: table): table
        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = Cryo.Dictionary.join(oldState.gradientEditor, {
                snap = action.snap
            })
        }))
    end,

    --[[
        Adds a new or pre-made palette to the list of gradient palettes.

        ```
        action = {
            name: string?,
            palette: GradientPalette?
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.GradientEditor_AddPalette] = function(oldState: table, action: table): table
        local newPalette: GradientPalette
        local palettes: {GradientPalette} = oldState.gradientEditor.palettes

        if (action.palette) then
            newPalette = action.palette
        else
            local desiredPaletteName: string = action.name or "New Palette"
            local actualPaletteName: string = Util.palette.getNewItemName(palettes, desiredPaletteName)

            newPalette = {
                name = actualPaletteName,
                gradients = {}
            }
        end

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = Cryo.Dictionary.join(oldState.gradientEditor, {
                palettes = Cryo.List.join(palettes, {newPalette})
            })
        }))
    end,

    --[[
        Removes a gradient palette.

        ```
        action = {
            index: number
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.GradientEditor_RemovePalette] = function(oldState: table, action: table): table
        local palettes: {GradientPalette} = oldState.gradientEditor.palettes
        local index: number = action.index
        if (not palettes[index]) then return oldState end

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = Cryo.Dictionary.join(oldState.gradientEditor, {
                palettes = Cryo.List.removeIndex(palettes, index)
            })
        }))
    end,

    --[[
        Duplicates a gradient palette and adds it to the gradient palette list.

        ```
        action = {
            index: number
        }
        ```
        
        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.GradientEditor_DuplicatePalette] = function(oldState: table, action: table): table
        local palettes: {GradientPalette} = oldState.gradientEditor.palettes
        local index: number = action.index

        local palette: GradientPalette = palettes[index]
        if (not palette) then return oldState end

        local matchStart: number? = string.find(palette.name, "%s*%(%d+%)$")
        local nameWithoutCounter: string = if (matchStart) then string.sub(palette.name, 1, matchStart - 1) else palette.name

        local newPaletteName: string = Util.palette.getNewItemName(palettes, nameWithoutCounter)
        local newPalette: GradientPalette = Util.table.deepCopy(palette)
        newPalette.name = newPaletteName

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = Cryo.Dictionary.join(oldState.gradientEditor, {
                palettes = Cryo.List.join(palettes, {newPalette})
            })
        }))
    end,

    --[[
        Modifies the name of a gradient palette.

        ```
        action = {
            index: number,
            newName: string
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.GradientEditor_ChangePaletteName] = function(oldState: table, action: table): table
        local palettes: {GradientPalette} = oldState.gradientEditor.palettes
        local index: number = action.index

        local palette: GradientPalette = palettes[index]
        if (not palette) then return oldState end

        local newPaletteName: string = Util.palette.getNewItemName(palettes, action.newName, index)
        if (newPaletteName == palette.name) then return oldState end

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = Cryo.Dictionary.join(oldState.gradientEditor, {
                palettes = Cryo.List.replaceIndex(palettes, index, Cryo.Dictionary.join(palette, {
                    name = newPaletteName
                }))
            })
        }))
    end,

    --[[
        Adds the current working gradient to a gradient palette.

        ```
        action = {
            index: number,
            newName: string?
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.GradientEditor_AddCurrentGradientToPalette] = function(oldState: table, action: table): table
        local palettes: {GradientPalette} = oldState.gradientEditor.palettes
        local index: number = action.index
        
        local palette: GradientPalette = palettes[index]
        if (not palette) then return oldState end

        local paletteGradients: {Gradient} = palette.gradients
        local newGradientName: string = Util.palette.getNewItemName(paletteGradients, action.newName or "New Color")

        local newGradient: Gradient = {
            name = newGradientName,

            keypoints = oldState.gradientEditor.keypoints,
            colorSpace = oldState.gradientEditor.colorSpace,
            hueAdjustment = oldState.gradientEditor.hueAdjustment,
            precision = oldState.gradientEditor.precision,
        }

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = Cryo.Dictionary.join(oldState.gradientEditor, {
                palettes = Cryo.List.replaceIndex(palettes, index, Cryo.Dictionary.join(palette, {
                    gradients = Cryo.List.join(paletteGradients, {newGradient})
                }))
            })
        }))
    end,

    --[[
        Removes a gradient from a gradient palette.

        ```
        action = {
            paletteIndex: number,
            gradientIndex: number
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.GradientEditor_RemovePaletteGradient] = function(oldState: table, action: table): table
        local palettes: {GradientPalette} = oldState.gradientEditor.palettes
        local paletteIndex: number = action.paletteIndex
        
        local palette: GradientPalette = palettes[paletteIndex]
        if (not palette) then return oldState end

        local paletteGradients: {Gradient} = palette.gradients
        local gradientIndex: number = action.gradientIndex

        local gradient: Gradient = paletteGradients[gradientIndex]
        if (not gradient) then return oldState end

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = Cryo.Dictionary.join(oldState.gradientEditor, {
                palettes = Cryo.List.replaceIndex(palettes, paletteIndex, Cryo.Dictionary.join(palette, {
                    gradients = Cryo.List.removeIndex(paletteGradients, gradientIndex)
                }))
            })
        }))
    end,

    --[[
        Modifies the name of a gradient in a gradient palette.

        ```
        action = {
            paletteIndex: number,
            gradientIndex: number,
            newName: string
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.GradientEditor_ChangePaletteGradientName] = function(oldState: table, action: table): table
        local palettes: {GradientPalette} = oldState.gradientEditor.palettes
        local paletteIndex: number = action.paletteIndex
        
        local palette: GradientPalette = palettes[paletteIndex]
        if (not palette) then return oldState end

        local paletteGradients: {Gradient} = palette.gradients
        local gradientIndex: number = action.gradientIndex

        local gradient: Gradient = paletteGradients[gradientIndex]
        if (not gradient) then return oldState end

        local newGradientName: string = Util.palette.getNewItemName(paletteGradients, action.newName, gradientIndex)
        if (newGradientName == gradient.name) then return oldState end

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = Cryo.Dictionary.join(oldState.gradientEditor, {
                palettes = Cryo.List.replaceIndex(palettes, paletteIndex, Cryo.Dictionary.join(palette, {
                    gradients = Cryo.List.replaceIndex(paletteGradients, gradientIndex, Cryo.Dictionary.join(gradient, {
                        name = newGradientName
                    }))
                }))
            })
        }))
    end,

    --[[
        Modifies the position of a gradient in a gradient palette.

        ```
        action = {
            paletteIndex: number,
            gradientIndex: number,
            offset: number,
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.GradientEditor_ChangePaletteGradientPosition] = function(oldState: table, action: table): table
        local palettes: {GradientPalette} = oldState.gradientEditor.palettes
        local paletteIndex: number = action.paletteIndex
        
        local palette: GradientPalette = palettes[paletteIndex]
        if (not palette) then return oldState end

        local paletteGradients: {Gradient} = palette.gradients
        local gradientIndex: number = action.gradientIndex
        local otherGradientIndex: number = gradientIndex + action.offset
        if (not (paletteGradients[gradientIndex] and paletteGradients[otherGradientIndex])) then return oldState end

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            gradientEditor = Cryo.Dictionary.join(oldState.gradientEditor, {
                palettes = Cryo.List.replaceIndex(palettes, paletteIndex, Cryo.Dictionary.join(palette, {
                    gradients = Cryo.Dictionary.join(paletteGradients, {
                        [gradientIndex] = paletteGradients[otherGradientIndex],
                        [otherGradientIndex] = paletteGradients[gradientIndex]
                    })
                }))
            })
        }))
    end,
}