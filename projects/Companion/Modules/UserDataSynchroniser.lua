--!strict
-- Synchronises ColorPane settings between Studio sessions

local HttpService: HttpService = game:GetService("HttpService")
local RunService: RunService = game:GetService("RunService")

---

local root = script.Parent.Parent
local Common = root.Common

local CommonIncludes = Common.Includes
local Cryo = require(CommonIncludes.Cryo)

local CommonModules = Common.Modules
local CommonTypes = require(CommonModules.Types)
local PluginProvider = require(CommonModules.PluginProvider)
local UserData = require(CommonModules.UserData)
local UserDataDiffs = require(CommonModules.UserDataDiffs)

local Modules = root.Modules
local Constants = require(Modules.Constants)

---

--[[
    The amount of time in seconds between user data syncs.
]]
local SYNC_FREQUENCY: number = 0.5

--[[
    The ID of this synchroniser, used to identify external modifications.
]]
local SYNCHRONISER_ID: string = HttpService:GenerateGUID(false)

local heartbeat: RBXScriptConnection
local lastSyncTime: number = -1
local plugin: Plugin = PluginProvider()
local syncing: boolean = false
local currentUserData: UserData.UserData

--[[
    Pulls user data from the plugin settings,
    and updates the current user data values accordingly.
]]
local pullSettings = function()
    local freshUserData = plugin:GetSetting(Constants.USERDATA_KEY)
    local freshSynchroniserId: string = freshUserData[Constants.META_UPDATE_SOURCE_KEY]

    if (freshSynchroniserId ~= SYNCHRONISER_ID) then
        -- only update values if the changes came from somewhere else
        local modifiedSettings = UserDataDiffs.GetModifiedValues(currentUserData:getAllValues(), freshUserData)

        for modifiedKey, modifiedValue in pairs(modifiedSettings) do
            currentUserData:setValue(modifiedKey, modifiedValue)
        end
    end
end

--[[
    Writes the current user data values to the plugin settings.

    @param bypassPull Bypass pulling settings before writing them
]]
local writeSettings = function(bypassPull: boolean?)
    if (not bypassPull) then
        pullSettings()
    end

    local writtenUserData = Cryo.Dictionary.join(currentUserData:getAllValues(), {
        [Constants.META_UPDATE_SOURCE_KEY] = SYNCHRONISER_ID
    })

    plugin:SetSetting(Constants.USERDATA_KEY, writtenUserData)
end

--[[
    Hooks a UserData object for synchronisation with plugin settings.

    @param userData The user data to synchronise
    @param initialWrite If the saved user data should be overwritten by `userData`
]]
return function(userData: UserData.UserData, initialWrite: boolean)
    if (currentUserData) then
        error("User data is already being synchronised!")
    end

    currentUserData = userData

    if (initialWrite) then
        writeSettings(true)
    end

    local valueChangedSubscription = userData.valueChanged:subscribe(function(_: CommonTypes.UserDataValue)
        writeSettings()
    end)

    heartbeat = RunService.Heartbeat:Connect(function()
        if (syncing) then return end
        if ((os.clock() - lastSyncTime) < SYNC_FREQUENCY) then return end

        syncing = true
        pullSettings()

        lastSyncTime = os.clock()
        syncing = false
    end)

    plugin.Unloading:Connect(function()
        valueChangedSubscription:unsubscribe()
        heartbeat:Disconnect()
    end)
end