local root = script.Parent.Parent

local PluginModules = root.PluginModules
local Style = require(PluginModules.Style)
local Translator = require(PluginModules.Translator)

local includes = root.includes
local Roact = require(includes.Roact)

local Components = root.Components
local Button = require(Components.Button)
local ConnectTheme = require(Components.ConnectTheme)

local StandardComponents = require(Components.StandardComponents)
local StandardTextLabel = StandardComponents.TextLabel
local StandardUIPadding = StandardComponents.UIPadding

---

local uiTranslations = Translator.GenerateTranslationTable({
    "FirstTimeSetup_Prompt",
    "FirstTimeSetup_Confirm_ButtonText",
})

---

--[[
    props

        onConfirm: () -> nil
    
    store props

        theme: StudioTheme
]]

local FirstTimeSetup = Roact.PureComponent:extend("FirstTimeSetup")

FirstTimeSetup.render = function(self)
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

        Notice = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.new(1, 0, 1, -(Style.Constants.StandardButtonHeight + Style.Constants.SpaciousElementPadding)),
            Position = UDim2.new(0.5, 0, 0, 0),

            Text = uiTranslations["FirstTimeSetup_Prompt"],
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
        }),

        ConfirmButton = Roact.createElement(Button, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(0, 90, 0, Style.Constants.StandardButtonHeight),

            displayType = "text",
            text = uiTranslations["FirstTimeSetup_Confirm_ButtonText"],

            backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton),
            borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
            hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton, Enum.StudioStyleGuideModifier.Hover),
            displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText),

            disabledBackgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton, Enum.StudioStyleGuideModifier.Disabled),
            disabledDisplayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText, Enum.StudioStyleGuideModifier.Disabled),

            onActivated = self.props.onConfirm,
        }),
    })
end

return ConnectTheme(FirstTimeSetup)