local RunService: RunService = game:GetService("RunService")
local StudioService: StudioService = game:GetService("StudioService")

---

export type APIError = "NoError" | "NoAPIConnection" | "APIError" | "UnknownError"

export type APIResponse = {
    Success: boolean,
    Status: APIError,
    StatusMessage: string,
    Body: any,
}

---

local API_NAME: string = "ColorPane"
local API_CHECK_FREQUENCY: number = 5

local currentAPI = nil
local unloadingEvent = Instance.new("BindableEvent")

local generateResponse = function(success: boolean, status: APIError?, statusMessage: string?, body: any): APIResponse
    return {
        Success = success,
        Status = if success then "NoError" else (status or "UnknownError"),
        StatusMessage = if success then "OK" else (statusMessage or "An error occurred"),
        Body = body
    }
end

local wrapAPIFunction = function(callback: (...any) -> ...any)
    return function(...: any): APIResponse
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

local API = {}
API.Unloading = unloadingEvent.Event

API.PromptForColor = wrapAPIFunction(function(promptOptions)
    return currentAPI.PromptForColor(promptOptions)
end)

API.PromptForGradient = wrapAPIFunction(function(promptOptions)
    return currentAPI.PromptForGradient(promptOptions)
end)

---

unloadingEvent.Event:Connect(onUnload)
getModule()

if (not currentAPI) then
    onUnload()
end

return API