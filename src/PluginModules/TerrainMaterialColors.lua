local Workspace = game:GetService("Workspace")

---

local root = script.Parent.Parent
local PluginModules = root:FindFirstChild("PluginModules")
local Util = require(PluginModules:FindFirstChild("Util"))

local Terrain = Workspace.Terrain

---

local copy = Util.copy

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

        table.insert(terrainMaterialColorProperties, newPropertyData)
        table.insert(terrainMaterialColorBehaviours, newPropertyBehaviour)
    end
end

return {
    Properties = terrainMaterialColorProperties,
    Behaviours = terrainMaterialColorBehaviours
}