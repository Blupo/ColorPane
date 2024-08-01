-- Standard ScrollingFrame component with theme coloring

local root = script.Parent.Parent.Parent

local Modules = root.Modules
local Style = require(Modules.Style)

local Includes = root.Includes
local Roact = require(Includes.RoactRodux.Roact)

local Components = root.Components
local ConnectTheme = require(Components.ConnectTheme)

---

--[[
    props
        AnchorPoint?
        Position?
        Size?
        CanvasSize?

        BackgroundTransparency? = 0
        BorderSizePixel? = 1

        [Roact.Event.InputBegan]?
        [Roact.Event.InputEnded]?

        useMainBackgroundColor: boolean?
    
    store props
        theme: StudioTheme
]]

local StandardScrollingFrame = Roact.PureComponent:extend("StandardScrollingFrame")

StandardScrollingFrame.render = function(self)
    local props = self.props
    local theme = props.theme

    return Roact.createElement("ScrollingFrame", {
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        Size = props.Size,
        BackgroundTransparency = props.BackgroundTransparency or 0,
        BorderSizePixel = props.BorderSizePixel or 1,
        ClipsDescendants = true,

        CanvasPosition = Vector2.new(0, 0),
        CanvasSize = props.CanvasSize,
        TopImage = Style.Images.ScrollbarImage,
        MidImage = Style.Images.ScrollbarImage,
        BottomImage = Style.Images.ScrollbarImage,
        HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
        VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
        VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right,
        ScrollBarThickness = Style.Constants.ScrollbarThickness,

        ScrollBarImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ScrollBar),
        BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),

        BackgroundColor3 = if props.useMainBackgroundColor then
            theme:GetColor(Enum.StudioStyleGuideColor.ScrollBarBackground)
        else theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame),

        [Roact.Event.InputBegan] = props[Roact.Event.InputBegan],
        [Roact.Event.InputEnded] = props[Roact.Event.InputEnded]
    }, props[Roact.Children])
end

return ConnectTheme(StandardScrollingFrame)