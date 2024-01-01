--[[
    This ModuleScript provides a proxy interface for
    communicating with the ColorPane plugin, instead
    of having to create such an interface yourself.

    Please read the documentation for how to use this:
        https://blupo.github.io/ColorPane/docs/developer-guide/integration
]]

local RunService: RunService = game:GetService("RunService")
local StudioService: StudioService = game:GetService("StudioService")

---

export type APIStatus = "NoError" | "NoAPIConnection" | "APIError" | "IncompatibilityError" | "UnknownError"

export type ProxyResponse = {
    Success: boolean,
    Status: APIStatus,
    StatusMessage: string,
    Body: any,
}

---

local API_NAME: string = "ColorPane"
local API_CHECK_FREQUENCY: number = 5
local PROXY_VERSION: {number} = {0, 5, 0}   -- TODO (rolling): update version to match ColorPane's

local currentAPI = nil
local incompatible: boolean = false
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
        elseif (incompatible) then
            return generateResponse(false, "IncompatibilityError", "Major version mismatch between ColorPane and Proxy")
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

    -- hook unloading event
    local unloading
    unloading = api.Unloading:Connect(function()
        unloading:Disconnect()
        unloading = nil
        
        if (currentAPI == api) then
            unloadingEvent:Fire()
            currentAPI = nil
        end
    end)

    -- check for version compatibility
    local major: number= PROXY_VERSION[1]
    local apiMajor: number = api.GetVersion()

    incompatible = (apiMajor ~= major)  -- incompatibility occurs if the major versions don't match
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

local Proxy = {}
Proxy.Unloading = unloadingEvent.Event

-- Returns if the proxy is connected to ColorPane
Proxy.IsAPIConnected = function()
    return (if currentAPI then true else false)
end

-- Returns the proxy version
Proxy.GetVersion = function()
    return table.unpack(PROXY_VERSION)
end

-- Returns if ColorPane's color editor is open
Proxy.IsColorEditorOpen = wrapAPIFunction(function()
    return currentAPI.IsColorEditorOpen()
end)

-- Returns if ColorPane's gradient editor is open
Proxy.IsGradientEditorOpen = wrapAPIFunction(function()
    return currentAPI.IsGradientEditorOpen()
end)

-- Prompts the user for a color
Proxy.PromptForColor = wrapAPIFunction(function(promptOptions)
    return currentAPI.PromptForColor(promptOptions)
end)

-- Prompts the user for a gradient
Proxy.PromptForGradient = wrapAPIFunction(function(promptOptions)
    return currentAPI.PromptForGradient(promptOptions)
end)

---

unloadingEvent.Event:Connect(onUnload)
getModule()

if (not currentAPI) then
    onUnload()
end

return table.freeze(Proxy)