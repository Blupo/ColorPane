--!strict
-- Manages the initialisation and synchronisation of user data

local root = script.Parent.Parent
local Common = root.Common

local CommonIncludes = Common.Includes
local Cryo = require(CommonIncludes.Cryo)
local t = require(CommonIncludes.t)

local CommonModules = Common.Modules
local CommonEnums = require(CommonModules.Enums)
local CommonTypes = require(CommonModules.Types)
local DefaultUserData = require(CommonModules.DefaultUserData)
local PluginProvider = require(CommonModules.PluginProvider)
local UserData = require(CommonModules.UserData)
local UserDataValidators = require(CommonModules.UserDataValidators)
local Util = require(CommonModules.Util)

local Modules = root.Modules
local Constants = require(Modules.Constants)
local UserDataSynchroniser = require(Modules.UserDataSynchroniser)

---

local LEGACY_USERDATA_KEY: string = "ColorPane_Settings"
local LEGACY_USERDATA_BACKUP_KEY: string = "ColorPane_Settings_Backup"

local userDataObj: UserData.UserData
local plugin: Plugin = PluginProvider()

--[[
    Migrates legacy ColorPane user data to the current format.

    @param legacyUserData The user data in an old format
    @return If the migration was successful
    @return The user data in the current format if the migration was successful. Otherwise, an error message.
]]
local migrateLegacyData = function(legacyUserData): (boolean, string | CommonTypes.UserData)
    local isValid: boolean, failReason: string? = t.interface({
        AskNameBeforePaletteCreation = t.optional(UserDataValidators.AskNameBeforePaletteCreation),
        SnapValue = t.optional(UserDataValidators.SnapValue),
        UserPalettes = t.optional(UserDataValidators.UserColorPalettes),
        UserGradients = t.optional(UserDataValidators.__legacy_UserGradients),
    })(legacyUserData)

    if (isValid) then
        local newSettings: CommonTypes.UserData = {
            AskNameBeforePaletteCreation = legacyUserData.AskNameBeforePaletteCreation,
            SnapValue = legacyUserData.SnapValue,
            UserColorPalettes = legacyUserData.UserPalettes,
            UserGradientPalettes = {},
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

            newSettings.UserGradientPalettes = {newPalette}
        end

        return true, newSettings
    else
        return false, failReason::string
    end
end

--[[
    Initialises user data.

    @return If the current user data should be overwritten
    @return The user's data
]]
local initUserData = function(): (CommonTypes.UserData, boolean)
    local defaultUserDataCopy: CommonTypes.UserData = Util.table.deepCopy(DefaultUserData)
    local legacyUserData = plugin:GetSetting(LEGACY_USERDATA_KEY)

    if (legacyUserData) then
        -- migrate old data
        local migrationSuccess: boolean, data = migrateLegacyData(legacyUserData)

        if (not migrationSuccess) then
            error("Could not migrate old ColorPane user data: " .. data::string)
        else
            plugin:SetSetting(LEGACY_USERDATA_BACKUP_KEY, legacyUserData)
            plugin:SetSetting(LEGACY_USERDATA_KEY, nil)

            print("Successfully migrated user data, a backup is available under the setting key "
                .. LEGACY_USERDATA_BACKUP_KEY .. " if something went wrong")
            
            return Cryo.Dictionary.join(defaultUserDataCopy, data::CommonTypes.UserData), true
        end
    end

    local savedUserData = plugin:GetSetting(Constants.USERDATA_KEY)

    if (savedUserData == nil) then
        -- saved data is missing
        return defaultUserDataCopy, true
    elseif (type(savedUserData) ~= "table") then
        -- saved data is invalid
        warn("ColorPane user data is invalid and will be re-created")
        return defaultUserDataCopy, true
    else
        -- check for missing or invalid values
        local modified: boolean = false

        for key: string in pairs(CommonEnums.UserDataKey) do
            local isValid: boolean, failReason: string? = t.optional(UserDataValidators[key])(savedUserData[key])

            if (not isValid) then
                if (key == CommonEnums.UserDataKey.UserColorPalettes) then
                    local palettes = savedUserData[key]
                    local isArrayOfThings: boolean = t.array(t.any)(palettes)

                    -- check if the value is an array
                    if (not isArrayOfThings) then
                        savedUserData[key] = nil
                    else
                        -- check which elements are non-conformant
                        for i = #palettes, 1, -1 do
                            local palette = palettes[i]
                            local isPalette: boolean = UserDataValidators.ColorPalette(palette)

                            if (not isPalette) then
                                table.remove(palettes, i)
                                warn("ColorPane color palette at index " .. i .. " is invalid and will be removed")
                            end
                        end
                    end
                elseif (key == CommonEnums.UserDataKey.UserGradientPalettes) then
                    local palettes = savedUserData[key]
                    local isArrayOfThings: boolean = t.array(t.any)(palettes)

                    -- check if the value is an array
                    if (not isArrayOfThings) then
                        savedUserData[key] = nil
                    else
                        -- check which elements are non-conformant
                        for i = #palettes, 1, -1 do
                            local palette = palettes[i]
                            local isPalette: boolean = UserDataValidators.GradientPalette(palette)

                            if (not isPalette) then
                                table.remove(palettes, i)
                                warn("ColorPane gradient palette at index " .. i .. " is invalid and will be removed")
                            end
                        end
                    end
                else
                    savedUserData[key] = nil
                    warn("ColorPane user data value " .. key .. " is invalid and will be replaced, reason is: " .. failReason::string)
                end

                modified = true
            elseif (savedUserData[key] == nil) then
                modified = true
            end
        end

        if (modified) then
            return Cryo.Dictionary.join(defaultUserDataCopy, savedUserData), true
        else
            return savedUserData, false
        end
    end
end

---

do
    local userData: CommonTypes.UserData, initialWrite: boolean = initUserData()
    userData[Constants.META_UPDATE_SOURCE_KEY] = nil

    userDataObj = UserData.new(userData)
    UserDataSynchroniser(userDataObj, initialWrite)
end

return userDataObj