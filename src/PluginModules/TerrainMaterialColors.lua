local Workspace = game:GetService("Workspace")

---

local root = script.Parent.Parent
local PluginModules = root:FindFirstChild("PluginModules")
local util = require(PluginModules:FindFirstChild("util"))

local Terrain = Workspace.Terrain

---

local copy = util.copy

local terrainMaterialColorProperties = {}
local terrainMaterialColorBehaviours = {}
local materialEnumItems = Enum.Material:GetEnumItems()

local propertyDataTemplate = {
    Category = "Terrain Colors",
    MemberType = "Property",
    
    Security = {
        Read = "None",
        Write = "None",
    },
    
    Serialization = {
        CanLoad = false,
        CanSave = false,
    },
    
    ValueType = {
        Category = "DataType",
        Name = "Color3"
    },

    ThreadSafety = "ReadOnly",
}

for _, materialEnumItem in pairs(materialEnumItems) do
    local success = pcall(function()
        Terrain:GetMaterialColor(materialEnumItem)
    end)

    if success then
        local newPropertyData = copy(propertyDataTemplate)
        newPropertyData.Name = materialEnumItem.Name .. " Color"

        local newPropertyBehaviour = {
            Get = function(terrain)
                return terrain:GetMaterialColor(materialEnumItem)
            end,
            
            Set = function(terrain, color)
                terrain:SetMaterialColor(materialEnumItem, color)
            end,
        }

        terrainMaterialColorProperties[#terrainMaterialColorProperties + 1] = newPropertyData
        terrainMaterialColorBehaviours[#terrainMaterialColorBehaviours + 1] = newPropertyBehaviour
    end
end

return {
    Properties = terrainMaterialColorProperties,
    Behaviours = terrainMaterialColorBehaviours
}