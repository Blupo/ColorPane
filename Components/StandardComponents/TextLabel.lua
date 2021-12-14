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
        LayoutOrder?
        BackgroundTransparency? = 1

        Text
        Font? = Style.StandardFont
        TextSize? = Style.StandardTextSize
        TextXAlignment? = Enum.TextXAlignment.Left
        TextYAlignment? = Enum.TextYAlignment.Center
        TextWrapped?

        BackgroundColor3? = StudioTheme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
        TextColor3? = StudioTheme:GetColor(Enum.StudioStyleGuideColor.MainText)
    
    store props

        theme: StudioTheme
]]

local StandardTextLabel = Roact.PureComponent:extend("StandardTextLabel")

StandardTextLabel.render = function(self)
    local props = self.props
    local theme = props.theme

    return Roact.createElement("TextLabel", {
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        Size = props.Size,
        LayoutOrder = props.LayoutOrder,
        BackgroundTransparency = props.BackgroundTransparency or 1,
        BorderSizePixel = 0,

        Text = props.Text,
        Font = props.Font or Style.StandardFont,
        TextSize = props.TextSize or Style.StandardTextSize,
        TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left,
        TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center,
        TextWrapped = props.TextWrapped,

        BackgroundColor3 = props.BackgroundColor3 or theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
        TextColor3 = props.TextColor3 or theme:GetColor(Enum.StudioStyleGuideColor.MainText)
    }, props[Roact.Children])
end

return ConnectTheme(StandardTextLabel)