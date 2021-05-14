local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

---

local PluginModules = script.Parent
local RobloxAPI = require(PluginModules:FindFirstChild("RobloxAPI"))

local APIData
local APIInterface

---

local debounce = false
local isAPIReady = false
local shouldListenForPropertyChanges = true

local selection
local selectionClassMap = {}
local selectionPropertiesMap = {}
local selectionCommonPropertyValuesMap = {}
local selectionPropertyValuesChangedConnections = {}

local selectionChanged
local selectionChangedEvent = Instance.new("BindableEvent")
local selectionColorsChangedEvent = Instance.new("BindableEvent")

local getClassPropertiesFilterParams = {
    IncludeInheritedMembers = false,

    FilterCallback = function(propertyClass, propertyInfo)
        local propertyName = propertyInfo.Name
        local tags = propertyInfo.Tags
        local security = propertyInfo.Security

        if (tags) then
            if (
                table.find(tags, "Deprecated") or
                table.find(tags, "ReadOnly") or
                table.find(tags, "Hidden") or
                table.find(tags, "NotScriptable")
            ) then return false end
        end

        if (
            (security.Write == "NotAccessibleSecurity") or
            (security.Write == "RobloxSecurity") or
            (security.Write == "RobloxScriptSecurity") or
            (security.Read == "RobloxSecurity") or
            (security.Read == "RobloxScriptSecurity")
        ) then return false end

        -- DataModelMesh.VertexColor is a Vector3 for some reason
        if ((propertyClass == "DataModelMesh") and (propertyName == "VertexColor")) then return true end

        local valueType = propertyInfo.ValueType.Name
        return (valueType == "Color3") or (valueType == "BrickColor") or (valueType == "ColorSequence")
    end,
}

local mapsHaveSameKeys = function(map1, map2)
    for key in pairs(map1) do
        if (not map2[key]) then
            return false
        end
    end

    for key in pairs(map2) do
        if (not map1[key]) then
            return false
        end
    end

    return true
end

local getSafeSelection = function()
    local rawSelection = Selection:Get()
	local safeSelection = {}

	for i = 1, #rawSelection do
		local obj = rawSelection[i]

        --[[
            To check if an Instance is "safe", we query its ClassName to:
                - Check if we pass security check
                - Make sure it isn't blank, which is a thing that can happen apparently
        ]]
		local passesSecurityCheck, hasValidClassName = pcall(function()
			return (obj.ClassName ~= "")
		end)

		if (passesSecurityCheck and hasValidClassName) then
			table.insert(safeSelection, obj)
		end
	end

	return safeSelection
end

local updateSelectionProperties = function()
    local newClassMap = {}
    local newPropertiesMap = {}

    for i = 1, #selection do
        local filteredHierarchy = APIData:GetClassHierarchy(selection[i].ClassName, newClassMap)

        for j = 1, #filteredHierarchy do
            newClassMap[filteredHierarchy[j]] = true
        end
    end

    if (mapsHaveSameKeys(newClassMap, selectionClassMap)) then return end

    for className in pairs(newClassMap) do
        local properties = APIData:GetClassProperties(className, getClassPropertiesFilterParams)

        for propertyClassName, classProperties in pairs(properties) do
            for j = 1, #classProperties do
                newPropertiesMap[classProperties[j]] = propertyClassName
            end
        end
    end

    selectionClassMap = newClassMap
    selectionPropertiesMap = newPropertiesMap
end

