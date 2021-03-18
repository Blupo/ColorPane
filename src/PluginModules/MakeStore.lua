local Studio = settings().Studio

---

local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local PluginSettings = require(PluginModules:FindFirstChild("PluginSettings"))
local util = require(PluginModules:FindFirstChild("util"))

local includes = root:FindFirstChild("includes")
local Rodux = require(includes:FindFirstChild("Rodux"))

---

local MAX_QP_COLORS = 99

local copy = util.copy
local mergeTable = util.mergeTable

local pluginStore

local getNewPaletteName = function(palettes, originalPaletteName, selfIndex)
    local found = false
    local numDuplicates = 0
    local paletteName = originalPaletteName

    repeat
        found = false

        for i = 1, #palettes do
            local palette = palettes[i]

            if ((palette.name == paletteName) and (i ~= selfIndex)) then
                found = true
                numDuplicates = numDuplicates + 1
                paletteName = originalPaletteName .. " (" .. numDuplicates .. ")"
                break
            end
        end
    until (not found)

    return paletteName, numDuplicates
end

local getNewPaletteColorName = function(paletteColors, originalColorName, selfIndex)
    local found = false
    local numDuplicates = 0
    local colorName = originalColorName

    repeat
        found = false

        for i = 1, #paletteColors do
            local color = paletteColors[i]

            if ((color.name == colorName) and (i ~= selfIndex)) then
                found = true
                numDuplicates = numDuplicates + 1
                colorName = originalColorName .. " (" .. numDuplicates .. ")"
                break
            end
        end
    until (not found)

    return colorName, numDuplicates
end

local getPalette = function(palettes, paletteName)
	for i = 1, #palettes do
		local palette = palettes[i]

		if (palette.name == paletteName) then
			return palette, i
		end
	end
end

local getPaletteColorIndex = function(paletteColors, colorName)
    for i = 1, #paletteColors do
        local color = paletteColors[i]

        if (color.name == colorName) then
            return i
        end
    end
end

