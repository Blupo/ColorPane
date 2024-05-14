-- A checkbox

local root = script.Parent.Parent

local Modules = root.Modules
local Style = require(Modules.Style)

local Includes = root.Includes
local Roact = require(Includes.RoactRodux.Roact)

local Components = root.Components
local ConnectTheme = require(Components.ConnectTheme)

local StandardComponents = Components.StandardComponents
local StandardTextLabel = require(StandardComponents.TextLabel)
local StandardUICorner = require(StandardComponents.UICorner)

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

    store props
        theme: StudioTheme
]]

local Checkbox = Roact.PureComponent:extend("Checkbox")

Checkbox.init = function(self)
    self:setState({
        hover = false
    })
end

Checkbox.render = function(self)
    local theme = self.props.theme
    local disabled = self.props.disabled
    local hover = self.state.hover

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
            Size = Style.UDim2.StandardButtonSize,
            AutoButtonColor = false,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            Text = "",
            TextTransparency = 1,

            BackgroundColor3 = if disabled then 
                theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder)
            else theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder, if hover then Enum.StudioStyleGuideModifier.Hover else nil),

            [Roact.Event.MouseButton1Click] = function()
                if (disabled) then return end

                self.props.onChecked(not self.props.value)
            end,

            [Roact.Event.MouseEnter] = function()
                if (disabled) then return end

                self:setState({
                    hover = true
                })
            end,

            [Roact.Event.MouseLeave] = function()
                if (disabled) then return end

                self:setState({
                    hover = false
                })
            end
        }, {
            CheckboxBackground = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                BackgroundColor3 = if disabled then
                    theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground)
                else theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground, if hover then Enum.StudioStyleGuideModifier.Hover else nil),
            }, {
                UICorner = Roact.createElement(StandardUICorner),
            }),

            CheckboxIndicator = if self.props.value then
                Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(1, -Style.Constants.SpaciousElementPadding, 1, -Style.Constants.SpaciousElementPadding),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,

                    BackgroundColor3 = theme:GetColor(
                        Enum.StudioStyleGuideColor.InputFieldBorder,
                        if disabled then Enum.StudioStyleGuideModifier.Disabled else Enum.StudioStyleGuideModifier.Selected
                    ),
                }, {
                    UICorner = Roact.createElement(StandardUICorner),
                })
            else nil,

            UICorner = Roact.createElement(StandardUICorner),
        }),

        Text = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(1, -(Style.Constants.StandardButtonHeight + Style.Constants.SpaciousElementPadding), 1, 0),

            Text = self.props.text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,

            TextColor3 = theme:GetColor(
                Enum.StudioStyleGuideColor.MainText,
                if disabled then Enum.StudioStyleGuideModifier.Disabled else nil
            )
        })
    })
end

return ConnectTheme(Checkbox)