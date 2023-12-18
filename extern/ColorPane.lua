local RunService: RunService = game:GetService("RunService")
local StudioService: StudioService = game:GetService("StudioService")

---

--[=[
    @interface APIStatus
    @within Proxy
    @field NoError "NoError"
    @field NoAPIConnection "NoAPIConnection" -- The API is not available
    @field APIError "APIError" -- There was a problem communicating with the API
    @field UnknownError "UnknownError"
]=]
export type APIStatus = "NoError" | "NoAPIConnection" | "APIError" | "UnknownError"

--[=[
    @interface ProxyResponse
    @within Proxy
    @field Success boolean -- Did the call succeed?
    @field Status APIStatus -- The status of the API call
    @field StatusMessage string -- An explanation of the status
    @field Body any -- The value the API returned
]=]
export type ProxyResponse = {
    Success: boolean,
    Status: APIStatus,
    StatusMessage: string,
    Body: any,
}

---

local API_NAME: string = "ColorPane"
local API_CHECK_FREQUENCY: number = 5

local currentAPI = nil
local unloadingEvent = Instance.new("BindableEvent")

local generateResponse = function(success: boolean, status: APIStatus?, statusMessage: string?, body: any): ProxyResponse
    return {
        Success = success,
        Status = if success then "NoError" else (status or "UnknownError"),
        StatusMessage = if success then "OK" else (statusMessage or "An error occurred"),
        Body = body
    }
end

local wrapAPIFunction = function(callback: (...any) -> ...any)
    return function(...: any): ProxyResponse
        if (not currentAPI) then
            return generateResponse(false, "NoAPIConnection", "Could not connect to the API")
        else
            local success, body = pcall(callback, ...)

            if (not success) then
                return generateResponse(false, "APIError", body)
            else
                return generateResponse(true, nil, nil, body)
            end
        end
    end
end

local getModule = function()
    if (currentAPI) then return end

    local module: Instance? = StudioService:FindFirstChild(API_NAME)
    if (not module) then return end
    if (not module:IsA("ModuleScript")) then return end

    local success: boolean, api = pcall(require, module)
    if (not success) then return end

    local unloading
    unloading = api.Unloading:Connect(function()
        unloading:Disconnect()
        unloading = nil
        
        if (currentAPI == api) then
            unloadingEvent:Fire()
            currentAPI = nil
        end
    end)

    currentAPI = api
end

local onUnload = function()
    local heartbeat
    local freq: number = API_CHECK_FREQUENCY

    heartbeat = RunService.Heartbeat:Connect(function(dt: number)
        if (currentAPI) then
            heartbeat:Disconnect()
            return
        end

        freq -= dt

        if (freq <= 0) then
            getModule()
            freq = API_CHECK_FREQUENCY
        end
    end)
end

---

--[=[
    @class Proxy
]=]

local Proxy = {}

--[=[
    @prop Unloading RBXScriptSignal
    @within Proxy
    @readonly
]=]
Proxy.Unloading = unloadingEvent.Event

--[=[
    @function IsAPIConnected
    @within Proxy
    @return boolean
]=]
Proxy.IsAPIConnected = function()
    return (if currentAPI then true else false)
end

--[=[
    @function PromptForColor
    @within Proxy
    @param options ColorPromptOptions
    @return ProxyResponse
]=]
Proxy.PromptForColor = wrapAPIFunction(function(promptOptions)
    return currentAPI.PromptForColor(promptOptions)
end)

--[=[
    @function PromptForGradient
    @within Proxy
    @param options GradientPromptOptions
    @return ProxyResponse
]=]
Proxy.PromptForGradient = wrapAPIFunction(function(promptOptions)
    return currentAPI.PromptForGradient(promptOptions)
end)

---

unloadingEvent.Event:Connect(onUnload)
getModule()

if (not currentAPI) then
    onUnload()
end

return Proxy