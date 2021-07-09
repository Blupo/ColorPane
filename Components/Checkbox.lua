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

---

--[[
    props

        AnchorPoint?
        Position?
        Size?
        LayoutOrder?

        disabled: boolean?
        value: boolean
        text: string
        onChecked: (boolean) -> nil
]]

local Checkbox = Roact.PureComponent:extend("Checkbox")

Checkbox.render = function(self)
    local theme = self.props.theme
    local disabled = self.props.disabled

    return Roact.createElement("Frame", {
        AnchorPoint = self.props.AnchorPoint,
        Position = self.props.Position,
        Size = self.props.Size,
        LayoutOrder = self.props.LayoutOrder,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        CheckboxBorder = Roact.createElement("TextButton", {
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, Style.StandardButtonSize, 0, Style.StandardButtonSize),
            AutoButtonColor = false,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            Text = "",
            TextTransparency = 1,

            BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder),

            [Roact.Event.MouseButton1Click] = function()
                if (disabled) then return end

                self.props.onChecked(not self.props.value)
            end
        }, {
            CheckboxBackground = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
            }, {
                UICorner = Roact.createElement(StandardUICorner),
            }),

            CheckboxIndicator = self.props.value and
                Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(1, -Style.SpaciousElementPadding, 1, -Style.SpaciousElementPadding),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,

                    BackgroundColor3 = theme:GetColor(
                        Enum.StudioStyleGuideColor.InputFieldBorder,
                        disabled and Enum.StudioStyleGuideModifier.Disabled or Enum.StudioStyleGuideModifier.Selected
                    ),
                }, {
                    UICorner = Roact.createElement(StandardUICorner),
                })
            or nil,

            UICorner = Roact.createElement(StandardUICorner),
        }),

        Text = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(1, -(Style.StandardButtonSize + Style.SpaciousElementPadding), 1, 0),

            Text = self.props.text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
        })
    })
end

return ConnectTheme(Checkbox)