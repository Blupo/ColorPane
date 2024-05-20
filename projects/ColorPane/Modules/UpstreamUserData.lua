--!strict

local StudioService: StudioService = game:GetService("StudioService")

---

local root = script.Parent.Parent
local Common = root.Common

local CommonIncludes = Common.Includes
local Signal = require(CommonIncludes.Signal)

local CommonModules = Common.Modules
local CommonEnums = require(CommonModules.Enums)
local CommonTypes = require(CommonModules.Types)
local UserDataInterfaceValidator = require(CommonModules.UserDataInterfaceValidator)

---

local upstreamInterfaceFolder: Folder?
local getValueFunction: BindableFunction?
local getAllValuesFunction: BindableFunction?
local setValueFunction: BindableFunction?

local valueChangedEvent: BindableEvent?
local valueChangedConnection: RBXScriptConnection?

local upstreamValueChangedSignal: Signal.Signal<CommonTypes.UserDataValue>, fireUpstreamValueChanged: Signal.FireSignal<CommonTypes.UserDataValue> = Signal.createSignal()
local upstreamAvailabilityChangedSignal: Signal.Signal<boolean>, fireUpstreamAvailabilityChanged: Signal.FireSignal<boolean> = Signal.createSignal()

local resetUpstreamInterface = function()
    upstreamInterfaceFolder = nil
    getValueFunction = nil
    getAllValuesFunction = nil
    setValueFunction = nil
    valueChangedEvent = nil

    if (valueChangedConnection) then
        valueChangedConnection:Disconnect()
    end

    valueChangedConnection = nil
    fireUpstreamAvailabilityChanged(false)
end

local hookUpstreamInterface = function(child: Instance)
    if (not UserDataInterfaceValidator(child)) then return end

    upstreamInterfaceFolder = child::Folder
    getValueFunction = child:FindFirstChild("GetValue")::BindableFunction
    getAllValuesFunction = child:FindFirstChild("GetAllValues")::BindableFunction
    setValueFunction = child:FindFirstChild("SetValue")::BindableFunction

    local valueChanged: BindableEvent = child:FindFirstChild("ValueChanged")::BindableEvent
    valueChangedConnection = valueChanged.Event:Connect(fireUpstreamValueChanged)
    valueChangedEvent = valueChanged

    child.ChildRemoved:Connect(function()
        if (
            (child == getValueFunction) or
            (child == getAllValuesFunction) or
            (child == setValueFunction) or
            (child == valueChangedEvent)
        ) then
            resetUpstreamInterface()
        end
    end)

    child.AncestryChanged:Connect(function(this: Instance)
        if (this ~= child) then return end
        resetUpstreamInterface()
    end)

    child.Destroying:Connect(resetUpstreamInterface)
    fireUpstreamAvailabilityChanged(true)
end

---

--[[
    Interface for interacting with the upstream user data provider
    (the Companion plugin).
]]
local UpstreamUserData = {}

--[[
    Fires when a value in the upstream provider changes.
]]
UpstreamUserData.ValueChanged = upstreamValueChangedSignal

--[[
    Fires when the upstream provider's availability changes.
]]
UpstreamUserData.AvailabilityChanged = upstreamAvailabilityChangedSignal

--[[
    Returns if the upstream provider is available.
]]
UpstreamUserData.IsAvailable = function(): boolean
    return (
        (upstreamInterfaceFolder ~= nil) and
        (getValueFunction ~= nil) and
        (getAllValuesFunction ~= nil) and
        (setValueFunction ~= nil) and
        (valueChangedEvent ~= nil)
    )
end

--[[
    Retrives a value from the upstream provider.

    @param key The name of the value to retrieve
    @return If the retrieval was successful
    @return The value of the user data value if the retrieval was successful. Otherwise, an error message.
]]
UpstreamUserData.GetValue = function(key: string): (boolean, any)
    if (not UpstreamUserData.IsAvailable()) then
        return false, CommonEnums.UpstreamUserDataProviderError.Unavailable
    end

    return (getValueFunction::BindableFunction):Invoke(key)
end

--[[
    Retrives all values from the upstream provider.

    @return If the retrieval was successful
    @return The values table if the retrieval was successful. Otherwise, an error message.
]]
UpstreamUserData.GetAllValues = function(): (boolean, string | CommonTypes.UserData)
    if (not UpstreamUserData.IsAvailable()) then
        return false, CommonEnums.UpstreamUserDataProviderError.Unavailable
    end

    return true, (getAllValuesFunction::BindableFunction):Invoke()
end

--[[
    Updates a value in the upstream provider.

    @param key The name of the value to update
    @param value The new value of the value
    @return If the update was successful
    @return An error message if the update wasn't successful
]]
UpstreamUserData.SetValue = function(key: string, value: any): (boolean, string?)
    if (not UpstreamUserData.IsAvailable()) then
        return false, CommonEnums.UpstreamUserDataProviderError.Unavailable
    end

    return (setValueFunction::BindableFunction):Invoke(key, value)
end

---

do
    -- check if the upstream is already available
    local children: {Instance} = StudioService:GetChildren()

    for i = 1, #children do
        local child: Instance = children[i]

        if (UserDataInterfaceValidator(child)) then
            hookUpstreamInterface(child)
            break
        end
    end
end

StudioService.ChildAdded:Connect(hookUpstreamInterface)

return UpstreamUserData