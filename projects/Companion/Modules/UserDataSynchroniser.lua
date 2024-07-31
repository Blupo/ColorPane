--!strict
--[[
    Class for UserData synchronisation with
    plugin settings.
]]

local HttpService: HttpService = game:GetService("HttpService")
local RunService: RunService = game:GetService("RunService")

---

local root = script.Parent.Parent
local Common = root.Common

local CommonIncludes = Common.Includes
local Cryo = require(CommonIncludes.Cryo)
local Signal = require(CommonIncludes.Signal)

local CommonModules = Common.Modules
local PluginProvider = require(CommonModules.PluginProvider)
local Types = require(CommonModules.Types)
local UserData = require(CommonModules.UserData)

local Modules = root.Modules
local Constants = require(Modules.Constants)

---

type UserData = UserData.UserData
type Values = Types.UserDataValues

type UserDataSynchroniserImpl = {
    __index: UserDataSynchroniserImpl,

    --[[
        Pulls user data from the plugin settings,
        and updates the current user data values accordingly.

        @param self The user data synchroniser
    ]]
    _pullSettings: (UserDataSynchroniser) -> (),

    --[[
        Writes the current user data values to the plugin settings.

        @param self The user data synchroniser
    ]]
    _writeSettings: (UserDataSynchroniser) -> (),

    --[[
        Creates a new synchroniser for a UserData.

        @param userData The UserData object
        @param pluginSettingKey The plugin setting key to write settings to
        @param diffCallback Callback to determine which values to use when two versions of the data differ
        @param initialWrite If the saved user data should be overwritten by `userData` 
        @return A user data synchroniser
    ]]
    new: (UserData, string, (Values, Values) -> Values, boolean?) -> UserDataSynchroniser,
}

export type UserDataSynchroniser = typeof(setmetatable(
    {}::{
        _userData: UserData,
        _pluginSettingKey: string,
        _diffCallback: (Values, Values) -> Values,

        _synchroniserId: string,
        _valueChangedSubscription: Signal.Subscription,
        _heartbeat: RBXScriptConnection,
        _lastSyncTime: number,
        _syncing: boolean,
    },
    
    {}::UserDataSynchroniserImpl
))

---

--[[
    The amount of time in seconds between user data syncs.
]]
local SYNC_FREQUENCY: number = 0.5

local plugin: Plugin = PluginProvider()

---

local UserDataSynchroniser: UserDataSynchroniserImpl = {}::UserDataSynchroniserImpl
UserDataSynchroniser.__index = UserDataSynchroniser

UserDataSynchroniser._pullSettings = function(self: UserDataSynchroniser)
    local userData = self._userData
    local freshUserData = plugin:GetSetting(self._pluginSettingKey)
    local freshSynchroniserId: string = freshUserData[Constants.META_UPDATE_SOURCE_KEY]

    if (freshSynchroniserId ~= self._synchroniserId) then
        -- only update values if the changes came from somewhere else
        local modifiedSettings = self._diffCallback(userData:getAllValues(), freshUserData)

        for modifiedKey, modifiedValue in pairs(modifiedSettings) do
            userData:setValue(modifiedKey, modifiedValue)
        end
    end
end

UserDataSynchroniser._writeSettings = function(self: UserDataSynchroniser)
    local writtenUserData = Cryo.Dictionary.join(self._userData:getAllValues(), {
        [Constants.META_UPDATE_SOURCE_KEY] = self._synchroniserId
    })

    plugin:SetSetting(self._pluginSettingKey, writtenUserData)
end

UserDataSynchroniser.new = function(
    userData: UserData,
    pluginSettingKey: string,
    diffCallback: (Values, Values) -> Values,
    initialWrite: boolean?
)
    local self = setmetatable({
        _userData = userData,
        _pluginSettingKey = pluginSettingKey,
        _diffCallback = diffCallback,

        _synchroniserId = HttpService:GenerateGUID(false),
        _valueChangedSubscription = Signal.createSignal():subscribe(function() end),
        _heartbeat = RunService.Heartbeat:Connect(function() end),
        _lastSyncTime = -1,
        _syncing = false,
    }, UserDataSynchroniser)

    -- these connections will be replaced
    self._valueChangedSubscription:unsubscribe()
    self._heartbeat:Disconnect()

    if (initialWrite) then
        self:_writeSettings()
    end
    
    self._valueChangedSubscription = userData.valueChanged:subscribe(function()
        self:_writeSettings()
    end)

    self._heartbeat = RunService.Heartbeat:Connect(function()
        if (self._syncing) then return end
        if ((os.clock() - self._lastSyncTime) < SYNC_FREQUENCY) then return end

        self._syncing = true
        self:_pullSettings()

        self._lastSyncTime = os.clock()
        self._syncing = false
    end)

    plugin.Unloading:Connect(function()
        self._valueChangedSubscription:unsubscribe()
        self._heartbeat:Disconnect()
    end)

    return self
end

---

return UserDataSynchroniser