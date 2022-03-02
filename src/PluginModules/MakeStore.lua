local Studio = settings().Studio

---

local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local PluginSettings = require(PluginModules:FindFirstChild("PluginSettings"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local Color = require(includes:FindFirstChild("Color")).Color
local Rodux = require(includes:FindFirstChild("Rodux"))
local state = require(includes:FindFirstChild("state"))

---

local pluginStore

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
            lastToolPage = {1, 1},
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
        },

        gradientEditor = {
            snap = PluginSettings.Get(PluginEnums.PluginSettingKey.SnapValue),
            palette = userGradients,
        }
    }

    local colorPaneStore = Rodux.Store.new(Rodux.createReducer(colorPaneStoreInitialState, {
        --[[
            theme: StudioTheme
        ]]
        [PluginEnums.StoreActionType.SetTheme] = function(oldState, action)
            return state.produce(oldState, function(draftState)
                draftState.theme = action.theme
            end)
        end,

        --[[
            slice: dictionary<any, any>
        ]]
        [PluginEnums.StoreActionType.UpdateSessionData] = function(oldState, action)
            return state.produce(oldState, function(draftState)
                Util.table.merge(draftState.sessionData, action.slice)
            end)
        end,
        
        --[[
            color: Color
            editor: PluginEnums.EditorKey?
        ]]
        [PluginEnums.StoreActionType.ColorEditor_SetColor] = function(oldState, action)
            return state.produce(oldState, function(draftState)
                draftState.colorEditor.color = action.color
                draftState.colorEditor.authoritativeEditor = action.editor or PluginEnums.EditorKey.Default
            end)
        end,

        --[[
            color: Color
        ]]
        [PluginEnums.StoreActionType.ColorEditor_AddQuickPaletteColor] = function(oldState, action)
            return state.produce(oldState, function(draftState)
                local quickPalette = draftState.colorEditor.quickPalette
                state.table.insert(quickPalette, 1, action.color)
            end)
        end,

        --[[
            palette: Palette?
            name: string?
        ]]
        [PluginEnums.StoreActionType.ColorEditor_AddPalette] = function(oldState, action)
            return state.produce(oldState, function(draftState)
                local palettes = draftState.colorEditor.palettes

                if (action.palette) then
                    state.table.append(palettes, action.palette)
                else
                    local paletteName = Util.palette.getNewItemName(palettes, action.name or "New Palette")

                    state.table.append(palettes, {
                        name = paletteName,
                        colors = {}
                    })
                end
            end)
        end,

        --[[
            index: number
        ]]
        [PluginEnums.StoreActionType.ColorEditor_RemovePalette] = function(oldState, action)
            return state.produce(oldState, function(draftState)
                local palettes = draftState.colorEditor.palettes
                local index = action.index
                if (not palettes[index]) then return end

                state.table.remove(palettes, index)
            end)
        end,

        --[[
            index: number
        ]]
        [PluginEnums.StoreActionType.ColorEditor_DuplicatePalette] = function(oldState, action)
            return state.produce(oldState, function(draftState)
                local palettes = draftState.colorEditor.palettes
                local index = action.index

                local palette = palettes[index]
                if (not palette) then return end

                local newPaletteName = Util.palette.getNewItemName(palettes, palette.name)
                local newPalette = Util.table.deepCopy(oldState.colorEditor.palettes[index])
                newPalette.name = newPaletteName
                
                state.table.append(palettes, newPalette)
            end)
        end,

        --[[
            index: number
            newName: string
        ]]
        [PluginEnums.StoreActionType.ColorEditor_ChangePaletteName] = function(oldState, action)
            return state.produce(oldState, function(draftState)
                local palettes = draftState.colorEditor.palettes
                local index = action.index

                local palette = palettes[index]
                if (not palette) then return end

                local newPaletteName = Util.palette.getNewItemName(palettes, action.newName, index)
                if (newPaletteName == palette.name) then return end

                palettes[index].name = newPaletteName
            end)
        end,

        --[[
            paletteIndex: number,
            newName: string?
        ]]
        [PluginEnums.StoreActionType.ColorEditor_AddCurrentColorToPalette] = function(oldState, action)
            return state.produce(oldState, function(draftState)
                local palettes = draftState.colorEditor.palettes
                local paletteIndex = action.paletteIndex
                
                local palette = palettes[paletteIndex]
                if (not palette) then return end

                local paletteColors = palette.colors
                local newColorName = Util.palette.getNewItemName(paletteColors, action.newName or "New Color")

                state.table.append(paletteColors, {
                    name = newColorName,
                    color = draftState.colorEditor.color:toColor3(),
                })
            end)
        end,

        --[[
            paletteIndex: number,
            colorIndex: number
        ]]
        [PluginEnums.StoreActionType.ColorEditor_RemovePaletteColor] = function(oldState, action)
            return state.produce(oldState, function(draftState)
                local palettes = draftState.colorEditor.palettes
                local paletteIndex = action.paletteIndex
                
                local palette = palettes[paletteIndex]
                if (not palette) then return end

                local paletteColors = palette.colors
                local colorIndex = action.colorIndex

                local color = paletteColors[colorIndex]
                if (not color) then return end

                state.table.remove(palette.colors, colorIndex)
            end)
        end,

        --[[
            paletteIndex: number,
            colorIndex: number,
            newName: string
        ]]
        [PluginEnums.StoreActionType.ColorEditor_ChangePaletteColorName] = function(oldState, action)
            state.produce(oldState, function(draftState)
                local palettes = draftState.colorEditor.palettes
                local paletteIndex = action.paletteIndex
                
                local palette = palettes[paletteIndex]
                if (not palette) then return end

                local paletteColors = palette.colors
                local colorIndex = action.colorIndex

                local color = paletteColors[colorIndex]
                if (not color) then return end

                local newColorName = Util.palette.getNewItemName(paletteColors, action.newName, colorIndex)
                if (newColorName == color.name) then return end

                paletteColors[colorIndex].name = newColorName
            end)
        end,

        --[[
            paletteIndex: number,
            colorIndex: number,
            offset: number,
        ]]
        [PluginEnums.StoreActionType.ColorEditor_ChangePaletteColorPosition] = function(oldState, action)
            return state.produce(oldState, function(draftState)
                local palettes = draftState.colorEditor.palettes
                local paletteIndex = action.paletteIndex
                
                local palette = palettes[paletteIndex]
                if (not palette) then return end

                local paletteColors = palette.colors
                local colorIndex = action.colorIndex
                local otherColorIndex = colorIndex + action.offset
                if (not (paletteColors[colorIndex] and paletteColors[otherColorIndex])) then return end

                paletteColors[colorIndex], paletteColors[otherColorIndex] = paletteColors[otherColorIndex], paletteColors[colorIndex]
            end)
        end,

        [PluginEnums.StoreActionType.GradientEditor_ResetState] = function(oldState)
            return state.produce(oldState, function(draftState)

                for k in state.iter.pairs(draftState.gradientEditor) do
                    if (
                        (k == "snap") or
                        (k == "palette")
                    ) then
                        continue
                    else
                        draftState.gradientEditor[k] = nil
                    end
                end
            end)
        end,

        --[[
            keypoints: array<GradientKeypoint>?
            selectedKeypoint: number?
        ]]
        [PluginEnums.StoreActionType.GradientEditor_SetKeypoints] = function(oldState, action)
            return state.produce(oldState, function(draftState)
                local gradientEditorState = draftState.gradientEditor

                gradientEditorState.keypoints = action.keypoints or gradientEditorState.keypoints
                gradientEditorState.selectedKeypoint = action.selectedKeypoint or gradientEditorState.selectedKeypoint

                if (gradientEditorState.selectedKeypoint == -1) then
                    gradientEditorState.selectedKeypoint = nil
                end

                gradientEditorState.displayKeypoints = Util.generateFullKeypointList(
                    state.draft.getRef(gradientEditorState.keypoints),
                    gradientEditorState.colorSpace,
                    gradientEditorState.hueAdjustment,
                    gradientEditorState.precision
                )
            end)
        end,

        --[[
            keypoints: array<GradientKeypoint>?,
            colorSpace: string?,
            hueAdjustment: string?,
            precision: number?
        ]]
        [PluginEnums.StoreActionType.GradientEditor_SetGradient] = function(oldState, action)
            return state.produce(oldState, function(draftState)
                Util.table.merge(draftState.gradientEditor, {
                    keypoints = action.keypoints,
                    colorSpace = action.colorSpace,
                    hueAdjustment = action.hueAdjustment,
                    precision = action.precision,
                })

                draftState.gradientEditor.displayKeypoints = Util.generateFullKeypointList(
                    state.draft.getRef(draftState.gradientEditor.keypoints),
                    draftState.gradientEditor.colorSpace,
                    draftState.gradientEditor.hueAdjustment,
                    draftState.gradientEditor.precision or 0
                )
            end)
        end,

        --[[
            snap: number
        ]]
        [PluginEnums.StoreActionType.GradientEditor_SetSnapValue] = function(oldState, action)
            return state.produce(oldState, function(draftState)
                draftState.gradientEditor.snap = action.snap
            end)
        end,

        --[[
            name: string

            keypoints: array<GradientKeypoint>
            colorSpace: string?
            hueAdjustment: string?
            precision: number?
        ]]
        [PluginEnums.StoreActionType.GradientEditor_AddPaletteColor] = function(oldState, action)
            return state.produce(oldState, function(draftState)
                local gradientPalette = draftState.gradientEditor.palette
                local newColorName = Util.palette.getNewItemName(gradientPalette, action.name or "New Gradient")

                state.table.append(gradientPalette, {
                    name = newColorName,

                    keypoints = action.keypoints,
                    colorSpace = action.colorSpace,
                    hueAdjustment = action.hueAdjustment,
                    precision = action.precision,
                })
            end)
        end,

        --[[
            index: number
        ]]
        [PluginEnums.StoreActionType.GradientEditor_RemovePaletteColor] = function(oldState, action)
            return state.produce(oldState, function(draftState)
                local gradientPalette = draftState.gradientEditor.palette
                local index = action.index
                if (not gradientPalette[index]) then return end

                state.table.remove(gradientPalette, action.index)
            end)
        end,

        --[[
            index: number,
            newName: string
        ]]
        [PluginEnums.StoreActionType.GradientEditor_ChangePaletteColorName] = function(oldState, action)
            return state.produce(oldState, function(draftState)
                local gradientPalette = draftState.gradientEditor.palette
                local index = action.index

                local color = gradientPalette[index]
                if (not color) then return end

                local newColorName = Util.palette.getNewItemName(gradientPalette, action.newName, index)
                if (newColorName == color.name) then return end

                gradientPalette[index].name = newColorName
            end)
        end,

        --[[
            index: number,
            offset: number,
        ]]
        [PluginEnums.StoreActionType.GradientEditor_ChangePaletteColorPosition] = function(oldState, action)
            return state.produce(oldState, function(draftState)
                local gradientPalette = draftState.gradientEditor.palette
                local index = action.index
                if (not gradientPalette[index]) then return end

                local newColorIndex = index + action.offset
                if (not gradientPalette[newColorIndex]) then return end

                gradientPalette[newColorIndex], gradientPalette[index] = gradientPalette[index], gradientPalette[newColorIndex]
            end)
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