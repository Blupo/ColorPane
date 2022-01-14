local Studio = settings().Studio

---

local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PaletteUtils = require(PluginModules:FindFirstChild("PaletteUtils"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local PluginSettings = require(PluginModules:FindFirstChild("PluginSettings"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local Color = require(includes:FindFirstChild("Color")).Color
local Rodux = require(includes:FindFirstChild("Rodux"))

---

local pluginStore

local getNewPaletteName = PaletteUtils.getNewPaletteName
local getNewPaletteColorName = PaletteUtils.getNewPaletteColorName

---

return function(plugin)
    if (pluginStore) then return pluginStore end

    local userPalettes = Util.table.deepCopy(PluginSettings.Get(PluginEnums.PluginSettingKey.UserPalettes) or {})
    local userGradients = Util.table.deepCopy(PluginSettings.Get(PluginEnums.PluginSettingKey.UserGradients) or {})

    for i = 1, #userPalettes do
        local palette = userPalettes[i]

        for j = 1, #palette.colors do
            local color = palette.colors[j]
            local colorValue = color.color

            color.color = Color3.new(colorValue[1], colorValue[2], colorValue[3])
        end
    end

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
            lastPaletteModification = os.clock(),
        },

        gradientEditor = {
            snap = PluginSettings.Get(PluginEnums.PluginSettingKey.SnapValue),
            palette = userGradients,
            lastPaletteModification = os.clock(),
        }
    }

    local colorPaneStore = Rodux.Store.new(Rodux.createReducer(colorPaneStoreInitialState, {
        --[[
            theme: StudioTheme
        ]]
        [PluginEnums.StoreActionType.SetTheme] = function(state, action)
            state = Util.table.deepCopyPreserveColors(state)
            
            state.theme = action.theme
            return state
        end,

        --[[
            slice: dictionary<any, any>
        ]]
        [PluginEnums.StoreActionType.UpdateSessionData] = function(state, action)
            state = Util.table.deepCopyPreserveColors(state)

            Util.table.merge(state.sessionData, action.slice)
            return state
        end,
        
        --[[
            color: Color
            editor: PluginEnums.EditorKey?
        ]]
        [PluginEnums.StoreActionType.ColorEditor_SetColor] = function(state, action)
            state = Util.table.deepCopyPreserveColors(state)

            state.colorEditor.color = action.color
            state.colorEditor.authoritativeEditor = action.editor or PluginEnums.EditorKey.Default
            
            return state
        end,

        --[[
            color: Color
        ]]
        [PluginEnums.StoreActionType.ColorEditor_AddQuickPaletteColor] = function(state, action)
            state = Util.table.deepCopyPreserveColors(state)

            local quickPalette = state.colorEditor.quickPalette
            table.insert(quickPalette, 1, action.color)

            return state
        end,

        --[[
            palette: Palette?
            name: string?
        ]]
        [PluginEnums.StoreActionType.ColorEditor_AddPalette] = function(state, action)
            state = Util.table.deepCopyPreserveColors(state)

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

            state = Util.table.deepCopyPreserveColors(state)
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

            state = Util.table.deepCopyPreserveColors(state)
            palettes = state.colorEditor.palettes
            palette = palettes[index]

            local newPaletteName = getNewPaletteName(palettes, palette.name)
            local newPalette = Util.table.deepCopyPreserveColors(palette)
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

            state = Util.table.deepCopyPreserveColors(state)
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

            state = Util.table.deepCopyPreserveColors(state)
            palettes = state.colorEditor.palettes
            palette = palettes[paletteIndex]
            paletteColors = palette.colors

            table.insert(paletteColors, {
                name = newColorName,
                color = state.colorEditor.color:toColor3(),
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

            state = Util.table.deepCopyPreserveColors(state)
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

            state = Util.table.deepCopyPreserveColors(state)
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

            state = Util.table.deepCopyPreserveColors(state)
            palettes = state.colorEditor.palettes
            palette = palettes[paletteIndex]
            paletteColors = palette.colors

            paletteColors[colorIndex], paletteColors[otherColorIndex] = paletteColors[otherColorIndex], paletteColors[colorIndex]
            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        [PluginEnums.StoreActionType.GradientEditor_ResetState] = function(state)
            state = Util.table.deepCopyPreserveColors(state)

            state.gradientEditor = {
                snap = state.gradientEditor.snap,
                palettes = state.gradientEditor.palettes,
                lastPaletteModification = state.gradientEditor.lastPaletteModification,
            }

            return state
        end,

        --[[
            keypoints: array<GradientKeypoint>?
            selectedKeypoint: number?
        ]]
        [PluginEnums.StoreActionType.GradientEditor_SetKeypoints] = function(state, action)
            state = Util.table.deepCopyPreserveColors(state)

            state.gradientEditor.keypoints = action.keypoints or state.gradientEditor.keypoints
            state.gradientEditor.selectedKeypoint = action.selectedKeypoint or state.gradientEditor.selectedKeypoint

            if (state.gradientEditor.selectedKeypoint == -1) then
                state.gradientEditor.selectedKeypoint = nil
            end

            state.gradientEditor.displayKeypoints = Util.generateFullKeypointList(
                state.gradientEditor.keypoints,
                state.gradientEditor.colorSpace,
                state.gradientEditor.hueAdjustment,
                state.gradientEditor.precision
            )

            return state
        end,

        --[[
            keypoints: array<GradientKeypoint>?,
            colorSpace: string?,
            hueAdjustment: string?,
            precision: number?
        ]]
        [PluginEnums.StoreActionType.GradientEditor_SetGradient] = function(state, action)
            state = Util.table.deepCopyPreserveColors(state)

            Util.table.merge(state.gradientEditor, {
                keypoints = action.keypoints,
                colorSpace = action.colorSpace,
                hueAdjustment = action.hueAdjustment,
                precision = action.precision,
            })

            state.gradientEditor.displayKeypoints = Util.generateFullKeypointList(
                state.gradientEditor.keypoints,
                state.gradientEditor.colorSpace,
                state.gradientEditor.hueAdjustment,
                state.gradientEditor.precision or 0
            )

            return state
        end,

        --[[
            snap: number
        ]]
        [PluginEnums.StoreActionType.GradientEditor_SetSnapValue] = function(state, action)
            state = Util.table.deepCopyPreserveColors(state)

            state.gradientEditor.snap = action.snap
            return state
        end,

        --[[
            name: string

            keypoints: array<GradientKeypoint>
            colorSpace: string?
            hueAdjustment: string?
            precision: number?
        ]]
        [PluginEnums.StoreActionType.GradientEditor_AddPaletteColor] = function(state, action)
            state = Util.table.deepCopyPreserveColors(state)

            local gradientPalette = state.gradientEditor.palette
            local newColorName = getNewPaletteColorName(gradientPalette, action.name or "New Gradient")

            table.insert(gradientPalette, {
                name = newColorName,

                keypoints = action.keypoints,
                colorSpace = action.colorSpace,
                hueAdjustment = action.hueAdjustment,
                precision = action.precision,
            })

            state.gradientEditor.lastPaletteModification = os.clock()
            return state
        end,

        --[[
            index: number
        ]]
        [PluginEnums.StoreActionType.GradientEditor_RemovePaletteColor] = function(state, action)
            local gradientPalette = state.gradientEditor.palette
            local index = action.index
            if (not gradientPalette[index]) then return state end

            state = Util.table.deepCopyPreserveColors(state)
            gradientPalette = state.gradientEditor.palette

            table.remove(gradientPalette, action.index)
            state.colorEditor.lastPaletteModification = os.clock()
            return state
        end,

        --[[
            index: number,
            newName: string
        ]]
        [PluginEnums.StoreActionType.GradientEditor_ChangePaletteColorName] = function(state, action)
            local gradientPalette = state.gradientEditor.palette
            local index = action.index

            local color = gradientPalette[index]
            if (not color) then return state end

            local newColorName = getNewPaletteColorName(gradientPalette, action.newName, index)
            if (newColorName == color.name) then return state end

            state = Util.table.deepCopyPreserveColors(state)
            gradientPalette = state.gradientEditor.palette

            gradientPalette[index].name = newColorName
            state.gradientEditor.lastPaletteModification = os.clock()
            return state
        end,

        --[[
            index: number,
            offset: number,
        ]]
        [PluginEnums.StoreActionType.GradientEditor_ChangePaletteColorPosition] = function(state, action)
            local gradientPalette = state.gradientEditor.palette
            local index = action.index
            if (not gradientPalette[index]) then return state end

            local newColorIndex = index + action.offset
            if (not gradientPalette[newColorIndex]) then return state end

            state = Util.table.deepCopyPreserveColors(state)
            gradientPalette = state.gradientEditor.palette

            gradientPalette[newColorIndex], gradientPalette[index] = gradientPalette[index], gradientPalette[newColorIndex]
            state.gradientEditor.lastPaletteModification = os.clock()
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