local root = script.Parent.Parent.Parent

local PluginModules = root.PluginModules
local Style = require(PluginModules.Style)

local includes = root.includes
local Roact = require(includes.Roact)

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