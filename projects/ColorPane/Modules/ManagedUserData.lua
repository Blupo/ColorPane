--!strict
-- Provides user data synchronised with the upstream provider

local root = script.Parent.Parent

local CommonModules = root.Common.Modules
local CommonTypes = require(CommonModules.Types)
local DefaultUserData = require(CommonModules.DefaultUserData)
local PluginProvider = require(CommonModules.PluginProvider)
local UserData = require(CommonModules.UserData)
local Util = require(CommonModules.Util)

local Modules = root.Modules
local UpstreamUserData = require(Modules.UpstreamUserData)

---

local plugin: Plugin = PluginProvider()
local userData: UserData.UserData

local userDataValueChangedSubscription
local upstreamDataValueChangedSubscription
local availabilityChangedSubscription

---

do
    -- initialise user data
    local gotValues: boolean, data: string | CommonTypes.UserData = UpstreamUserData.GetAllValues()

    if (gotValues) then
        userData = UserData.new(data::CommonTypes.UserData)
    else
        userData = UserData.new(Util.table.deepCopy(DefaultUserData))
    end

    -- subscribe to events
    userDataValueChangedSubscription = userData.valueChanged:subscribe(function(value: CommonTypes.UserDataValue)
        UpstreamUserData.SetValue(value.Key, value.Value)
    end)

    upstreamDataValueChangedSubscription = UpstreamUserData.ValueChanged:subscribe(function(value: CommonTypes.UserDataValue)
        userData:setValue(value.Key, value.Value)
    end)

    availabilityChangedSubscription = UpstreamUserData.AvailabilityChanged:subscribe(function(available: boolean)
        -- if the upstream becomes available, we need to pull data
        if (not available) then return end
        
        --[[
            Note: The upstream user data is always authoritative when
            pulling data.

            If there's a difference between the local and upstream
            data, the upstream data will always be used, and local
            data will always be overwritten.
        ]]

        local success, values = UpstreamUserData.GetAllValues()
        if (not success) then return end

        for k, v in pairs(values) do
            -- we don't need to check if the values actually changed since the model already does that
            userData:setValue(k, v)
        end
    end)

    plugin.Unloading:Connect(function()
        userDataValueChangedSubscription:unsubscribe()
        upstreamDataValueChangedSubscription:unsubscribe()
        availabilityChangedSubscription:unsubscribe()
    end)
end

return userData