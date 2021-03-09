local root = script.Parent.Parent
local includes = root:FindFirstChild("includes")

local Roact = require(includes:FindFirstChild("Roact"))

---

local Padding = Roact.PureComponent:extend("Padding")

Padding.render = function(self)
    local top, bottom, left, right

    if (#self.props == 1) then
        top, bottom, left, right = self.props[1], self.props[1], self.props[1], self.props[1]
    elseif (#self.props == 2) then
        top, bottom, left, right = self.props[1], self.props[1], self.props[2], self.props[2]
    elseif (#self.props == 4) then
        top, bottom, left, right = self.props[1], self.props[2], self.props[3], self.props[4]
    end

    return Roact.createElement("UIPadding", {
        PaddingTop = UDim.new(0, top),
        PaddingBottom = UDim.new(0, bottom),
        PaddingLeft = UDim.new(0, left),
        PaddingRight = UDim.new(0, right),
    })
end

return Padding