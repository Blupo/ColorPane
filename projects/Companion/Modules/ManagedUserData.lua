--!strict
--[[
    Manages the initialisation and synchronisation of user data
]]

local root = script.Parent.Parent
local Common = root.Common

local CommonIncludes = Common.Includes
local Cryo = require(CommonIncludes.Cryo)
local t = require(CommonIncludes.t)

local CommonModules = Common.Modules
local ColorPaneUserDataDefaultValues = require(CommonModules.ColorPaneUserDataDefaultValues)
local ColorPaneUserDataDiffs = require(CommonModules.ColorPaneUserDataDiffs)
local ColorPaneUserDataFactory = require(CommonModules.ColorPaneUserDataFactory)
local ColorPaneUserDataValidators = require(CommonModules.ColorPaneUserDataValidators)
local CommonEnums = require(CommonModules.Enums)
local CommonTypes = require(CommonModules.Types)
local PluginProvider = require(CommonModules.PluginProvider)
local UserData = require(CommonModules.UserData)
local Util = require(CommonModules.Util)

local Modules = root.Modules
local CompanionUserDataDefaultValues = require(Modules.CompanionUserDataDefaultValues)
local Constants = require(Modules.Constants)
local Enums = require(Modules.Enums)
local Types = require(Modules.Types)
local UserDataSynchroniser = require(Modules.UserDataSynchroniser)

---

local LEGACY_USERDATA_KEY: string = "ColorPane_Settings"
local LEGACY_USERDATA_BACKUP_KEY: string = "ColorPane_Settings_Backup"

local colorPaneUserDataObj: UserData.UserData
local companionUserDataObj: UserData.UserData
local plugin: Plugin = PluginProvider()

--[[
    Migrates legacy ColorPane user data to the current format,
    and returns the user data values.

    @param legacyUserData The user data in an old format
    @return The set of ColorPane user data values
    @return The set of Companion user data values
]]
local migrateLegacyData = function(legacyUserData): (CommonTypes.ColorPaneUserData, Types.CompanionUserData)
    -- we shouldn't directly modify this data
    legacyUserData = Util.table.deepCopy(legacyUserData)
    
    local isValid: boolean, failReason: string? = t.interface({
        AskNameBeforePaletteCreation = t.optional(ColorPaneUserDataValidators.AskNameBeforePaletteCreation),
        SnapValue = t.optional(ColorPaneUserDataValidators.SnapValue),
        UserPalettes = t.optional(ColorPaneUserDataValidators.UserColorPalettes),
        UserGradients = t.optional(ColorPaneUserDataValidators.__userGradients),
        AutoLoadColorProperties = t.optional(t.boolean),
        CacheAPIData = t.optional(t.boolean),
    })(legacyUserData)

    if (isValid) then
        local newColorPaneValues: CommonTypes.ColorPaneUserData = {
            AskNameBeforePaletteCreation = legacyUserData.AskNameBeforePaletteCreation,
            SnapValue = legacyUserData.SnapValue,
            UserColorPalettes = legacyUserData.UserPalettes,
            UserGradientPalettes = {},
        }

        local newCompanionValues: Types.CompanionUserData = {
            AutoLoadColorPropertiesAPIData = legacyUserData.AutoLoadColorProperties,
            CacheColorPropertiesAPIData = legacyUserData.CacheAPIData,
        }
        
        if (legacyUserData.UserGradients) then
            local newPalette = {
                name = "(Transferred from ColorPane)",
                gradients = {}
            }

            for i, gradient in ipairs(legacyUserData.UserGradients) do
                for _, keypoint in ipairs(gradient.keypoints) do
                    keypoint.time = keypoint.Time
                    keypoint.color = keypoint.Color

                    keypoint.Time = nil
                    keypoint.Color = nil
                end

                newPalette.gradients[i] = gradient
            end

            newColorPaneValues.UserGradientPalettes = {newPalette}
        end

        return newColorPaneValues, newCompanionValues
    else
        error("Could not migrate old ColorPane user data: " .. failReason::string)
    end
