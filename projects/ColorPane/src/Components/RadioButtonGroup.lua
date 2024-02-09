local Common = script.Parent.Parent.Common

local CommonPluginModules = Common.PluginModules
local Style = require(CommonPluginModules.Style)

local CommonIncludes = Common.Includes
local Roact = require(CommonIncludes.RoactRodux.Roact)

local CommonComponents = Common.Components
local ConnectTheme = require(CommonComponents.ConnectTheme)

local StandardComponents = CommonComponents.StandardComponents
local StandardTextLabel = require(StandardComponents.TextLabel)
local StandardUICorner = require(StandardComponents.UICorner)
local StandardUIListLayout = require(StandardComponents.UIListLayout)

---

--[[
    props

        AnchorPoint?
        Size?
        Position?

        selected: number?
        options: array<string>
        onSelected: (number) -> nil

    store props

        theme: StudioTheme
]]

local RadioButtonGroup = Roact.PureComponent:extend("RadioButtonGroup")

RadioButtonGroup.render = function(self)
    local theme = self.props.theme

    local options = self.props.options
    local optionsChildren = {}

    for i = 1, #options do
        optionsChildren[i] = Roact.createElement("TextButton", {
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardInputHeight),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            LayoutOrder = i,

            Text = "",
            TextTransparency = 1,

            [Roact.Event.Activated] = function()
                self.props.onSelected(i)
            end,
        }, {
            RadioButton = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, Style.Constants.StandardInputHeight, 0, Style.Constants.StandardInputHeight),
                Position = UDim2.new(0, 0, 0.5, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 1,

                BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder)
            }, {
                UICorner = Roact.createElement(StandardUICorner, { circular = true }),

                Inner = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Size = UDim2.new(1, -2, 1, -2),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 1,

                    BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
                }, {
                    UICorner = Roact.createElement(StandardUICorner, { circular = true }),
                }),

                Indicator = (self.props.selected == i) and
                    Roact.createElement("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Size = UDim2.new(1, -Style.Constants.SpaciousElementPadding, 1, -Style.Constants.SpaciousElementPadding),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        BackgroundTransparency = 0,
                        BorderSizePixel = 0,
                        ZIndex = 2,

                        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Selected)
                    }, {
                        UICorner = Roact.createElement(StandardUICorner, { circular = true }),
                    })
                or nil,
            }),

            Label = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(1, -(Style.Constants.StandardInputHeight + Style.Constants.SpaciousElementPadding), 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundTransparency = 1,
                Text = options[i],
            })
        })
    end

    optionsChildren.UIListLayout = Roact.createElement(StandardUIListLayout, {
        Padding = UDim.new(0, Style.Constants.MinorElementPadding),

        preset = 1,
    })

    return Roact.createElement("Frame", {
        AnchorPoint = self.props.AnchorPoint,
        Size = self.props.Size,
        Position = self.props.Position,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, optionsChildren)
end

---

return ConnectTheme(RadioButtonGroup)