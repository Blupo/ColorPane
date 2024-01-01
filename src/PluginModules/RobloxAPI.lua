local HttpService: HttpService = game:GetService("HttpService")
local RunService: RunService = game:GetService("RunService")

---

local root = script.Parent.Parent

local PluginModules = root.PluginModules
local ColorAPIData = require(PluginModules.ColorAPIData)
local PluginEnums = require(PluginModules.PluginEnums)
local PluginSettings = require(PluginModules.PluginSettings)

local includes = root.includes
local Promise = require(includes.Promise)
local Signal = require(includes.Signal)

---

local API_URL: string = "https://setup.rbxcdn.com/"
local STUDIO_VERSION_ENDPOINT: string = "versionQTStudio"
local API_DATA_ENDPOINT: string = "%s-API-Dump.json"

local apiData
local requestInProgress: boolean = false

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
        local cachedAPIData = PluginSettings.GetCachedRobloxAPIData()

        if (cachedAPIData) then
            resolve(cachedAPIData, true)
            return
        end

        if (RunService:IsEdit()) then
            local studioVersion

            local studioVersionResponse = HttpService:RequestAsync({
                Url = API_URL .. STUDIO_VERSION_ENDPOINT,
                Method = "GET",
            })

            if (studioVersionResponse.Success) then
                studioVersion = studioVersionResponse.Body
            else
                reject(studioVersionResponse.StatusMessage)
                return
            end

            local jsonAPIDataResponse = HttpService:RequestAsync({
                Url = API_URL .. string.format(API_DATA_ENDPOINT, studioVersion),
                Method = "GET",
            })

            if (jsonAPIDataResponse.Success) then
                resolve(jsonAPIDataResponse.Body, false)
            else
                reject(jsonAPIDataResponse.StatusMessage)
            end
        else
            reject("No cached API data")
        end
    end):andThen(function(api, usedCache)
        api = usedCache and api or HttpService:JSONDecode(api)

        if (not usedCache) then
            PluginSettings.CacheRobloxAPIData(api)
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

PluginSettings.SettingChanged:subscribe(function(setting)
    local key, newValue = setting.Key, setting.Value
    if (key ~= PluginEnums.PluginSettingKey.CacheAPIData) then return end

    if (newValue) then
        if (not apiData) then return end

        PluginSettings.CacheRobloxAPIData(apiData)
    else
        PluginSettings.ClearCachedRobloxAPIData()
    end
end)

return RobloxAPI