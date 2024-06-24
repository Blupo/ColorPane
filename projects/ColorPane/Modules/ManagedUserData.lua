--!strict

local root = script.Parent.Parent
local Common = root.Common

local CommonIncludes = Common.Includes
local Signal = require(CommonIncludes.Signal)

local CommonModules = Common.Modules
local ColorPaneUserDataDefaultValues = require(CommonModules.ColorPaneUserDataDefaultValues)
local ColorPaneUserDataFactory = require(CommonModules.ColorPaneUserDataFactory)
local CommonTypes = require(CommonModules.Types)
local PluginProvider = require(CommonModules.PluginProvider)
local UserData = require(CommonModules.UserData)
local Util = require(CommonModules.Util)

local Modules = root.Modules
local UpstreamUserData = require(Modules.UpstreamUserData)

---

local plugin: Plugin = PluginProvider()

local localUserData: UserData.UserData
local valueChangedSignal: Signal.Signal<CommonTypes.KeyValue>, fireValueChanged: Signal.FireSignal<CommonTypes.KeyValue> = Signal.createSignal()

local localUserDataValueChangedSubscription: Signal.Subscription
local upstreamDataValueChangedSubscription: Signal.Subscription
local availabilityChangedSubscription: Signal.Subscription

---

local ManagedUserData = {}

--[[
    Fires when a user data value changes.
]]
ManagedUserData.ValueChanged = valueChangedSignal

--[[
    Retrives a user data value.

    @param key The name of the value to retrieve
    @return The user data value
]]
ManagedUserData.GetValue = function(key: string)
    if (UpstreamUserData.IsAvailable()) then
        return UpstreamUserData.GetValue(key)
    else
        return localUserData:getValue(key)
    end
end

--[[
    Retrives all user data values.

    @return The values table
]]
ManagedUserData.GetAllValues = function()
    if (UpstreamUserData.IsAvailable()) then
        return UpstreamUserData.GetAllValues()
    else
        return localUserData:getAllValues()
    end
end

--[[
    Updates a user data value.

    @param key The name of the value to update
    @param value The new value of the value
]]
ManagedUserData.SetValue = function(key: string, value: any)
    if (UpstreamUserData.IsAvailable()) then
        UpstreamUserData.SetValue(key, value)
    else
        localUserData:setValue(key, value)
    end
end

---

-- initialise user data
do
    local gotValues: boolean, data: string | CommonTypes.ColorPaneUserData = pcall(UpstreamUserData.GetAllValues)

    if (gotValues) then
        localUserData = ColorPaneUserDataFactory(data::CommonTypes.ColorPaneUserData)
    else
        localUserData = ColorPaneUserDataFactory(Util.table.deepCopy(ColorPaneUserDataDefaultValues))
    end
end

localUserDataValueChangedSubscription = localUserData.valueChanged:subscribe(function(value: CommonTypes.KeyValue)
    if (UpstreamUserData.IsAvailable()) then return end

    fireValueChanged(value)
end)

upstreamDataValueChangedSubscription = UpstreamUserData.ValueChanged:subscribe(function(value: CommonTypes.KeyValue)
    fireValueChanged(value)
end)

availabilityChangedSubscription = UpstreamUserData.AvailabilityChanged:subscribe(function(available: boolean)
    if (not available) then return end
    
    --  Note: The upstream user data is always authoritative when
    --  pulling data.
    --
    --  If there's a difference between the local and upstream
    --  data, the upstream data will always be used, and local
    --  data will always be overwritten.
    local success, values = pcall(UpstreamUserData.GetAllValues)
    if (not success) then return end

    for k, v in pairs(values) do
        local updated = localUserData:setValue(k, v)

        if (updated) then
            -- we need to fire the event here since the
            -- subscription callback will not
            fireValueChanged({
                Key = k,
                Value = v
            })
        end
    end
end)

plugin.Unloading:Connect(function()
    localUserDataValueChangedSubscription:unsubscribe()
    upstreamDataValueChangedSubscription:unsubscribe()
    availabilityChangedSubscription:unsubscribe()
end)

return ManagedUserData