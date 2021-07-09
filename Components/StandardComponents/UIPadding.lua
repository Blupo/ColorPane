local root = script.Parent.Parent.Parent

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

---

--[[
    props: array<number>

        If 1 number is provided:
            Top = Bottom = Left = Right = props[1]
        If 2 numbers are provided:
            Top, Bottom = props[1]
            Left, Right = props[2]
        If 4 numbers are provided:
            Top = props[1]
            Bottom = props[2]
            Left = props[3]
            Right = props[4]
]]

local StandardUIPadding = Roact.PureComponent:extend("StandardUIPadding")

StandardUIPadding.render = function(self)
    local top, bottom, left, right
    local paddings = self.props

    if (#paddings == 1) then
        top, bottom, left, right = paddings[1], paddings[1], paddings[1], paddings[1]
    elseif (#paddings == 2) then
        top, bottom, left, right = paddings[1], paddings[1], paddings[2], paddings[2]
    elseif (#paddings == 4) then
        top, bottom, left, right = paddings[1], paddings[2], paddings[3], paddings[4]
    end

    return Roact.createElement("UIPadding", {
        PaddingTop = UDim.new(0, top),
        PaddingBottom = UDim.new(0, bottom),
        PaddingLeft = UDim.new(0, left),
        PaddingRight = UDim.new(0, right),
    })
end

return StandardUIPadding