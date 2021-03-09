local CoreGui = game:GetService("CoreGui")

---

local root = script.Parent
local API = root:FindFirstChild("API")

---

if (CoreGui:FindFirstChild("ColorPane")) then
    warn("ColorPane is already loaded")
else
    API.Archivable = false
    API.Name = "ColorPane"

    require(API).init(plugin)
    
    local success = pcall(function()
        API.Parent = CoreGui
    end)

    if (not success) then
        warn("ColorPane requires script injection to expose the API to developers. Please allow the permission and reload the plugin.")
    end
end