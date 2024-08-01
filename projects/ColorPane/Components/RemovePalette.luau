-- A dialog for removing a palette

local TextService = game:GetService("TextService")

---

local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local Style = require(CommonModules.Style)
local Translator = require(CommonModules.Translator)

local CommonIncludes = Common.Includes
local Roact = require(CommonIncludes.RoactRodux.Roact)
local RoactRodux = require(CommonIncludes.RoactRodux.RoactRodux)

local CommonComponents = Common.Components
local Button = require(CommonComponents.Button)

local StandardComponents = CommonComponents.StandardComponents
local StandardTextLabel = require(StandardComponents.TextLabel)
local StandardUIPadding = require(StandardComponents.UIPadding)

local Modules = root.Modules
local Enums = require(Modules.Enums)

---

local uiTranslations = Translator.GenerateTranslationTable({
    "DeletePalette_Confirm_ButtonText",
    "Cancel_ButtonText",
})

---

--[[
    props
        paletteIndex: number,
        onPromptClosed: (boolean) -> nil

    store props
        theme: StudioTheme
        palettes: array<Palette>

        updatePalettePage: (number, number) -> nil
        removePalette: (number) -> nil
]]

local RemovePalette = Roact.PureComponent:extend("RemovePalette")

RemovePalette.init = function(self)
    self.promptWidth, self.updatePromptWidth = Roact.createBinding(0)
end

RemovePalette.render = function(self)
    local theme = self.props.theme
    local palettes = self.props.palettes

    local paletteIndex = self.props.paletteIndex
    local promptText = Translator.FormatByKey("DeletePalette_Prompt", { palettes[paletteIndex].name })

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        [Roact.Change.AbsoluteSize] = function(obj)
            self.updatePromptWidth(obj.AbsoluteSize.X)
        end
    }, {
        UIPadding = Roact.createElement(StandardUIPadding, {
            paddings = {0, Style.Constants.MajorElementPadding}
        }),

        WarningText = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 0.5, -4),

            Size = self.promptWidth:map(function(promptWidth)
                local promptTextHeight = TextService:GetTextSize(
                    promptText,
                    Style.Constants.LargeTextSize,
                    Style.Fonts.Standard,
                    Vector2.new(promptWidth - (Style.Constants.MajorElementPadding * 2), math.huge)
                ).Y

                return UDim2.new(1, 0, 0, promptTextHeight)
            end),

            Text = promptText,
            TextSize = Style.Constants.LargeTextSize,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Bottom,
            TextWrapped = true,
        }),

        Buttons = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0.5, 4),
            Size = Style.UDim2.ButtonBarSize,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            CancelButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(0.5, -4, 0.5, 0),
                Size = Style.UDim2.DialogButtonSize,

                displayType = "text",
                text = uiTranslations["Cancel_ButtonText"],

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton, Enum.StudioStyleGuideModifier.Hover),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonText),

                onActivated = function()
                    self.props.onPromptClosed(false)
                end
            }),

            ConfirmButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0.5, 4, 0.5, 0),
                Size = Style.UDim2.DialogButtonSize,
                BackgroundTransparency = 0,

                displayType = "text",
                text = uiTranslations["DeletePalette_Confirm_ButtonText"],

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.ErrorText),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.ErrorText),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText),

                onActivated = function()
                    self.props.updatePalettePage(1, 1)
                    self.props.removePalette(paletteIndex)
                    self.props.onPromptClosed(true)
                end
            }),
        }),
    })
end

---

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,
        palettes = state.colorEditor.palettes,
    }
end, function(dispatch)
    return {
        updatePalettePage = function(section, page)
            dispatch({
                type = Enums.StoreActionType.UpdateSessionData,
                slice = {
                    lastPalettePage = {section, page}
                }
            })
        end,

        removePalette = function(paletteIndex)
            dispatch({
                type = Enums.StoreActionType.ColorEditor_RemovePalette,
                paletteIndex = paletteIndex,
            })
        end,
    }
end)(RemovePalette)