local ChangeHistoryService: ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection: Selection = game:GetService("Selection")

---

local root = script.Parent.Parent

local includes = root.includes
local Signal = require(includes.Signal)

local PluginModules = root.PluginModules
local ColorAPIData = require(PluginModules.ColorAPIData)
local PluginProvider = require(PluginModules.PluginProvider)
local RobloxAPI = require(PluginModules.RobloxAPI)
local Util = require(PluginModules.Util)

---

local plugin: Plugin? = PluginProvider()
assert(plugin, Util.makeBugMessage("Plugin object is missing"))

local apiIsReady: boolean = false

local currentSelection: {Instance} = {}
local currentSelectionProperties = {}
local currentSelectionCommonPropertyValues = {}
local currentSelectionPropertyValuesChangedConnections = {}

local internalSelectionChanged
local selectionChangedSignal: Signal.Signal<nil>, fireSelectionChanged: Signal.FireSignal<nil> = Signal.createSignal()
local selectionColorsChangedSignal: Signal.Signal<nil>, fireSelectionColorsChanged: Signal.FireSignal<nil> = Signal.createSignal()

-- gets all Instances in the selection which are "safe"
-- i.e. doesn't raise any security errors and has a non-blank ClassName
local getSafeSelection = function(): {Instance}
    local selection: {Instance} = Selection:Get()

    for i = #selection, 1, -1 do
        local obj: Instance = selection[i]

        local passesSecurityCheck: boolean, validClassName: boolean = pcall(function()
            return (obj.ClassName ~= "")
        end)

        if (not (passesSecurityCheck and validClassName)) then
            table.remove(selection, i)
        end
    end

    return selection
end

local getSelectionColorProperties = function(selection)
    local classes = {}

    for i = 1, #selection do
        local className = selection[i].ClassName

        if (not table.find(classes, className)) then
            table.insert(classes, className)
        end
    end

    return ColorAPIData.GetProperties(classes)
end

local generateSelectionCommonColorPropertyValue = function(className: string, propertyName: string)
    local propertyInfo = ColorAPIData.GetProperty(className, propertyName)
    if (not propertyInfo) then return end

    local anchorValue

    for i = 1, #currentSelection do
        local object = currentSelection[i]

        if (object:IsA(className)) then
            local objectValue = propertyInfo.Custom and propertyInfo.Get(object) or object[propertyName]

            if (anchorValue == nil) then
                anchorValue = objectValue
            elseif (anchorValue ~= objectValue) then
                anchorValue = false
                break
            end
        end
    end

    if (anchorValue) then
        return ColorAPIData.TransformPropertyValue(className, propertyName, anchorValue)
    end
end

local generateSelectionCommonColorPropertyValues = function(properties)
    local values = {}

    for className, classProperties in pairs(properties) do
        for propertyName, propertyInfo in pairs(classProperties) do
            local anchorValue

            for i = 1, #currentSelection do
                local object = currentSelection[i]

                if (object:IsA(className)) then
                    local objectValue = propertyInfo.Custom and propertyInfo.Get(object) or object[propertyName]

                    if (anchorValue == nil) then
                        anchorValue = objectValue
                    elseif (anchorValue ~= objectValue) then
                        anchorValue = false
                        break
                    end
                end
            end

            if (anchorValue) then
                if (not values[className]) then
                    values[className] = {}
                end

                values[className][propertyName] = ColorAPIData.TransformPropertyValue(className, propertyName, anchorValue)
            end
        end
    end

    return values
end

local onSelectionChanged = function()
    currentSelection = getSafeSelection()
    currentSelectionProperties = getSelectionColorProperties(currentSelection)
    currentSelectionCommonPropertyValues = generateSelectionCommonColorPropertyValues(currentSelectionProperties)

    for i = 1, #currentSelectionPropertyValuesChangedConnections do
        currentSelectionPropertyValuesChangedConnections[i]:Disconnect()
    end

    table.clear(currentSelectionPropertyValuesChangedConnections)

    for className, classProperties in pairs(currentSelectionProperties) do
        for propertyName, propertyInfo in pairs(classProperties) do
            for i = 1, #currentSelection do
                local object: Instance = currentSelection[i]

                if (object:IsA(className) and (not propertyInfo.Custom)) then
                    -- update common properties table
                    table.insert(currentSelectionPropertyValuesChangedConnections, object:GetPropertyChangedSignal(propertyName):Connect(function()
                        local newCommonValue = generateSelectionCommonColorPropertyValue(className, propertyName)

                        if (newCommonValue and (not currentSelectionCommonPropertyValues[className])) then
                            currentSelectionCommonPropertyValues[className] = {}
                        elseif ((not newCommonValue) and (not currentSelectionCommonPropertyValues[className])) then
                            return
                        end

                        currentSelectionCommonPropertyValues[className][propertyName] = newCommonValue
                        fireSelectionColorsChanged()
                    end))
                end
            end
        end
    end

    fireSelectionChanged()