local updateSelectionCommonPropertyValues
updateSelectionCommonPropertyValues = function()
    if (debounce) then return end
    debounce = true

    for i = #selectionPropertyValuesChangedConnections, 1, -1 do
        selectionPropertyValuesChangedConnections[i]:Disconnect()
    end

    local newCommonPropertyValues = {}
    table.clear(selectionPropertyValuesChangedConnections)

    for propertyData, propertyClassName in pairs(selectionPropertiesMap) do
        local propertyName = propertyData.Name
        local isNative = APIData:IsClassMemberNative(propertyClassName, "Property", propertyName)
        local classCommonPropertyValues = newCommonPropertyValues[propertyClassName]
        local commonPropertyValues

        if (not classCommonPropertyValues) then
            newCommonPropertyValues[propertyClassName] = {}
            classCommonPropertyValues = newCommonPropertyValues[propertyClassName]
        end

        classCommonPropertyValues[propertyName] = {}
        commonPropertyValues = classCommonPropertyValues[propertyName]

        for i = 1, #selection do
            local obj = selection[i]

            if (obj:IsA(propertyClassName)) then
                table.insert(commonPropertyValues, APIInterface:GetProperty(obj, propertyName, propertyClassName, true))

                if (isNative and shouldListenForPropertyChanges) then
                    table.insert(selectionPropertyValuesChangedConnections, obj:GetPropertyChangedSignal(propertyName):Connect(updateSelectionCommonPropertyValues))
                end
            end
        end
    end

    for _, propertyValues in pairs(newCommonPropertyValues) do
        for propertyName, values in pairs(propertyValues) do
            if (#values == 1) then
                propertyValues[propertyName] = values[1]
            elseif (#values < 1) then
                propertyValues[propertyName] = nil
            else
                local controlValue = values[1]
                local controlValueIsCommon = true

                for i = 2, #values do
                    if (values[i] ~= controlValue) then
                        controlValueIsCommon = false
                        break
                    end
                end

                propertyValues[propertyName] = controlValueIsCommon and controlValue or nil
            end
        end
    end

    selectionCommonPropertyValuesMap = newCommonPropertyValues
    selectionColorsChangedEvent:Fire()
    debounce = false
end

local onSelectionChanged = function()
    if (not isAPIReady) then return end

    selection = getSafeSelection()
    updateSelectionProperties()
    updateSelectionCommonPropertyValues()

    selectionChangedEvent:Fire()
end

---

local SelectionManager = {}
SelectionManager.SelectionChanged = selectionChangedEvent.Event
SelectionManager.SelectionColorsChanged = selectionColorsChangedEvent.Event

SelectionManager.GetColorProperties = function()
    return selectionPropertiesMap
end

SelectionManager.GetCommonColorPropertyValues = function()
    return selectionCommonPropertyValuesMap
end

SelectionManager.RegenerateCommonColorPropertyValues = function()
    if (not isAPIReady) then return end

    updateSelectionCommonPropertyValues()
end

SelectionManager.SetListeningForPropertyChanges = function(shouldListen)
    shouldListenForPropertyChanges = shouldListen
end

SelectionManager.GetColorPropertyValuesSnapshot = function()
    if (not isAPIReady) then return {} end

    local snapshot = {}

    for propertyData, propertyClassName in pairs(selectionPropertiesMap) do
        local propertyName = propertyData.Name

        for i = 1, #selection do
            local obj = selection[i]

            if (obj:IsA(propertyClassName)) then
                if (not snapshot[obj]) then
                    snapshot[obj] = {}
                end

                snapshot[obj][propertyName] = APIInterface:GetProperty(obj, propertyName, propertyClassName, true)
            end
        end
    end

    return snapshot
end

SelectionManager.ApplyColorProperty = function(className, propertyName, newColor, setHistoryWaypoint)
    if (not isAPIReady) then return end

    if (setHistoryWaypoint) then
        ChangeHistoryService:SetWaypoint(propertyName)
    end

    for i = 1, #selection do
        local obj = selection[i]

        if (obj:IsA(className)) then
            APIInterface:SetProperty(obj, propertyName, newColor, className, true)
        end
    end

    if (setHistoryWaypoint) then
        ChangeHistoryService:SetWaypoint(propertyName)
    end
end

SelectionManager.ApplyObjectColorProperty = function(obj, className, propertyName, newValue)
    if (not isAPIReady) then return end

    APIInterface:SetProperty(obj, propertyName, newValue, className, true)
end

SelectionManager.Connect = function()
    if (selectionChanged) then return end

    selectionChanged = Selection.SelectionChanged:Connect(onSelectionChanged)
end

SelectionManager.Disconnect = function()
    if (not selectionChanged) then return end

    selectionChanged:Disconnect()
    selectionChanged = nil
end

SelectionManager.init = function(plugin)
    SelectionManager.init = nil

    RobloxAPI.DataRequestFinished:Connect(function(didLoad)
        if (not didLoad) then return end

        APIData = RobloxAPI.APIData
        APIInterface = RobloxAPI.APIInterface
        isAPIReady = true

        SelectionManager.Connect()
        onSelectionChanged()
    end)

    plugin.Unloading:Connect(function()
        if (selectionChanged) then
            selectionChanged:Disconnect()
            selectionChanged = nil
        end

        selectionChangedEvent:Destroy()
        selectionColorsChangedEvent:Destroy()
    end)
end

return SelectionManager