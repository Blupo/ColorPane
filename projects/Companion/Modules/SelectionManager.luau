local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

---

local root = script.Parent.Parent
local Common = root.Common

local CommonIncludes = Common.Includes
local Signal = require(CommonIncludes.Signal)

local CommonModules = Common.Modules
local PluginProvider = require(CommonModules.PluginProvider)

local Modules = root.Modules
local ColorAPIData = require(Modules.ColorAPIData)
local RobloxAPI = require(Modules.RobloxAPI)

---

local plugin: Plugin = PluginProvider()
local apiIsReady = false
local recordingId: string?

local currentSelection: {Instance} = {}
local currentSelectionProperties = {}
local currentSelectionCommonPropertyValues = {}
local currentSelectionPropertyValuesChangedConnections = {}

local dataRequestFinishedSubscription

local internalSelectionChanged
local selectionChangedSignal: Signal.Signal<nil>, fireSelectionChanged: Signal.FireSignal<nil> = Signal.createSignal()
local selectionColorsChangedSignal: Signal.Signal<nil>, fireSelectionColorsChanged: Signal.FireSignal<nil> = Signal.createSignal()

local getSafeSelection = function(): {Instance}
    local selection: {Instance} = Selection:Get()

    for i = #selection, 1, -1 do
        local obj = selection[i]

        --[[
            Make sure we pass the security check and ClassName isn't blank
            (because apparently that's a thing)
        ]]
        local passesSecurityCheck, validClassName = pcall(function()
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
    else
        return nil
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

---

local SelectionManager = {}

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

SelectionManager.BeginRecording = function()
    assert(recordingId == nil, "Recording already started")

    recordingId = ChangeHistoryService:TryBeginRecording( "Change color properties")
    assert(recordingId ~= nil, "Could not begin recording")
end

SelectionManager.StopRecording = function(operation: Enum.FinishRecordingOperation)
    assert(recordingId, "Recording has not started")

    ChangeHistoryService:FinishRecording(recordingId, operation)
    recordingId = nil
end

SelectionManager.SetSelectionProperty = function(className: string, propertyName: string, newColor: any)
    if (not recordingId) then return end

    local propertyInfo = ColorAPIData.GetProperty(className, propertyName)
    if (not propertyInfo) then return end

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
end

---

dataRequestFinishedSubscription = RobloxAPI.DataRequestFinished:subscribe(function(didLoad)
    if (not didLoad) then return end

    apiIsReady = true
    onSelectionChanged()
end)

plugin.Unloading:Connect(function()
    if (recordingId) then
        SelectionManager.StopRecording(Enum.FinishRecordingOperation.Cancel)
    end

    dataRequestFinishedSubscription:unsubscribe()
    SelectionManager.Disconnect()
end)

return SelectionManager