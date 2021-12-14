local TextService = game:GetService("TextService")

---

local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardTextLabel = StandardComponents.TextLabel
local StandardUIPadding = StandardComponents.UIPadding

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
    local promptText = string.format("Are your sure you want to delete %s?", palettes[paletteIndex].name)

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
        UIPadding = Roact.createElement(StandardUIPadding, {0, Style.MajorElementPadding}),

        WarningText = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 0.5, -4),

            Size = self.promptWidth:map(function(promptWidth)
                local promptTextHeight = TextService:GetTextSize(
                    promptText,
                    Style.LargeTextSize,
                    Style.StandardFont,
                    Vector2.new(promptWidth - (Style.MajorElementPadding * 2), math.huge)
                ).Y

                return UDim2.new(1, 0, 0, promptTextHeight)
            end),

            Text = promptText,
            TextSize = Style.LargeTextSize,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Bottom,
            TextWrapped = true,
        }),

        Buttons = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0.5, 4),
            Size = UDim2.new(1, 0, 0, Style.StandardButtonSize),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            CancelButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(0.5, -4, 0.5, 0),
                Size = UDim2.new(0, Style.DialogButtonWidth, 0, Style.StandardButtonSize),

                displayType = "text",
                text = "Cancel",

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
                Size = UDim2.new(0, Style.DialogButtonWidth, 0, Style.StandardButtonSize),
                BackgroundTransparency = 0,

                displayType = "text",
                text = "Confirm",

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.ErrorText),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.ErrorText),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText),

                onActivated = function()
                    self.props.removePalette(paletteIndex)
                    self.props.updatePalettePage(1, 1)
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

        removePalette = function(index)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_RemovePalette,
                index = index,
            })
        end,
    }
end)(RemovePalette)