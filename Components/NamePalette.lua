local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PaletteUtils = require(PluginModules:FindFirstChild("PaletteUtils"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local TextInput = require(Components:FindFirstChild("TextInput"))

---

--[[

    props

        paletteIndex: number?
        onPromptClosed: (boolean) -> nil
]]

local RenamePalette = Roact.PureComponent:extend("RenamePalette")

RenamePalette.init = function(self, initProps)
    local palettes = initProps.palettes
    local paletteIndex = initProps.paletteIndex

    self:setState({
        newPaletteName = paletteIndex and palettes[paletteIndex].name or "New Palette"
    })
end

RenamePalette.render = function(self)
    local theme = self.props.theme
    local palettes = self.props.palettes

    local paletteIndex = self.props.paletteIndex
    local selectedPalette = palettes[paletteIndex]

    local newPaletteName = self.state.newPaletteName
    local actualNewPaletteName = PaletteUtils.getNewPaletteName(palettes, newPaletteName, paletteIndex)
    
    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        PromptLabel = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, Style.StandardTextSize),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Font = Style.StandardFont,
            TextSize = Style.StandardTextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Text = selectedPalette and "Rename " .. selectedPalette.name or "Name the Palette",

            TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
        }),

        NameInput = Roact.createElement(TextInput, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, Style.StandardTextSize + Style.MinorElementPadding),
            Size = UDim2.new(1, 0, 0, Style.LargeButtonSize),

            Text = newPaletteName,
            TextSize = Style.LargeTextSize,

            onSubmit = function(newText)
                self:setState({
                    newPaletteName = newText
                })
            end,

            canClear = false,
        }),

        NameIsOKLabel = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, Style.StandardTextSize + Style.LargeButtonSize + (Style.MinorElementPadding * 2)),
            Size = UDim2.new(1, 0, 0, Style.StandardTextSize),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Font = Style.StandardFont,
            TextSize = Style.StandardTextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Text = (newPaletteName ~= actualNewPaletteName) and ("The palette will be renamed to '" .. actualNewPaletteName .. "'") or "The palette name is OK",

            TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
        }),

        Buttons = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, (Style.StandardTextSize * 2) + Style.LargeButtonSize + (Style.MinorElementPadding * 3)),
            Size = UDim2.new(1, 0, 0, Style.StandardButtonSize),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            UIListLayout = Roact.createElement("UIListLayout", {
                Padding = UDim.new(0, Style.SpaciousElementPadding),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            }),

            CancelButton = Roact.createElement(Button, {
                Size = UDim2.new(0, Style.DialogButtonWidth, 0, Style.StandardButtonSize),
                LayoutOrder = 0,

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
                Size = UDim2.new(0, Style.DialogButtonWidth, 0, Style.StandardButtonSize),
                LayoutOrder = 0,

                displayType = "text",
                text = "OK",

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton, Enum.StudioStyleGuideModifier.Hover),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText),

                onActivated = function()
                    if (selectedPalette) then
                        self.props.changePaletteName(selectedPalette.name, actualNewPaletteName)
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

        changePaletteName = function(oldPaletteName, newPaletteName)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_ChangePaletteName,
                name = oldPaletteName,
                newName = newPaletteName
            })
        end
    }
end)(RenamePalette)