end

---

local SelectionManager = {}

SelectionManager.SelectionChanged = selectionChangedSignal
SelectionManager.SelectionColorsChanged = selectionColorsChangedSignal

SelectionManager.Connect = function()
    if (internalSelectionChanged) then return end

    internalSelectionChanged = Selection.SelectionChanged:Connect(onSelectionChanged)
    onSelectionChanged()
end

SelectionManager.Disconnect = function()
    if (not internalSelectionChanged) then return end

    for i = 1, #currentSelectionPropertyValuesChangedConnections do
        currentSelectionPropertyValuesChangedConnections[i]:Disconnect()
    end

    table.clear(currentSelectionPropertyValuesChangedConnections)

    internalSelectionChanged:Disconnect()
    internalSelectionChanged = nil
end

SelectionManager.GetSelectionCommonColorPropertyValues = function(): {[string]: {[string]: any}}
    return currentSelectionCommonPropertyValues
end

SelectionManager.GetSelectionColorPropertyData = function()
    if (not apiIsReady) then
        return {
            Properties = {},
            Duplicated = {},
            Sorted = {},
        }
    end

    local duplicateProperties = {}
    local sortedProperties = {}

    for className, classProperties in pairs(currentSelectionProperties) do
        for propertyName in pairs(classProperties) do
            if (duplicateProperties[propertyName] == nil) then
                for otherClassName, otherClassProperties in pairs(currentSelectionProperties) do
                    if (otherClassName == className) then continue end

                    if otherClassProperties[propertyName] then
                        duplicateProperties[propertyName] = true
                        break
                    end
                end

                if (duplicateProperties[propertyName] == nil) then
                    duplicateProperties[propertyName] = false
                end
            end

            table.insert(sortedProperties, {className, propertyName})
        end
    end

    table.sort(sortedProperties, function(a, b)
        if (a[2] ~= b[2]) then
            return a[2] < b[2]
        else
            return a[1] < b[1]
        end
    end)

    return {
        Properties = currentSelectionProperties,
        Duplicated = duplicateProperties,
        Sorted = sortedProperties,
    }
end

SelectionManager.GenerateSelectionColorPropertyValueSnapshot = function(className: string, propertyName: string): {[Instance]: any}
    local propertyInfo = ColorAPIData.GetProperty(className, propertyName)
    if (not propertyInfo) then return {} end

    local snapshot = {}

    for i = 1, #currentSelection do
        local object = currentSelection[i]

        if (object:IsA(className)) then
            snapshot[object] = propertyInfo.Custom and propertyInfo.Get(object) or object[propertyName]
        end
    end

    return snapshot
end

SelectionManager.RestoreSelectionColorPropertyFromSnapshot = function(className: string, propertyName: string, snapshot: {[Instance]: any})
    local propertyInfo = ColorAPIData.GetProperty(className, propertyName)
    if (not propertyInfo) then return end

    for i = 1, #currentSelection do
        local object: Instance = currentSelection[i]

        if (object:IsA(className)) then
            local color = snapshot[object]

            if (propertyInfo.Custom) then
                propertyInfo.Set(object, color)
            else
                object[propertyName] = color
            end
        end
    end
end

SelectionManager.SetSelectionProperty = function(className: string, propertyName: string, newColor: any, setHistoryWaypoint: boolean)
    local propertyInfo = ColorAPIData.GetProperty(className, propertyName)
    if (not propertyInfo) then return end

    if (setHistoryWaypoint) then
        ChangeHistoryService:SetWaypoint(propertyName)
    end

    for i = 1, #currentSelection do
        local object: Instance = currentSelection[i]

        if (object:IsA(className)) then
            local transformedColor = ColorAPIData.TransformColorValue(className, propertyName, newColor)

            if (propertyInfo.Custom) then
                propertyInfo.Set(object, transformedColor)
            else
                object[propertyName] = transformedColor
            end
        end
    end

    if (setHistoryWaypoint) then
        ChangeHistoryService:SetWaypoint(propertyName)
    end
end

---

RobloxAPI.DataRequestFinished:subscribe(function(didLoad: boolean)
    if (not didLoad) then return end

    apiIsReady = true
    onSelectionChanged()
end)

plugin.Unloading:Connect(SelectionManager.Disconnect)
return SelectionManager