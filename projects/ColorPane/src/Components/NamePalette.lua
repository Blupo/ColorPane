local root = script.Parent.Parent
local Common = root.Common

local CommonPluginModules = Common.PluginModules
local Style = require(CommonPluginModules.Style)
local Translator = require(CommonPluginModules.Translator)

local CommonIncludes = Common.Includes
local Roact = require(CommonIncludes.RoactRodux.Roact)
local RoactRodux = require(CommonIncludes.RoactRodux.RoactRodux)

local CommonComponents = Common.Components
local Button = require(CommonComponents.Button)
local StandardComponents = require(CommonComponents.StandardComponents)
local TextInput = require(CommonComponents.TextInput)

local PluginModules = root.PluginModules
local PluginEnums = require(PluginModules.PluginEnums)
local Util = require(PluginModules.Util)

local StandardTextLabel = StandardComponents.TextLabel
local StandardUIListLayout = StandardComponents.UIListLayout

---

local uiTranslations = Translator.GenerateTranslationTable({
    "NamePalette_Prompt",
    "PaletteNameOK_Message",
    "DefaultPaletteName",

    "Cancel_ButtonText",
    "OK_ButtonText",
})

---

--[[
    props

        paletteIndex: number?
        onPromptClosed: (boolean) -> nil

    store props

        theme: StudioTheme
        palettes: array<Palette>

        updatePalettePage: (number, number) -> nil
        addPalette: (string) -> nil
        changePaletteName: (number, string) -> nil
]]

local RenamePalette = Roact.PureComponent:extend("RenamePalette")

RenamePalette.init = function(self, initProps)
    local palettes = initProps.palettes
    local paletteIndex = initProps.paletteIndex

    self:setState({
        newPaletteName = paletteIndex and palettes[paletteIndex].name or uiTranslations["DefaultPaletteName"]
    })
end

RenamePalette.render = function(self)
    local theme = self.props.theme
    local palettes = self.props.palettes

    local paletteIndex = self.props.paletteIndex
    local selectedPalette = palettes[paletteIndex]

    local newPaletteName = self.state.newPaletteName
    local actualNewPaletteName = Util.palette.getNewItemName(palettes, newPaletteName, paletteIndex)
    
    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        PromptLabel = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
            Text = selectedPalette and Translator.FormatByKey("RenamePalette_Prompt", { selectedPalette.name }) or uiTranslations["NamePalette_Prompt"],
        }),

        NameInput = Roact.createElement(TextInput, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, Style.Constants.StandardTextSize + Style.Constants.MinorElementPadding),
            Size = UDim2.new(1, 0, 0, Style.Constants.LargeButtonHeight),

            Text = newPaletteName,
            TextSize = Style.Constants.LargeTextSize,

            onSubmit = function(newText)
                self:setState({
                    newPaletteName = newText
                })
            end,
        }),

        NameIsOKLabel = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, Style.Constants.StandardTextSize + Style.Constants.LargeButtonHeight + (Style.Constants.MinorElementPadding * 2)),
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
            Text = (newPaletteName ~= actualNewPaletteName) and Translator.FormatByKey("PaletteRename_Message", { actualNewPaletteName }) or uiTranslations["PaletteNameOK_Message"],
        }),

        Buttons = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, (Style.Constants.StandardTextSize * 2) + Style.Constants.LargeButtonHeight + (Style.Constants.MinorElementPadding * 3)),
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardButtonHeight),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            UIListLayout = Roact.createElement(StandardUIListLayout, {
                Padding = UDim.new(0, Style.Constants.SpaciousElementPadding),
                
                preset = 2,
            }),

            CancelButton = Roact.createElement(Button, {
                Size = Style.UDim2.DialogButtonSize,
                LayoutOrder = 0,

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
                Size = Style.UDim2.DialogButtonSize,
                LayoutOrder = 0,

                displayType = "text",
                text = uiTranslations["OK_ButtonText"],

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton, Enum.StudioStyleGuideModifier.Hover),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText),

                onActivated = function()
                    if (selectedPalette) then
                        self.props.changePaletteName(paletteIndex, actualNewPaletteName)
                    else
                        self.props.addPalette(newPaletteName)
                        self.props.updatePalettePage(2, #palettes + 1)
                    end

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
                type = PluginEnums.StoreActionType.UpdateSessionData,
                slice = {
                    lastPalettePage = {section, page}
                }
            })
        end,

        addPalette = function(name)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_AddPalette,
                name = name
            })
        end,

        changePaletteName = function(index, newName)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_ChangePaletteName,
                index = index,
                newName = newName,
            })
        end
    }
end)(RenamePalette)