end

--[[
    Initialises ColorPane user data.

    @param userData The current ColorPane user data
    @return The user's ColorPane data
    @return If the current ColorPane data should be overwritten
]]
local initColorPaneUserData = function(userData, colorPaneDefaultUserDataValues): (CommonTypes.ColorPaneUserData, boolean)
    if (userData == nil) then
        return colorPaneDefaultUserDataValues, true
    elseif (type(userData) ~= "table") then
        warn("ColorPane user data is invalid and will be re-created")
        return colorPaneDefaultUserDataValues, true
    else
        -- check for missing or invalid values
        local modified: boolean = false

        for key: string in pairs(CommonEnums.ColorPaneUserDataKey) do
            local isValid: boolean, failReason: string? =
                t.optional(ColorPaneUserDataValidators[key])(userData[key])

            if (not isValid) then
                if (key == CommonEnums.ColorPaneUserDataKey.UserColorPalettes) then
                    local palettes = userData[key]
                    local isArrayOfThings: boolean = t.array(t.any)(palettes)

                    -- check if the value is an array
                    if (not isArrayOfThings) then
                        userData[key] = nil
                    else
                        -- check which elements are non-conformant
                        for i = #palettes, 1, -1 do
                            local palette = palettes[i]
                            local isPalette: boolean = ColorPaneUserDataValidators.ColorPalette(palette)

                            if (not isPalette) then
                                table.remove(palettes, i)
                                warn("ColorPane color palette at index " .. i .. " is invalid and will be removed")
                            end
                        end
                    end
                elseif (key == CommonEnums.ColorPaneUserDataKey.UserGradientPalettes) then
                    local palettes = userData[key]
                    local isArrayOfThings: boolean = t.array(t.any)(palettes)

                    -- check if the value is an array
                    if (not isArrayOfThings) then
                        userData[key] = nil
                    else
                        -- check which elements are non-conformant
                        for i = #palettes, 1, -1 do
                            local palette = palettes[i]
                            local isPalette: boolean = ColorPaneUserDataValidators.GradientPalette(palette)

                            if (not isPalette) then
                                table.remove(palettes, i)
                                warn("ColorPane gradient palette at index " .. i .. " is invalid and will be removed")
                            end
                        end
                    end
                else
                    userData[key] = nil
                    warn("ColorPane user data value " .. key .. " is invalid and will be replaced, reason is: " .. failReason::string)
                end

                modified = true
            elseif (userData[key] == nil) then
                modified = true
            end
        end

        if (modified) then
            return Cryo.Dictionary.join(colorPaneDefaultUserDataValues, userData), true
        else
            return userData, false
        end
    end
end

--[[
    Initialises Companion user data.

    @param userData The current Companion user data
    @return The user's Companion data
    @return If the current Companion data should be overwritten
]]
local initCompanionUserData = function(userData, companionDefaultUserDataValues): (Types.CompanionUserData, boolean)
    if (userData == nil) then
        return companionDefaultUserDataValues, false
    elseif (type(userData) ~= "table") then
        warn("ColorPane user data is invalid and will be re-created")
        return companionDefaultUserDataValues, false
    else
        -- check for missing or invalid values
        local modified: boolean = false

        for key: string in pairs(CommonEnums.ColorPaneUserDataKey) do
            local isValid: boolean, failReason: string? =
                t.optional(ColorPaneUserDataValidators[key])(userData[key])

            if (not isValid) then
                userData[key] = nil
                modified = true
                warn("Companion user data value " .. key .. " is invalid and will be replaced, reason is: " .. failReason::string)
            elseif (userData[key] == nil) then
                modified = true
            end
        end

        if (modified) then
            return Cryo.Dictionary.join(companionDefaultUserDataValues, userData), true
        else
            return userData, false
        end
    end  
end

