local root = script.Parent.Parent.Parent

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

---

--[[
    props

        Padding?
        FillDirection? = Enum.FillDirection.Vertical
        HorizontalAlignment? = Enum.HorizontalAlignment.Left
        VerticalAlignment? = Enum.VerticalAlignment.Top
        SortOrder? = Enum.SortOrder.LayoutOrder

        [Roact.Change.AbsoluteContentSize]?

        preset: number(1,2)?
]]

local StandardUIListLayout = Roact.PureComponent:extend("StandardUIListLayout")

StandardUIListLayout.render = function(self)
    local props = self.props
    local preset = props.preset
    local overrides = {}

    if (preset == 1) then
        overrides.FillDirection = Enum.FillDirection.Vertical
        overrides.HorizontalAlignment = Enum.HorizontalAlignment.Left
        overrides.VerticalAlignment = Enum.VerticalAlignment.Top
    elseif (preset == 2) then
        overrides.FillDirection = Enum.FillDirection.Horizontal
        overrides.HorizontalAlignment = Enum.HorizontalAlignment.Right
        overrides.VerticalAlignment = Enum.VerticalAlignment.Center
    end

    return Roact.createElement("UIListLayout", {
        Padding = props.Padding,
        FillDirection = overrides.FillDirection or props.FillDirection or Enum.FillDirection.Vertical,
        HorizontalAlignment = overrides.HorizontalAlignment or props.HorizontalAlignment or Enum.HorizontalAlignment.Left,
        VerticalAlignment = overrides.VerticalAlignment or props.VerticalAlignment or Enum.VerticalAlignment.Top,
        SortOrder = props.SortOrder or Enum.SortOrder.LayoutOrder,

        [Roact.Change.AbsoluteContentSize] = props[Roact.Change.AbsoluteContentSize]
    }, props[Roact.Children])
end

return StandardUIListLayout