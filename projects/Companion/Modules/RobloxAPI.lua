--!strict

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

---

local root = script.Parent.Parent
local Common = root.Common

local CommonIncludes = Common.Includes
local Promise = require(CommonIncludes.Promise)
local Signal = require(CommonIncludes.Signal)

local CommonModules = Common.Modules
local PluginProvider = require(CommonModules.PluginProvider)

local Modules = root.Modules
local ColorAPIData = require(Modules.ColorAPIData)
local Enums = require(Modules.Enums)
local ManagedUserData = require(Modules.ManagedUserData)

---

local ROOT_URL = "https://setup.rbxcdn.com/"

--[[
    The endpoint to retrieve the current version of Roblox Studio.
]]
local STUDIO_VERSION_ENDPOINT = "versionQTStudio"

--[[
    The endpoint to retrieve API dumps.
]]
local API_DATA_ENDPOINT = "%s-API-Dump.json"

local plugin: Plugin = PluginProvider()
local apiData
local requestInProgress = false
local companionUserData = ManagedUserData.Companion
local valueChangedSubscription

local dataRequestStartedSignal: Signal.Signal<nil>, fireDataRequestStarted: Signal.FireSignal<nil> = Signal.createSignal()
local dataRequestFinishedSignal: Signal.Signal<boolean>, fireDataRequestFinished: Signal.FireSignal<boolean> = Signal.createSignal()

---

local RobloxAPI = {}
RobloxAPI.DataRequestStarted = dataRequestStartedSignal
RobloxAPI.DataRequestFinished = dataRequestFinishedSignal

RobloxAPI.IsAvailable = function()
    return (apiData and true or false)
end

RobloxAPI.IsRequestRunning = function()
    return requestInProgress
end

RobloxAPI.GetData = function()
    if (apiData or requestInProgress) then return end

    requestInProgress = true
    fireDataRequestStarted()

    Promise.new(function(resolve, reject)
        local cachedAPIData: string? = companionUserData:getValue(Enums.CompanionUserDataKey.RobloxApiDump)

        if (cachedAPIData) then
            resolve(cachedAPIData, true)
            return
        end

        if (RunService:IsEdit()) then
            -- get the current Roblox Studio version
            local studioVersion: string

            local studioVersionResponse = HttpService:RequestAsync({
                Url = ROOT_URL .. STUDIO_VERSION_ENDPOINT,
                Method = "GET",
            })

            if (studioVersionResponse.Success) then
                if (not studioVersionResponse.Body) then
                    reject("Empty body")
                    return
                end

                studioVersion = studioVersionResponse.Body
            else
                reject(studioVersionResponse.StatusMessage)
                return
            end

            -- get the API dump itself
            local jsonAPIDataResponse = HttpService:RequestAsync({
                Url = ROOT_URL .. string.format(API_DATA_ENDPOINT, studioVersion),
                Method = "GET",
            })

            if (jsonAPIDataResponse.Success) then
                local apiDump = jsonAPIDataResponse.Body

                if (apiDump) then
                    resolve(apiDump, false)
                else
                    reject("Empty body")
                end
            else
                reject(jsonAPIDataResponse.StatusMessage)
            end
        else
            reject("No cached API data")
        end
    end):andThen(function(api, usedCache)
        api = usedCache and api or HttpService:JSONDecode(api)

        if (not usedCache) then
            companionUserData:setValue(Enums.CompanionUserDataKey.RobloxApiDump, api)
            companionUserData:setValue(Enums.CompanionUserDataKey.RobloxApiDumpLastUpdated, DateTime.now().UnixTimestamp)
        end

        ColorAPIData.init(api)

        apiData = api
        fireDataRequestFinished(true)
    end, function()
        fireDataRequestFinished(false)
    end):finally(function()
        requestInProgress = false
    end)
end

---

valueChangedSubscription = companionUserData.valueChanged:subscribe(function(value)
    if (value.Key ~= Enums.CompanionUserDataKey.CacheColorPropertiesAPIData) then return end

    if (value.Value) then
        if (not apiData) then return end

        companionUserData:setValue(Enums.CompanionUserDataKey.RobloxApiDump, apiData)
        companionUserData:setValue(Enums.CompanionUserDataKey.RobloxApiDumpLastUpdated, DateTime.now().UnixTimestamp)
    else
        companionUserData:setValue(Enums.CompanionUserDataKey.RobloxApiDump, nil)
        companionUserData:setValue(Enums.CompanionUserDataKey.RobloxApiDumpLastUpdated, nil)
    end
end)

plugin.Unloading:Connect(function()
    valueChangedSubscription:unsubscribe()
end)

return RobloxAPI