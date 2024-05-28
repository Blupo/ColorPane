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

type Color = Types.ColorPaletteColor
type ColorPalette = Types.ColorPalette

--[[
    Rodux reducers for color-editor-related updates.
]]
return {
    --[[
        Updates the color editor's working color.
        
        ```
        action = {
            color: Color,
            editor: Enums.EditorKey?
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.ColorEditor_SetColor] = function(oldState: table, action: table): table
        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            colorEditor = Cryo.Dictionary.join(oldState.colorEditor, {
                color = action.color,
                authoritativeEditor = action.editor or Enums.EditorKey.Default
            })
        }))
    end,

    --[[
        Adds a color to the color editor's quick palette.

        ```
        action = {
            color: Color
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.ColorEditor_AddQuickPaletteColor] = function(oldState: table, action: table): table
        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            colorEditor = Cryo.Dictionary.join(oldState.colorEditor, {
                quickPalette = Cryo.List.join({action.color}, oldState.colorEditor.quickPalette)
            })
        }))
    end,

    --[[
        Adds a new or pre-made palette to the list of color palettes.

        ```
        action = {
            name: string?,
            palette: ColorPalette?
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.ColorEditor_AddPalette] = function(oldState: table, action: table): table
        local newPalette: ColorPalette
        local palettes: {ColorPalette} = oldState.colorEditor.palettes

        if (action.palette) then
            newPalette = action.palette
        else
            local desiredPaletteName: string = action.name or "New Palette"
            local actualPaletteName: string = Util.palette.getNewItemName(palettes, desiredPaletteName)

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
        Removes a color palette.

        ```
        action = {
            paletteIndex: number
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.ColorEditor_RemovePalette] = function(oldState: table, action: table): table
        local palettes: {ColorPalette} = oldState.colorEditor.palettes
        local paletteIndex: number = action.paletteIndex
        if (not palettes[paletteIndex]) then return oldState end

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            colorEditor = Cryo.Dictionary.join(oldState.colorEditor, {
                palettes = Cryo.List.removeIndex(palettes, paletteIndex)
            })
        }))
    end,

    --[[
        Duplicates a color palette and adds it to the color palette list.

        ```
        action = {
            paletteIndex: number
        }
        ```
        
        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.ColorEditor_DuplicatePalette] = function(oldState: table, action: table): table
        local palettes: {ColorPalette} = oldState.colorEditor.palettes
        local paletteIndex: number = action.paletteIndex

        local palette: ColorPalette = palettes[paletteIndex]
        if (not palette) then return oldState end

        local matchStart: number? = string.find(palette.name, "%s*%(%d+%)$")
        local nameWithoutCounter: string = if (matchStart) then string.sub(palette.name, 1, matchStart - 1) else palette.name

        local newPaletteName: string = Util.palette.getNewItemName(palettes, nameWithoutCounter)
        local newPalette: ColorPalette = Util.table.deepCopy(palette)
        newPalette.name = newPaletteName

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            colorEditor = Cryo.Dictionary.join(oldState.colorEditor, {
                palettes = Cryo.List.join(palettes, {newPalette})
            })
        }))
    end,

    --[[
        Modifies the name of a color palette.

        ```
        action = {
            paletteIndex: number,
            newName: string
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.ColorEditor_ChangePaletteName] = function(oldState: table, action: table): table
        local palettes: {ColorPalette} = oldState.colorEditor.palettes
        local paletteIndex: number = action.paletteIndex

        local palette: ColorPalette = palettes[paletteIndex]
        if (not palette) then return oldState end

        local newPaletteName: string = Util.palette.getNewItemName(palettes, action.newName, paletteIndex)
        if (newPaletteName == palette.name) then return oldState end

        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            colorEditor = Cryo.Dictionary.join(oldState.colorEditor, {
                palettes = Cryo.List.replaceIndex(palettes, paletteIndex, Cryo.Dictionary.join(palette, {
                    name = newPaletteName
                }))
            })
        }))
    end,

    --[[
        Adds the current working color to a color palette.

        ```
        action = {
            paletteIndex: number,
            newName: string?
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.ColorEditor_AddCurrentColorToPalette] = function(oldState: table, action: table): table
        local palettes: {ColorPalette} = oldState.colorEditor.palettes
        local paletteIndex: number = action.paletteIndex
        
        local palette: ColorPalette = palettes[paletteIndex]
        if (not palette) then return oldState end

        local paletteColors: {Color} = palette.colors
        local newColorName: string = Util.palette.getNewItemName(paletteColors, action.newName or "New Color")

        local newColor: Color = {
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
        Removes a color from a color palette.

        ```
        action = {
            paletteIndex: number,
            colorIndex: number
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.ColorEditor_RemovePaletteColor] = function(oldState: table, action: table): table
        local palettes: {ColorPalette} = oldState.colorEditor.palettes
        local paletteIndex: number = action.paletteIndex
        
        local palette: ColorPalette = palettes[paletteIndex]
        if (not palette) then return oldState end

        local paletteColors: {Color} = palette.colors
        local colorIndex = action.colorIndex

        local color: Color = paletteColors[colorIndex]
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
        Modifies the name of a color in a color palette.

        ```
        action = {
            paletteIndex: number,
            colorIndex: number,
            newName: string
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.ColorEditor_ChangePaletteColorName] = function(oldState: table, action: table): table
        local palettes: {ColorPalette} = oldState.colorEditor.palettes
        local paletteIndex: number = action.paletteIndex
        
        local palette: ColorPalette = palettes[paletteIndex]
        if (not palette) then return oldState end

        local paletteColors: {Color} = palette.colors
        local colorIndex: number = action.colorIndex

        local color: Color = paletteColors[colorIndex]
        if (not color) then return oldState end

        local newColorName: string = Util.palette.getNewItemName(paletteColors, action.newName, colorIndex)
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
        Modifies the position of a color in a color palette.

        ```
        action = {
            paletteIndex: number,
            colorIndex: number,
            offset: number,
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.ColorEditor_ChangePaletteColorPosition] = function(oldState: table, action: table): table
        local palettes: {ColorPalette} = oldState.colorEditor.palettes
        local paletteIndex: number = action.paletteIndex
        
        local palette: ColorPalette = palettes[paletteIndex]
        if (not palette) then return oldState end

        local paletteColors: {Color} = palette.colors
        local colorIndex: number = action.colorIndex
        local otherColorIndex: number = colorIndex + action.offset
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
}