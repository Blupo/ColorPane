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
    API.Parent = CoreGui
end