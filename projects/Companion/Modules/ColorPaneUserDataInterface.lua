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
local ColorPaneUserDataInterfaceValidator = require(CommonModules.ColorPaneUserDataInterfaceValidator)
local ColorPaneUserDataInterfaceVersion = require(CommonModules.ColorPaneUserDataInterfaceVersion)
local CommonTypes = require(CommonModules.Types)
local PluginProvider = require(CommonModules.PluginProvider)

local Modules = root.Modules
local ManagedUserData = require(Modules.ManagedUserData)

---

local plugin: Plugin = PluginProvider()
local colorPaneUserData = ManagedUserData.ColorPane

local interfaceFolder: Folder = Instance.new("Folder")
local getVersionFunction: BindableFunction = Instance.new("BindableFunction")
local getValueFunction: BindableFunction = Instance.new("BindableFunction")
local getAllValuesFunction: BindableFunction = Instance.new("BindableFunction")
local setValueFunction: BindableFunction = Instance.new("BindableFunction")
local valueChangedEvent: BindableEvent = Instance.new("BindableEvent")

---

getVersionFunction.OnInvoke = function(): number
    return ColorPaneUserDataInterfaceVersion
end

getValueFunction.OnInvoke = function(key: string): any
    return colorPaneUserData:getValue(key)
end

getAllValuesFunction.OnInvoke = function(): CommonTypes.ColorPaneUserData
    return colorPaneUserData:getAllValues()
end

setValueFunction.OnInvoke = function(key: string, value: any): boolean
    return colorPaneUserData:setValue(key, value)
end

local valueChangedSubscription = colorPaneUserData.valueChanged:subscribe(function(value: CommonTypes.KeyValue)
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
    local interfaceIsValid: boolean, invalidReason: string? = ColorPaneUserDataInterfaceValidator(interfaceFolder)

    if (not interfaceIsValid) then
        error("[CPCompanion] The user data interface is invalid: " .. invalidReason::string)
    else
        interfaceFolder.Parent = StudioService
    end
end

plugin.Unloading:Connect(function()
    valueChangedSubscription:unsubscribe()
    getVersionFunction:Destroy()
    getValueFunction:Destroy()
    getAllValuesFunction:Destroy()
    setValueFunction:Destroy()
    valueChangedEvent:Destroy()
    interfaceFolder:Destroy()
end)

return nil