local root = script.Parent.Parent

local PluginModules = root.PluginModules
local Style = require(PluginModules.Style)

local Includes = root.Includes
local Roact = require(Includes.RoactRodux.Roact)

local Components = root.Components
local Button = require(Components.Button)
local ConnectTheme = require(Components.ConnectTheme)

local StandardComponents = Components.StandardComponents
local StandardTextLabel = require(StandardComponents.TextLabel)
local StandardUIPadding = require(StandardComponents.UIPadding)

---

--[[
    props
        promptText: string
        cancelText: string
        confirmText: string

        onDone: (boolean)

    store props
        theme: StudioTheme
]]

local Prompt = Roact.PureComponent:extend("Prompt")

Prompt.render = function(self)
    local theme = self.props.theme

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
    }, {
        UIPadding = Roact.createElement(StandardUIPadding, {Style.Constants.PagePadding}),

        PromptText = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, -(Style.UDim2.DialogButtonSize.Y.Offset + Style.Constants.MinorElementPadding)),

            Text = self.props.promptText,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextWrapped = true,
            RichText = true,
        }),

        CancelButton = Roact.createElement(Button, {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(0.5, -Style.Constants.MinorElementPadding, 1, 0),
            Size = UDim2.new(0, Style.Constants.DialogButtonWidth + 10, 0, Style.Constants.StandardButtonHeight),

            backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton),
            borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
            hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton, Enum.StudioStyleGuideModifier.Hover),
            displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonText),

            displayType = "text",
            text = self.props.cancelText,

            onActivated = function()
                self.props.onDone(false)
            end
        }),

        ConfirmButton = Roact.createElement(Button, {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0.5, Style.Constants.MinorElementPadding, 1, 0),
            Size = UDim2.new(0, Style.Constants.DialogButtonWidth + 10, 0, Style.Constants.StandardButtonHeight),

            backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.ErrorText),
            borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
            hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.ErrorText),
            displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText),

            displayType = "text",
            text = self.props.confirmText,

            onActivated = function()
                self.props.onDone(true)
            end
        })
    })
end

return ConnectTheme(Prompt)