local Workspace = game:GetService("Workspace")

---

local root = script.Parent.Parent
local Common = root.Common
local CommonIncludes = Common.Includes
local ColorLib = require(CommonIncludes.Color)

local Color, Gradient = ColorLib.Color, ColorLib.Gradient
local Terrain = Workspace.Terrain

---

local colorProperties = {}
local classHierarchy = {}
local materialEnumItems = Enum.Material:GetEnumItems()

---

local ColorAPIData = {}

ColorAPIData.init = function(apiData)
    ColorAPIData.init = nil

    local classes = apiData.Classes

    for i = 1, #classes do
        local class = classes[i]
        local className = class.Name
        local classMembers = class.Members

        classHierarchy[className] = (class.Superclass ~= "<<<ROOT>>>") and class.Superclass or nil

        for j = 1, #classMembers do
            local member = classMembers[j]
            if (member.MemberType ~= "Property") then continue end

            local memberName = member.Name
            local memberSecurity = member.Security
            local memberTags = member.Tags
            local memberValueType = member.ValueType

            -- check for color properties
            if (
                ((className == "DataModelMesh") and (memberName == "VertexColor")) or
                (memberValueType.Name == "BrickColor") or
                (memberValueType.Name == "Color3") or
                (memberValueType.Name == "ColorSequence")
            ) then
                -- check tags
                if (memberTags and (
                    table.find(memberTags, "Deprecated") or
                    table.find(memberTags, "ReadOnly") or
                    table.find(memberTags, "Hidden") or
                    table.find(memberTags, "NotScriptable")
                )) then continue end

                -- check security
                if (
                    (memberSecurity.Write == "NotAccessibleSecurity") or
                    (memberSecurity.Write == "RobloxSecurity") or
                    (memberSecurity.Write == "RobloxScriptSecurity") or
                    (memberSecurity.Read == "RobloxSecurity") or
                    (memberSecurity.Read == "RobloxScriptSecurity")
                ) then continue end

                if (not colorProperties[className]) then
                    colorProperties[className] = {}
                end

                colorProperties[className][memberName] = member
            end
        end
    end

    -- add custom Terrain properties
    if (not colorProperties.Terrain) then
        colorProperties.Terrain = {}
    end

    for _, materialEnumItem in pairs(materialEnumItems) do
        local success = pcall(function()
            Terrain:GetMaterialColor(materialEnumItem)
        end)
    
        if (success) then
            local memberName = materialEnumItem.Name .. " Material"

            local newPropertyData = {
                Name = memberName,
                Custom = true,

                ValueType = {
                    Name = "Color3"
                },

                Get = function(obj)
                    return obj:GetMaterialColor(materialEnumItem)
                end,

                Set = function(obj, color)
                    obj:SetMaterialColor(materialEnumItem, color)
                end
            }

            colorProperties.Terrain[memberName] = newPropertyData
        end
    end
end

ColorAPIData.GetProperty = function(className: string, propertyName: string)
    return colorProperties[className][propertyName]
end

ColorAPIData.GetProperties = function(classNames: {string})
    local properties = {}

    for i = 1, #classNames do
        local className = classNames[i]

        while (className) do
            if (not properties[className]) then
                local classProperties = colorProperties[className]

                if (classProperties) then
                    properties[className] = {}

                    for propertyName, property in pairs(classProperties) do
                        properties[className][propertyName] = property
                    end
                end
            end
            
            className = classHierarchy[className]
        end
    end

    return properties
end

ColorAPIData.TransformColorValue = function(className: string, propertyName: string, value: any)
    local propertyInfo = colorProperties[className][propertyName]
    if (not propertyInfo) then return end

    local valueType = propertyInfo.ValueType.Name

    if ((className == "DataModelMesh") and (propertyName == "VertexColor")) then
        return Vector3.new(value:components())
    elseif (valueType == "Color3") then
        return value:toColor3()
    elseif (valueType == "BrickColor") then
        return value:toBrickColor()
    elseif (valueType == "ColorSequence") then
        return value:colorSequence(nil, "RGB")
    else
        error("Unsupported value type")
    end
end

ColorAPIData.TransformPropertyValue = function(className: string, propertyName: string, value: any)
    local propertyInfo = colorProperties[className][propertyName]
    if (not propertyInfo) then return end

    local valueType = propertyInfo.ValueType.Name

    if ((className == "DataModelMesh") and (propertyName == "VertexColor")) then
        return Color.new(value.X, value.Y, value.Z)
    elseif (valueType == "Color3") then
        return Color.fromColor3(value)
    elseif (valueType == "BrickColor") then
        return Color.fromBrickColor(value)
    elseif (valueType == "ColorSequence") then
        return Gradient.fromColorSequence(value)
    else
        error("Unsupported value type")
    end
end

---

return ColorAPIData