return function(plugin)
    if (pluginStore) then return pluginStore end

    local userPalettes = copy(PluginSettings.Get(PluginEnums.PluginSettingKey.UserPalettes) or {})

    for i = 1, #userPalettes do
        local palette = userPalettes[i]

        for j = 1, #palette.colors do
            local color = palette.colors[j]
            local colorValue = color.color

            color.color = Color3.new(colorValue[1], colorValue[2], colorValue[3])
        end
    end

    local colorPaneStoreInitialState = {
        theme = Studio.Theme,

        sessionData = {
            editorPage = 1,
            lastSliderPage = 1,
            lastPalettePage = 1,
            lastHueHarmony = 1,
            
            cbDataClass = 1,
            cbNumDataClasses = 3,
        },
        
        colorEditor = {
            authoritativeEditor = "",
            
            quickPalette = {},
            palettes = userPalettes,
            lastPaletteModification = os.clock(), -- this is easier than trying to compare the contents of each palette table
        },

        colorSequenceEditor = {
            snap = PluginSettings.Get(PluginEnums.PluginSettingKey.SnapValue) or 0.1/100,
        }
    }

    local colorPaneStore = Rodux.Store.new(Rodux.createReducer(colorPaneStoreInitialState, {
        [PluginEnums.StoreActionType.SetTheme] = function(state, action)
            state = copy(state)
            
            state.theme = action.theme
            return state
        end,

        [PluginEnums.StoreActionType.UpdateSessionData] = function(state, action)
            state = copy(state)

            mergeTable(state.sessionData, action.slice)
            return state
        end,
        
        [PluginEnums.StoreActionType.ColorEditor_SetColor] = function(state, action)
            state = copy(state)

            state.colorEditor.color = action.color
            state.colorEditor.authoritativeEditor = action.editor or PluginEnums.EditorKey.Default
            
            return state
        end,

        [PluginEnums.StoreActionType.ColorEditor_AddQuickPaletteColor] = function(state, action)
            state = copy(state)

            local quickPalette = state.colorEditor.quickPalette
            table.insert(quickPalette, 1, action.color)

            if (quickPalette[MAX_QP_COLORS + 1]) then
                quickPalette[MAX_QP_COLORS + 1] = nil
            end

            return state
        end,

        [PluginEnums.StoreActionType.ColorEditor_AddPalette] = function(state, action)
            state = copy(state)

            local palettes = state.colorEditor.palettes
            local paletteName = getNewPaletteName(palettes, action.name or "New Palette")

            palettes[#palettes + 1] = {
                name = paletteName,
                colors = {}
            }

            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        [PluginEnums.StoreActionType.ColorEditor_RemovePalette] = function(state, action)
            local _, paletteIndex = getPalette(state.colorEditor.palettes, action.name)
            if (not paletteIndex) then return state end

            state = copy(state)
            table.remove(state.colorEditor.palettes, paletteIndex)

            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        [PluginEnums.StoreActionType.ColorEditor_DuplicatePalette] = function(state, action)
            local palettes = state.colorEditor.palettes

            local _, paletteIndex = getPalette(palettes, action.name)
            if (not paletteIndex) then return state end

            local newPaletteName = getNewPaletteName(palettes, action.name)

            state = copy(state)
            palettes = state.colorEditor.palettes

            local paletteCopy = copy(palettes[paletteIndex])
            paletteCopy.name = newPaletteName

            palettes[#palettes + 1] = paletteCopy
            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        [PluginEnums.StoreActionType.ColorEditor_ChangePaletteName] = function(state, action)
            local _, paletteIndex = getPalette(state.colorEditor.palettes, action.name)
            if (not paletteIndex) then return state end

            local newPaletteName = getNewPaletteName(state.colorEditor.palettes, action.newName, paletteIndex)
            if (newPaletteName == action.name) then return state end

            state = copy(state)
            state.colorEditor.palettes[paletteIndex].name = newPaletteName
            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        [PluginEnums.StoreActionType.ColorEditor_AddPaletteColor] = function(state, action)
            local palette = getPalette(state.colorEditor.palettes, action.palette)
            if (not palette) then return state end

            state = copy(state)
            palette = getPalette(state.colorEditor.palettes, action.palette)

            local paletteColors = palette.colors
            local colorName = getNewPaletteColorName(paletteColors, action.name or "New Color")

            paletteColors[#paletteColors + 1] = {
                name = colorName,
                color = action.color
            }

            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        [PluginEnums.StoreActionType.ColorEditor_AddCurrentColorToPalette] = function(state, action)
            local palette = getPalette(state.colorEditor.palettes, action.palette)
            if (not palette) then return state end

            state = copy(state)
            palette = getPalette(state.colorEditor.palettes, action.palette)

            local paletteColors = palette.colors
            local colorName = getNewPaletteColorName(paletteColors, action.name or "New Color")

            paletteColors[#paletteColors + 1] = {
                name = colorName,
                color = state.colorEditor.color
            }

            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        [PluginEnums.StoreActionType.ColorEditor_RemovePaletteColor] = function(state, action)
            local palette = getPalette(state.colorEditor.palettes, action.palette)
            if (not palette) then return state end

            local paletteColors = palette.colors

            local colorIndex = getPaletteColorIndex(paletteColors, action.name)
            if (not colorIndex) then return state end

            state = copy(state)
            palette = getPalette(state.colorEditor.palettes, action.palette)
            paletteColors = palette.colors

            table.remove(paletteColors, colorIndex)
            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        [PluginEnums.StoreActionType.ColorEditor_ChangePaletteColorName] = function(state, action)
            local palette = getPalette(state.colorEditor.palettes, action.palette)
            if (not palette) then return state end

            local paletteColors = palette.colors

            local colorIndex = getPaletteColorIndex(paletteColors, action.name)
            if (not colorIndex) then return state end

            local newColorName = getNewPaletteColorName(paletteColors, action.newName, colorIndex)
            if (newColorName == action.name) then return state end

            state = copy(state)
            palette = getPalette(state.colorEditor.palettes, action.palette)
            paletteColors = palette.colors

            paletteColors[colorIndex].name = newColorName
            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        [PluginEnums.StoreActionType.ColorEditor_ChangePaletteColorPosition] = function(state, action)
            local palette = getPalette(state.colorEditor.palettes, action.palette)
            if (not palette) then return state end

            local paletteColors = palette.colors

            local colorIndex = getPaletteColorIndex(paletteColors, action.name)
            if (not colorIndex) then return state end

            local newColorIndex = colorIndex + action.offset
            if (not paletteColors[newColorIndex]) then return state end

            state = copy(state)
            palette = getPalette(state.colorEditor.palettes, action.palette)
            paletteColors = palette.colors

            paletteColors[newColorIndex], paletteColors[colorIndex] = paletteColors[colorIndex], paletteColors[newColorIndex]
            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        [PluginEnums.StoreActionType.ColorSequenceEditor_SetSnapValue] = function(state, action)
            state = copy(state)

            state.colorSequenceEditor.snap = action.snap
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