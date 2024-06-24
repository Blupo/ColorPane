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
local ColorPaneUserDataInterfaceValidator = require(CommonModules.ColorPaneUserDataInterfaceValidator)
local ColorPaneUserDataInterfaceVersion = require(CommonModules.ColorPaneUserDataInterfaceVersion)
local PluginProvider =  require(CommonModules.PluginProvider)

---

local plugin: Plugin = PluginProvider()
local childAdded: RBXScriptConnection

local upstreamInterfaceFolder: Folder?
local getValueFunction: BindableFunction?
local getAllValuesFunction: BindableFunction?
local setValueFunction: BindableFunction?
local valueChangedEvent: BindableEvent?

local valueChangedConnection: RBXScriptConnection
local interfaceChildRemoved: RBXScriptConnection
local interfaceAncestryChanged: RBXScriptConnection
local interfaceDestroying: RBXScriptConnection

local upstreamValueChangedSignal: Signal.Signal<CommonTypes.KeyValue>, fireUpstreamValueChanged: Signal.FireSignal<CommonTypes.KeyValue> = Signal.createSignal()
local upstreamAvailabilityChangedSignal: Signal.Signal<boolean>, fireUpstreamAvailabilityChanged: Signal.FireSignal<boolean> = Signal.createSignal()

local resetUpstreamInterface = function()
    valueChangedConnection:Disconnect()
    interfaceChildRemoved:Disconnect()
    interfaceAncestryChanged:Disconnect()
    interfaceDestroying:Disconnect()

    upstreamInterfaceFolder = nil
    getValueFunction = nil
    getAllValuesFunction = nil
    setValueFunction = nil
    valueChangedEvent = nil

    fireUpstreamAvailabilityChanged(false)
end

local hookUpstreamInterface = function(child: Instance)
    if (not ColorPaneUserDataInterfaceValidator(child)) then return end

    local getVersion: BindableFunction = child:FindFirstChild("GetVersion")::BindableFunction
    local thisVersion: number = getVersion:Invoke()
    if (thisVersion ~= ColorPaneUserDataInterfaceVersion) then return end

    upstreamInterfaceFolder = child::Folder
    getValueFunction = child:FindFirstChild("GetValue")::BindableFunction
    getAllValuesFunction = child:FindFirstChild("GetAllValues")::BindableFunction
    setValueFunction = child:FindFirstChild("SetValue")::BindableFunction

    local valueChanged: BindableEvent = child:FindFirstChild("ValueChanged")::BindableEvent
    valueChangedConnection = valueChanged.Event:Connect(fireUpstreamValueChanged)
    valueChangedEvent = valueChanged

    interfaceChildRemoved = child.ChildRemoved:Connect(function()
        if (
            (child == getValueFunction) or
            (child == getAllValuesFunction) or
            (child == setValueFunction) or
            (child == valueChangedEvent)
        ) then
            resetUpstreamInterface()
        end
    end)

    interfaceAncestryChanged = child.AncestryChanged:Connect(function(this: Instance)
        if (this ~= child) then return end
        resetUpstreamInterface()
    end)

    interfaceDestroying = child.Destroying:Connect(resetUpstreamInterface)
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
    @return The user data value
]]
UpstreamUserData.GetValue = function(key: string): any
    assert(UpstreamUserData.IsAvailable(), CommonEnums.UpstreamUserDataProviderError.Unavailable)
    return (getValueFunction::BindableFunction):Invoke(key)
end

--[[
    Retrives all values from the upstream provider.

    @return The values table
]]
UpstreamUserData.GetAllValues = function(): CommonTypes.ColorPaneUserData
    assert(UpstreamUserData.IsAvailable(), CommonEnums.UpstreamUserDataProviderError.Unavailable)
    return (getAllValuesFunction::BindableFunction):Invoke()
end

--[[
    Updates a value in the upstream provider.

    @param key The name of the value to update
    @param value The new value of the value
    @return If the value was actually updated
]]
UpstreamUserData.SetValue = function(key: string, value: any): boolean
    assert(UpstreamUserData.IsAvailable(), CommonEnums.UpstreamUserDataProviderError.Unavailable)
    return (setValueFunction::BindableFunction):Invoke(key, value)
end

---

do
    -- check if the upstream is already available
    local children: {Instance} = StudioService:GetChildren()

    for i = 1, #children do
        local child: Instance = children[i]

        if (ColorPaneUserDataInterfaceValidator(child)) then
            hookUpstreamInterface(child)
            break
        end
    end
end

childAdded = StudioService.ChildAdded:Connect(hookUpstreamInterface)

plugin.Unloading:Connect(function()
    childAdded:Disconnect()
    resetUpstreamInterface()
end)

return UpstreamUserData