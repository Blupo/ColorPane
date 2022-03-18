local root = script.Parent.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local ConnectTheme = require(Components:FindFirstChild("ConnectTheme"))

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
        BackgroundColor3 = props.useMainBackgroundColor and theme:GetColor(Enum.StudioStyleGuideColor.MainBackground) or theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame),
        BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),

        [Roact.Event.InputBegan] = props[Roact.Event.InputBegan],
        [Roact.Event.InputEnded] = props[Roact.Event.InputEnded]
    }, props[Roact.Children])
end

return ConnectTheme(StandardScrollingFrame)