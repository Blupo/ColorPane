local root = script.Parent.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

---

--[[
    props

        circular: boolean?
]]

local StandardUICorner = Roact.PureComponent:extend("StandardUICorner")

StandardUICorner.render = function(self)
    return Roact.createElement("UICorner", {
        CornerRadius = self.props.circular and
            UDim.new(1, 0)
        or UDim.new(0, Style.Constants.StandardCornerRadius),
    })
end

return StandardUICorner