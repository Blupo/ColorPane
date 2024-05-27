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

---

local Studio: Studio = settings().Studio

local plugin: Plugin = PluginProvider()
local themeChanged: RBXScriptConnection

local initialState: {[any]: any} = {
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

plugin.Unloading:Connect(function()
    themeChanged:Disconnect()
end)

return Store