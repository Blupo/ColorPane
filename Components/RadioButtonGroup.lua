local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local ConnectTheme = require(Components:FindFirstChild("ConnectTheme"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardTextLabel = StandardComponents.TextLabel
local StandardUICorner = StandardComponents.UICorner
local StandardUIListLayout = StandardComponents.UIListLayout

---

--[[
    props

        AnchorPoint?
        Size?
        Position?

        selected: number?,
        options: array<string>,
        onSelected: (number)
]]

local RadioButtonGroup = Roact.PureComponent:extend("RadioButtonGroup")

RadioButtonGroup.init = function(self, initProps)
    self:setState({
        selected = initProps.selected,
    })
end

RadioButtonGroup.render = function(self)
    local theme = self.props.theme

    local options = self.props.options
    local optionsChildren = {}

    for i = 1, #options do
        optionsChildren[i] = Roact.createElement("TextButton", {
            Size = UDim2.new(1, 0, 0, Style.StandardInputHeight),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            LayoutOrder = i,

            Text = "",
            TextTransparency = 1,

            [Roact.Event.Activated] = function()
                self:setState({
                    selected = i,
                })

                self.props.onSelected(i, options[i])
            end,
        }, {
            RadioButton = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, Style.StandardInputHeight, 0, Style.StandardInputHeight),
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

                Indicator = (self.state.selected == i) and
                    Roact.createElement("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Size = UDim2.new(1, -Style.SpaciousElementPadding, 1, -Style.SpaciousElementPadding),
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
                Size = UDim2.new(1, -(Style.StandardInputHeight + Style.SpaciousElementPadding), 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundTransparency = 1,
                Text = options[i],
            })
        })
    end

    optionsChildren.UIListLayout = Roact.createElement(StandardUIListLayout, {
        Padding = UDim.new(0, Style.MinorElementPadding),

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