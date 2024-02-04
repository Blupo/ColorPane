local Studio: Studio = settings().Studio

---

local root = script.Parent.Parent

local PluginModules = root.PluginModules
local PluginEnums = require(PluginModules.PluginEnums)
local PluginProvider = require(PluginModules.PluginProvider)
local Util = require(PluginModules.Util)

local includes = root.includes
local Cryo = require(includes.Cryo)
local Rodux = require(includes.RoactRodux.Rodux)

---

local plugin: Plugin? = PluginProvider()
assert(plugin, Util.makeBugMessage("Plugin object is missing"))

---

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
    },

    gradientEditor = {
        snap = 0.1/100,
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