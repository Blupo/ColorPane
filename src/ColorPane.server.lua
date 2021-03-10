local CoreGui = game:GetService("CoreGui")

---

local root = script.Parent
local API = root:FindFirstChild("API")

local PluginModules = root:FindFirstChild("PluginModules")
local MakeToolbar = require(PluginModules:FindFirstChild("MakeToolbar"))

---

local toolbarComponents = MakeToolbar(plugin)
local reloadButton = toolbarComponents.ReloadButton

local dropAPI = function()
    local success = pcall(function()
        API.Parent = CoreGui
    end)

    if (success) then
        reloadButton.Enabled = false
    else
        warn("ColorPane requires script injection to expose the API to developers. Please allow the permission and reload the plugin or use the Reload button in the toolbar.")
    end
end

---

if (CoreGui:FindFirstChild("ColorPane")) then
    warn("ColorPane is already loaded")
end

reloadButton.Click:Connect(dropAPI)

API.Archivable = false
API.Name = "ColorPane"
require(API).init(plugin)

dropAPI()