local HttpService = game:GetService("HttpService")

---

local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local TerrainMaterialColors = require(PluginModules:FindFirstChild("TerrainMaterialColors"))

local includes = root:FindFirstChild("includes")
local APIUtils = require(includes:FindFirstChild("APIUtils"))
local Promise = require(includes:FindFirstChild("Promise"))

---

local API_URL = "https://setup.rbxcdn.com/"
local STUDIO_VERSION_ENDPOINT = "versionQTStudio"
local API_DUMP_ENDPOINT = "%s-API-Dump.json"

local apiDump
local requestInProgress = false
local apiDataRequestStartedEvent = Instance.new("BindableEvent")
local apiDataRequestFinishedEvent = Instance.new("BindableEvent")

---

local RobloxAPI = {}
RobloxAPI.DataRequestStarted = apiDataRequestStartedEvent.Event
RobloxAPI.DataRequestFinished = apiDataRequestFinishedEvent.Event

RobloxAPI.IsAvailable = function()
    return (apiDump and true or false)
end

RobloxAPI.IsRequestRunning = function()
    return requestInProgress
end

RobloxAPI.GetData = function()
    if (apiDump or requestInProgress) then return end

    requestInProgress = true
    apiDataRequestStartedEvent:Fire()

    Promise.new(function(resolve, reject)
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

        local jsonAPIDumpResponse = HttpService:RequestAsync({
            Url = API_URL .. string.format(API_DUMP_ENDPOINT, studioVersion),
            Method = "GET",
        })

        if (jsonAPIDumpResponse.Success) then
            resolve(HttpService:JSONDecode(jsonAPIDumpResponse.Body))
        else
            reject(jsonAPIDumpResponse.StatusMessage)
        end
    end):andThen(function(api)
        RobloxAPI.APIData = APIUtils.createAPIData(api)
        RobloxAPI.APIInterface = APIUtils.createAPIInterface(RobloxAPI.APIData)

        for i = 1, #TerrainMaterialColors.Properties do
            local property = TerrainMaterialColors.Properties[i]
            local behaviour = TerrainMaterialColors.Behaviours[i]
        
            RobloxAPI.APIData:AddClassMember("Terrain", property)
            RobloxAPI.APIInterface:AddClassMemberBehavior("Terrain", "Property", property.Name, behaviour)
        end
        
        apiDump = api
        apiDataRequestFinishedEvent:Fire(true)
    end, function()
        apiDataRequestFinishedEvent:Fire(false)
    end):finally(function()
        requestInProgress = false
    end)
end

--[[
RobloxAPI.GetData = function()
    if (apiDump or requestInProgress) then return end

    requestInProgress = true
    apiDataRequestStartedEvent:Fire()

    coroutine.wrap(function()
        local studioVersion

        pcall(function()
            local response = HttpService:RequestAsync({
                Url = API_URL .. STUDIO_VERSION_ENDPOINT,
                Method = "GET",
            })
        
            if (response.Success) then
                studioVersion = response.Body
            end
        end)

        if (not studioVersion) then
            requestInProgress = false
            apiDataRequestFinishedEvent:Fire(false)

            return
        end

        pcall(function()
            local response = HttpService:RequestAsync({
                Url = API_URL .. string.format(API_DUMP_ENDPOINT, studioVersion),
                Method = "GET",
            })
        
            if (response.Success) then
                apiDump = HttpService:JSONDecode(response.Body)
            end
        end)

        if (apiDump) then
            RobloxAPI.APIData = APIUtils.createAPIData(apiDump)
            RobloxAPI.APIInterface = APIUtils.createAPIInterface(RobloxAPI.APIData)

            for i = 1, #TerrainMaterialColors.Properties do
                local property = TerrainMaterialColors.Properties[i]
                local behaviour = TerrainMaterialColors.Behaviours[i]
            
                RobloxAPI.APIData:AddClassMember("Terrain", property)
                RobloxAPI.APIInterface:AddClassMemberBehavior("Terrain", "Property", property.Name, behaviour)
            end
        end

        requestInProgress = false
        apiDataRequestFinishedEvent:Fire(apiDump and true or false)
    end)()
end
--]]

RobloxAPI.init = function(plugin)
    RobloxAPI.init = nil

    plugin.Unloading:Connect(function()
        apiDataRequestStartedEvent:Destroy()
        apiDataRequestFinishedEvent:Destroy()
    end)
end

return RobloxAPI