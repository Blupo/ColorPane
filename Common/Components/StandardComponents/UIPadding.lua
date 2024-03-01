-- UIPadding component where the paddings are specified in an array

local root = script.Parent.Parent.Parent

local Includes = root.Includes
local Roact = require(Includes.RoactRodux.Roact)

---

--[[
    props
        
        paddings: array<number>

    Notes
        The paddings array must contain either 1, 2, or 4 numbers.
        If it doesn't, an error will occur.

        If only 1 number is provided in the array,
        all paddings are set to that number.

            Top = Bottom = Left = Right = paddings[1]

        If 2 numbers are provided, the top and bottom paddings
        are set to the first number, and the left and right
        paddings are set to the second number.

            Top, Bottom = paddings[1]
            Left, Right = paddings[2]

        If 4 numbers are provided, the paddings are set as such:

            Top = paddings[1]
            Bottom = paddings[2]
            Left = paddings[3]
            Right = paddings[4]
]]

local StandardUIPadding = Roact.PureComponent:extend("StandardUIPadding")

StandardUIPadding.render = function(self)
    local top, bottom, left, right
    local paddings = self.props.paddings

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