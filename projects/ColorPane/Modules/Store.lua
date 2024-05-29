--!strict

local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local CommonEnums = require(CommonModules.Enums)
local PluginProvider = require(CommonModules.PluginProvider)

local CommonIncludes = Common.Includes
local Rodux = require(CommonIncludes.RoactRodux.Rodux)

local Includes = root.Includes
local Color = require(Includes.Color).Color

local Modules = root.Modules
local Enums = require(Modules.Enums)
local ManagedUserData = require(Modules.ManagedUserData)
local StoreReducers = require(Modules.StoreReducers)
local Types = require(Modules.Types)
local UpstreamUserData = require(Modules.UpstreamUserData)
local Util = require(Modules.Util)

---

type table = Types.table

local Studio: Studio = settings().Studio

local plugin: Plugin = PluginProvider()
local themeChanged: RBXScriptConnection
local valueChanged
local upstreamAvailabilityChanged

local convertColorPaletteToColor3s = function(palette: table)
    for i = 1, #palette.colors do
        local color = palette.colors[i]
        local colorValue = color.color

        -- we use Color3s because we only need to display the colors,
        -- not manipulate them
        color.color = Color3.new(table.unpack(colorValue))
    end
end

local convertGradientPaletteToColors = function(palette: table)
    for i = 1, #palette.gradients do
        local gradient = palette.gradients[i]
        local keypoints = gradient.keypoints
    
        for j = 1, #keypoints do
            local keypoint = keypoints[j]
    
            keypoints[j] = {
                time = keypoint.time, 
                color = Color.new(table.unpack(keypoint.color))
            }
        end
    end
end

local initialState: {[any]: any} = {
    theme = Studio.Theme,
    upstreamAvailable = UpstreamUserData.IsAvailable(),

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
        convertColorPaletteToColor3s(userColorPalettes[i])
    end

    for i = 1, #userGradientPalettes do
        convertGradientPaletteToColors(userGradientPalettes[i])
    end

    initialState.colorEditor.palettes = userColorPalettes
    initialState.gradientEditor.palettes = userGradientPalettes
end

--[[
    ColorPane store
]]
local Store = Rodux.Store.new(Rodux.createReducer(initialState, StoreReducers))

---

themeChanged = Studio.ThemeChanged:Connect(function()
    Store:dispatch({
        type = Enums.StoreActionType.SetTheme,
        theme = Studio.Theme,
    })
end)

valueChanged = ManagedUserData.valueChanged:subscribe(function(value)
    local key: string = value.Key

    if (key == CommonEnums.UserDataKey.SnapValue) then
        Store:dispatch({
            type = Enums.StoreActionType.GradientEditor_SetSnapValue,
            snap = value.Value,
        })
    elseif (key == CommonEnums.UserDataKey.UserColorPalettes) then
        local palettes: table = Util.table.deepCopy(value.Value)

        for i = 1, #palettes do
            convertColorPaletteToColor3s(palettes[i])
        end

        Store:dispatch({
            type = Enums.StoreActionType.ColorEditor_SetPalettes,
            palettes = palettes,
        })
    elseif (key == CommonEnums.UserDataKey.UserGradientPalettes) then
        local palettes: table = Util.table.deepCopy(value.Value)

        for i = 1, #palettes do
            convertGradientPaletteToColors(palettes[i])
        end

        Store:dispatch({
            type = Enums.StoreActionType.GradientEditor_SetPalettes,
            palettes = palettes,
        })
    end
end)

upstreamAvailabilityChanged = UpstreamUserData.AvailabilityChanged:subscribe(function(available: boolean)
    Store:dispatch({
        type = Enums.StoreActionType.UpstreamAvailabilityChanged,
        available = available,
    })
end)

plugin.Unloading:Connect(function()
    themeChanged:Disconnect()
    valueChanged:unsubscribe()
    upstreamAvailabilityChanged:unsubscribe()
end)

return Store