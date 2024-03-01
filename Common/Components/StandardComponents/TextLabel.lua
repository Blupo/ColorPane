-- Standard TextLabel component with theme coloring

local root = script.Parent.Parent.Parent

local PluginModules = root.PluginModules
local Style = require(PluginModules.Style)

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
        LayoutOrder?
        BackgroundTransparency? = 1

        Text
        Font? = Style.Fonts.Standard
        TextSize? = Style.Constants.StandardTextSize
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
        Font = props.Font or Style.Fonts.Standard,
        TextSize = props.TextSize or Style.Constants.StandardTextSize,
        TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left,
        TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center,
        TextWrapped = props.TextWrapped,

        BackgroundColor3 = props.BackgroundColor3 or theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
        TextColor3 = props.TextColor3 or theme:GetColor(Enum.StudioStyleGuideColor.MainText)
    }, props[Roact.Children])
end

return ConnectTheme(StandardTextLabel)