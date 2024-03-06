--[[
    UICorner component that can either be round
    or use the standard style corner radius
]]

local root = script.Parent.Parent.Parent

local Modules = root.Modules
local Style = require(Modules.Style)

local Includes = root.Includes
local Roact = require(Includes.RoactRodux.Roact)

---

--[[
    props
        circular: boolean?
]]

local StandardUICorner = Roact.PureComponent:extend("StandardUICorner")

StandardUICorner.render = function(self)
    return Roact.createElement("UICorner", {
        CornerRadius = if self.props.circular then
            UDim.new(1, 0)
        else UDim.new(0, Style.Constants.StandardCornerRadius),
    })
end

return StandardUICorner