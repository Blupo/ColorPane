--!strict
-- Plugin that exposes the ColorPane API script for testing

local ColorPane = script.Parent.ColorPane
require(ColorPane)(plugin, "CPTester")

local APIScript = ColorPane.API
APIScript.Parent = game:GetService("Workspace")
APIScript.Archivable = false

plugin.Unloading:Connect(function()
    APIScript:Destroy()
end)