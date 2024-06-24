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
    __pullSettings: (UserDataSynchroniser) -> (),

    --[[
        Writes the current user data values to the plugin settings.

        @param self The user data synchroniser
    ]]
    __writeSettings: (UserDataSynchroniser) -> (),

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
        __userData: UserData,
        __pluginSettingKey: string,
        __diffCallback: (Values, Values) -> Values,

        __synchroniserId: string,
        __valueChangedSubscription: Signal.Subscription,
        __heartbeat: RBXScriptConnection,
        __lastSyncTime: number,
        __syncing: boolean,
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

UserDataSynchroniser.__pullSettings = function(self: UserDataSynchroniser)
    local userData = self.__userData
    local freshUserData = plugin:GetSetting(self.__pluginSettingKey)
    local freshSynchroniserId: string = freshUserData[Constants.META_UPDATE_SOURCE_KEY]

    if (freshSynchroniserId ~= self.__synchroniserId) then
        -- only update values if the changes came from somewhere else
        local modifiedSettings = self.__diffCallback(userData:getAllValues(), freshUserData)

        for modifiedKey, modifiedValue in pairs(modifiedSettings) do
            userData:setValue(modifiedKey, modifiedValue)
        end
    end
end

UserDataSynchroniser.__writeSettings = function(self: UserDataSynchroniser)
    local writtenUserData = Cryo.Dictionary.join(self.__userData:getAllValues(), {
        [Constants.META_UPDATE_SOURCE_KEY] = self.__synchroniserId
    })

    plugin:SetSetting(self.__pluginSettingKey, writtenUserData)
end

UserDataSynchroniser.new = function(
    userData: UserData,
    pluginSettingKey: string,
    diffCallback: (Values, Values) -> Values,
    initialWrite: boolean?
)
    local self = setmetatable({
        __userData = userData,
        __pluginSettingKey = pluginSettingKey,
        __diffCallback = diffCallback,

        __synchroniserId = HttpService:GenerateGUID(false),
        __valueChangedSubscription = Signal.createSignal():subscribe(function() end),
        __heartbeat = RunService.Heartbeat:Connect(function() end),
        __lastSyncTime = -1,
        __syncing = false,
    }, UserDataSynchroniser)

    -- these connections will be replaced
    self.__valueChangedSubscription:unsubscribe()
    self.__heartbeat:Disconnect()

    if (initialWrite) then
        self:__writeSettings()
    end
    
    self.__valueChangedSubscription = userData.valueChanged:subscribe(function()
        self:__writeSettings()
    end)

    self.__heartbeat = RunService.Heartbeat:Connect(function()
        if (self.__syncing) then return end
        if ((os.clock() - self.__lastSyncTime) < SYNC_FREQUENCY) then return end

        self.__syncing = true
        self:__pullSettings()

        self.__lastSyncTime = os.clock()
        self.__syncing = false
    end)

    plugin.Unloading:Connect(function()
        self.__valueChangedSubscription:unsubscribe()
        self.__heartbeat:Disconnect()
    end)

    return self
end

---

return UserDataSynchroniser