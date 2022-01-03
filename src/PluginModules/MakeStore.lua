local Studio = settings().Studio

---

local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PaletteUtils = require(PluginModules:FindFirstChild("PaletteUtils"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local PluginSettings = require(PluginModules:FindFirstChild("PluginSettings"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local Rodux = require(includes:FindFirstChild("Rodux"))

---

local getNewPaletteName = PaletteUtils.getNewPaletteName
local getNewPaletteColorName = PaletteUtils.getNewPaletteColorName

local pluginStore

return function(plugin)
    if (pluginStore) then return pluginStore end

    local userPalettes = Util.table.deepCopy(PluginSettings.Get(PluginEnums.PluginSettingKey.UserPalettes) or {})
    local userColorSequences = Util.table.deepCopy(PluginSettings.Get(PluginEnums.PluginSettingKey.UserColorSequences) or {})

    for i = 1, #userPalettes do
        local palette = userPalettes[i]

        for j = 1, #palette.colors do
            local color = palette.colors[j]
            local colorValue = color.color

            color.color = Color3.new(colorValue[1], colorValue[2], colorValue[3])
        end
    end

    for i = 1, #userColorSequences do
        local color = userColorSequences[i]
        local colorSequence = color.color
        local keypoints = {}

        for j = 1, #colorSequence do
            local keypoint = colorSequence[j]
            local keypointValue = keypoint[2]

            keypoints[j] = ColorSequenceKeypoint.new(keypoint[1], Color3.new(keypointValue[1], keypointValue[2], keypointValue[3]))
        end

        color.color = ColorSequence.new(keypoints)
    end

    local colorPaneStoreInitialState = {
        theme = Studio.Theme,

        sessionData = {
            editorPage = 1,
            lastSliderPage = {1, 1},
            lastPalettePage = {1, 1},
            lastHueHarmony = 1,
            paletteLayout = "grid",
            
            cbDataClass = 1,
            cbNumDataClasses = 3,

            variationSteps = 10,
        },
        
        colorEditor = {
            authoritativeEditor = "",
            
            quickPalette = {},
            palettes = userPalettes,

            -- comparing this is easier than comparing the actual tables
            lastPaletteModification = os.clock(),
        },

        colorSequenceEditor = {
            snap = PluginSettings.Get(PluginEnums.PluginSettingKey.SnapValue),

            palette = userColorSequences,
            lastPaletteModification = os.clock(),
        }
    }

    local colorPaneStore = Rodux.Store.new(Rodux.createReducer(colorPaneStoreInitialState, {
        --[[
            theme: StudioTheme
        ]]
        [PluginEnums.StoreActionType.SetTheme] = function(state, action)
            state = Util.table.deepCopy(state)
            
            state.theme = action.theme
            return state
        end,

        --[[
            slice: dictionary<any, any>
        ]]
        [PluginEnums.StoreActionType.UpdateSessionData] = function(state, action)
            state = Util.table.deepCopy(state)

            Util.table.merge(state.sessionData, action.slice)
            return state
        end,
        
        --[[
            color: Color3
            editor: PluginEnums.EditorKey?
        ]]
        [PluginEnums.StoreActionType.ColorEditor_SetColor] = function(state, action)
            state = Util.table.deepCopy(state)

            state.colorEditor.color = action.color
            state.colorEditor.authoritativeEditor = action.editor or PluginEnums.EditorKey.Default
            
            return state
        end,

        --[[
            color: Color3
        ]]
        [PluginEnums.StoreActionType.ColorEditor_AddQuickPaletteColor] = function(state, action)
            state = Util.table.deepCopy(state)

            local quickPalette = state.colorEditor.quickPalette
            table.insert(quickPalette, 1, action.color)

            return state
        end,

        --[[
            palette: Palette?
            name: string?
        ]]
        [PluginEnums.StoreActionType.ColorEditor_AddPalette] = function(state, action)
            state = Util.table.deepCopy(state)

            local palettes = state.colorEditor.palettes

            if (action.palette) then
                table.insert(palettes, action.palette)
            else
                local paletteName = getNewPaletteName(palettes, action.name or "New Palette")

                table.insert(palettes, {
                    name = paletteName,
                    colors = {}
                })
            end
            
            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        --[[
            index: number
        ]]
        [PluginEnums.StoreActionType.ColorEditor_RemovePalette] = function(state, action)
            local palettes = state.colorEditor.palettes
            local index = action.index
            if (not palettes[index]) then return state end

            state = Util.table.deepCopy(state)
            palettes = state.colorEditor.palettes

            table.remove(palettes, index)
            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        --[[
            index: number
        ]]
        [PluginEnums.StoreActionType.ColorEditor_DuplicatePalette] = function(state, action)
            local palettes = state.colorEditor.palettes
            local index = action.index

            local palette = palettes[index]
            if (not palette) then return state end

            state = Util.table.deepCopy(state)
            palettes = state.colorEditor.palettes
            palette = palettes[index]

            local newPaletteName = getNewPaletteName(palettes, palette.name)
            local newPalette = Util.table.deepCopy(palette)
            newPalette.name = newPaletteName
            
            table.insert(palettes, newPalette)
            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        --[[
            index: number
            newName: string
        ]]
        [PluginEnums.StoreActionType.ColorEditor_ChangePaletteName] = function(state, action)
            local palettes = state.colorEditor.palettes
            local index = action.index

            local palette = palettes[index]
            if (not palette) then return state end

            local newPaletteName = getNewPaletteName(palettes, action.newName, index)
            if (newPaletteName == palette.name) then return state end

            state = Util.table.deepCopy(state)
            palettes = state.colorEditor.palettes

            palettes[index].name = newPaletteName
            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        --[[
            paletteIndex: number,
            newName: string?
        ]]
        [PluginEnums.StoreActionType.ColorEditor_AddCurrentColorToPalette] = function(state, action)
            local palettes = state.colorEditor.palettes
            local paletteIndex = action.paletteIndex
            
            local palette = palettes[paletteIndex]
            if (not palette) then return state end

            local paletteColors = palette.colors
            local newColorName = getNewPaletteColorName(paletteColors, action.newName or "New Color")

            state = Util.table.deepCopy(state)
            palettes = state.colorEditor.palettes
            palette = palettes[paletteIndex]
            paletteColors = palette.colors

            table.insert(paletteColors, {
                name = newColorName,
                color = state.colorEditor.color,
            })

            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        --[[
            paletteIndex: number,
            colorIndex: number
        ]]
        [PluginEnums.StoreActionType.ColorEditor_RemovePaletteColor] = function(state, action)
            local palettes = state.colorEditor.palettes
            local paletteIndex = action.paletteIndex
            
            local palette = palettes[paletteIndex]
            if (not palette) then return state end

            local paletteColors = palette.colors
            local colorIndex = action.colorIndex

            local color = paletteColors[colorIndex]
            if (not color) then return state end

            state = Util.table.deepCopy(state)
            palettes = state.colorEditor.palettes
            palette = palettes[paletteIndex]

            table.remove(palette.colors, colorIndex)
            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        --[[
            paletteIndex: number,
            colorIndex: number,
            newName: string
        ]]
        [PluginEnums.StoreActionType.ColorEditor_ChangePaletteColorName] = function(state, action)
            local palettes = state.colorEditor.palettes
            local paletteIndex = action.paletteIndex
            
            local palette = palettes[paletteIndex]
            if (not palette) then return state end

            local paletteColors = palette.colors
            local colorIndex = action.colorIndex

            local color = paletteColors[colorIndex]
            if (not color) then return state end

            local newColorName = getNewPaletteColorName(paletteColors, action.newName, colorIndex)
            if (newColorName == color.name) then return state end

            state = Util.table.deepCopy(state)
            palettes = state.colorEditor.palettes
            palette = palettes[paletteIndex]
            paletteColors = palette.colors
            
            paletteColors[colorIndex].name = newColorName
            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        --[[
            paletteIndex: number,
            colorIndex: number,
            offset: number,
        ]]
        [PluginEnums.StoreActionType.ColorEditor_ChangePaletteColorPosition] = function(state, action)
            local palettes = state.colorEditor.palettes
            local paletteIndex = action.paletteIndex
            
            local palette = palettes[paletteIndex]
            if (not palette) then return state end

            local paletteColors = palette.colors
            local colorIndex = action.colorIndex
            local otherColorIndex = colorIndex + action.offset
            if (not (paletteColors[colorIndex] and paletteColors[otherColorIndex])) then return state end

            state = Util.table.deepCopy(state)
            palettes = state.colorEditor.palettes
            palette = palettes[paletteIndex]
            paletteColors = palette.colors

            paletteColors[colorIndex], paletteColors[otherColorIndex] = paletteColors[otherColorIndex], paletteColors[colorIndex]
            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        --[[
            snap: number
        ]]
        [PluginEnums.StoreActionType.ColorSequenceEditor_SetSnapValue] = function(state, action)
            state = Util.table.deepCopy(state)

            state.colorSequenceEditor.snap = action.snap
            return state
        end,

        --[[
            name: string,
            color: ColorSequence,
        ]]
        [PluginEnums.StoreActionType.ColorSequenceEditor_AddPaletteColor] = function(state, action)
            state = Util.table.deepCopy(state)

            local colorSequencePalette = state.colorSequenceEditor.palette
            local newColorName = getNewPaletteColorName(colorSequencePalette, action.name or "New Gradient")

            table.insert(colorSequencePalette, {
                name = newColorName,
                color = action.color,
            })

            state.colorSequenceEditor.lastPaletteModification = os.clock()
            return state
        end,

        --[[
            index: number
        ]]
        [PluginEnums.StoreActionType.ColorSequenceEditor_RemovePaletteColor] = function(state, action)
            local colorSequencePalette = state.colorSequenceEditor.palette
            local index = action.index
            if (not colorSequencePalette[index]) then return state end

            state = Util.table.deepCopy(state)
            colorSequencePalette = state.colorSequenceEditor.palette

            table.remove(colorSequencePalette, action.index)
            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        --[[
            index: number,
            newName: string
        ]]
        [PluginEnums.StoreActionType.ColorSequenceEditor_ChangePaletteColorName] = function(state, action)
            local colorSequencePalette = state.colorSequenceEditor.palette
            local index = action.index

            local color = colorSequencePalette[index]
            if (not color) then return state end

            local newColorName = getNewPaletteColorName(colorSequencePalette, action.newName, index)
            if (newColorName == color.name) then return state end

            state = Util.table.deepCopy(state)
            colorSequencePalette = state.colorSequenceEditor.palette

            colorSequencePalette[index].name = newColorName
            state.colorSequenceEditor.lastPaletteModification = os.clock()
            return state
        end,

        --[[
            index: number,
            offset: number,
        ]]
        [PluginEnums.StoreActionType.ColorSequenceEditor_ChangePaletteColorPosition] = function(state, action)
            local colorSequencePalette = state.colorSequenceEditor.palette
            local index = action.index
            if (not colorSequencePalette[index]) then return state end

            local newColorIndex = index + action.offset
            if (not colorSequencePalette[newColorIndex]) then return state end

            state = Util.table.deepCopy(state)
            colorSequencePalette = state.colorSequenceEditor.palette

            colorSequencePalette[newColorIndex], colorSequencePalette[index] = colorSequencePalette[index], colorSequencePalette[newColorIndex]
            state.colorSequenceEditor.lastPaletteModification = os.clock()
            return state
        end,
    }))

    local themeChanged = Studio.ThemeChanged:Connect(function()
        colorPaneStore:dispatch({
            type = PluginEnums.StoreActionType.SetTheme,
            theme = Studio.Theme,
        })
    end)

    plugin.Unloading:Connect(function()
        themeChanged:Disconnect()
    end)

    pluginStore = colorPaneStore
    return colorPaneStore
end