--[[
    Initialises user data.

    @return The user's ColorPane data
    @return If the current ColorPane data should be overwritten
    @return The user's Companion data
    @return If the current Companion user data should be overwritten
]]
local initUserData = function(): (CommonTypes.ColorPaneUserData, boolean, Types.CompanionUserData, boolean)
    local colorPaneDefaultUserDataValues = Util.table.deepCopy(ColorPaneUserDataDefaultValues)
    local companionDefaultUserDataValues = Util.table.deepCopy(CompanionUserDataDefaultValues)
    local legacyUserData = plugin:GetSetting(LEGACY_USERDATA_KEY)

    -- if there's legacy user data, we'll migrate it
    -- and skip the rest of the initialisation
    if (legacyUserData) then
        local colorPaneUserData, companionUserData = migrateLegacyData(legacyUserData)

        plugin:SetSetting(LEGACY_USERDATA_BACKUP_KEY, legacyUserData)
        plugin:SetSetting(LEGACY_USERDATA_KEY, nil)

        print("Successfully migrated user data, a backup is available under the setting key "
            .. LEGACY_USERDATA_BACKUP_KEY .. " if something went wrong")
        
        return
            Cryo.Dictionary.join(colorPaneDefaultUserDataValues, colorPaneUserData), true,
            Cryo.Dictionary.join(companionDefaultUserDataValues, companionUserData), true
    end

    -- the rest of the initialisation
    local savedColorPaneUserData = plugin:GetSetting(Constants.COLORPANE_USERDATA_KEY)
    local savedCompanionUserData = plugin:GetSetting(Constants.COMPANION_USERDATA_KEY)

    local colorPaneUserData, overwriteColorPaneUserData =
        initColorPaneUserData(savedColorPaneUserData, colorPaneDefaultUserDataValues)

    local companionUserData, overwriteCompanionUserData =
        initCompanionUserData(savedCompanionUserData, companionDefaultUserDataValues)
    
    return
        colorPaneUserData, overwriteColorPaneUserData,
        companionUserData, overwriteCompanionUserData
end

---

do
    local colorPaneUserData, colorPaneInitialWrite,
        companionUserData, companionInitialWrite = initUserData()

    colorPaneUserData[Constants.META_UPDATE_SOURCE_KEY] = nil
    companionUserData[Constants.META_UPDATE_SOURCE_KEY] = nil

    colorPaneUserDataObj = ColorPaneUserDataFactory(colorPaneUserData)

    companionUserDataObj = UserData.new(
        Enums.CompanionUserDataKey,

        {
            [Enums.CompanionUserDataKey.AutoLoadColorPropertiesAPIData] = t.boolean,
            [Enums.CompanionUserDataKey.CacheColorPropertiesAPIData] = t.boolean,
        },

        {},
        companionUserData
    )

    UserDataSynchroniser.new(
        colorPaneUserDataObj,
        Constants.COLORPANE_USERDATA_KEY,
        ColorPaneUserDataDiffs.GetModifiedValues,
        colorPaneInitialWrite
    )

    UserDataSynchroniser.new(
        companionUserDataObj,
        Constants.COMPANION_USERDATA_KEY,

        function(this, that)
            return {
                [Enums.CompanionUserDataKey.AutoLoadColorPropertiesAPIData] = if
                    this[Enums.CompanionUserDataKey.AutoLoadColorPropertiesAPIData] == that[Enums.CompanionUserDataKey.AutoLoadColorPropertiesAPIData]
                then nil else that[Enums.CompanionUserDataKey.AutoLoadColorPropertiesAPIData],

                [Enums.CompanionUserDataKey.CacheColorPropertiesAPIData] = if
                    this[Enums.CompanionUserDataKey.CacheColorPropertiesAPIData] == that[Enums.CompanionUserDataKey.CacheColorPropertiesAPIData]
                then nil else that[Enums.CompanionUserDataKey.CacheColorPropertiesAPIData],
            }
        end,

        companionInitialWrite
    )
end

return {
    ColorPane = colorPaneUserDataObj,
    Companion = companionUserDataObj,
}