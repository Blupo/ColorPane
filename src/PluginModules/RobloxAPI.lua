local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

---

local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local ColorAPIData = require(PluginModules:FindFirstChild("ColorAPIData"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local PluginSettings = require(PluginModules:FindFirstChild("PluginSettings"))

local includes = root:FindFirstChild("includes")
local Promise = require(includes:FindFirstChild("Promise"))
local Signal = require(includes:FindFirstChild("GoodSignal"))

---

local API_URL = "https://setup.rbxcdn.com/"
local STUDIO_VERSION_ENDPOINT = "versionQTStudio"
local API_DATA_ENDPOINT = "%s-API-Dump.json"

local apiData
local requestInProgress = false

---

local RobloxAPI = {}
RobloxAPI.DataRequestStarted = Signal.new()
RobloxAPI.DataRequestFinished = Signal.new()

RobloxAPI.IsAvailable = function()
    return (apiData and true or false)
end

RobloxAPI.IsRequestRunning = function()
    return requestInProgress
end

RobloxAPI.GetData = function()
    if (apiData or requestInProgress) then return end

    requestInProgress = true
    RobloxAPI.DataRequestStarted:Fire()

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
        RobloxAPI.DataRequestFinished:Fire(true)
    end, function()
        RobloxAPI.DataRequestFinished:Fire(false)
    end):finally(function()
        requestInProgress = false
    end)
end

---

PluginSettings.SettingChanged:Connect(function(key, newValue)
    if (key ~= PluginEnums.PluginSettingKey.CacheAPIData) then return end

    if (newValue) then
        if (not apiData) then return end

        PluginSettings.CacheRobloxAPIData(apiData)
    else
        PluginSettings.ClearCachedRobloxAPIData()
    end
end)

return RobloxAPI