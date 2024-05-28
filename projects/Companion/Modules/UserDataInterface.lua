--!strict
--[[
    Provides a physical interface in the form of BindableFunctions and BindableEvents
    for ColorPane instances to retrieve and update user data values.
]]

local StudioService: StudioService = game:GetService("StudioService")

---

local root = script.Parent.Parent

local Common = root.Common
local CommonModules = Common.Modules
local CommonTypes = require(CommonModules.Types)
local PluginProvider = require(CommonModules.PluginProvider)
local UserDataInterfaceValidator = require(CommonModules.UserDataInterfaceValidator)
local UserDataInterfaceVersion = require(CommonModules.UserDataInterfaceVersion)

local Modules = root.Modules
local ManagedUserData = require(Modules.ManagedUserData)

---

local plugin: Plugin = PluginProvider()

local interfaceFolder: Folder = Instance.new("Folder")
local getVersionFunction: BindableFunction = Instance.new("BindableFunction")
local getValueFunction: BindableFunction = Instance.new("BindableFunction")
local getAllValuesFunction: BindableFunction = Instance.new("BindableFunction")
local setValueFunction: BindableFunction = Instance.new("BindableFunction")
local valueChangedEvent: BindableEvent = Instance.new("BindableEvent")

---

getVersionFunction.OnInvoke = function(): number
    return UserDataInterfaceVersion
end

getValueFunction.OnInvoke = function(key: string): any
    return ManagedUserData:getValue(key)
end

getAllValuesFunction.OnInvoke = function(): CommonTypes.UserData
    return ManagedUserData:getAllValues()
end

setValueFunction.OnInvoke = function(key: string, value: any): ()
    ManagedUserData:setValue(key, value)
end

local valueChangedSubscription = ManagedUserData.valueChanged:subscribe(function(value: CommonTypes.KeyValue)
    valueChangedEvent:Fire(value)
end)

---

interfaceFolder.Name = "ColorPaneUserData"
getVersionFunction.Name = "GetVersion"
getValueFunction.Name = "GetValue"
getAllValuesFunction.Name = "GetAllValues"
setValueFunction.Name = "SetValue"
valueChangedEvent.Name = "ValueChanged"

interfaceFolder.Archivable = false
getVersionFunction.Archivable = false
getValueFunction.Archivable = false
getAllValuesFunction.Archivable = false
setValueFunction.Archivable = false
valueChangedEvent.Archivable = false

getVersionFunction.Parent = interfaceFolder
getValueFunction.Parent = interfaceFolder
getAllValuesFunction.Parent = interfaceFolder
setValueFunction.Parent = interfaceFolder
valueChangedEvent.Parent = interfaceFolder

-- check if the interface is valid before we put it out into the world
do
    local interfaceIsValid: boolean, invalidReason: string? = UserDataInterfaceValidator(interfaceFolder)

    if (not interfaceIsValid) then
        error("[CPCompanion] The user data interface is invalid: " .. invalidReason::string)
    else
        interfaceFolder.Parent = StudioService
    end
end

plugin.Unloading:Connect(function()
    valueChangedSubscription:unsubscribe()
    interfaceFolder:Destroy()
end)

return nil