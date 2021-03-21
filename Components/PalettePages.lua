local TextService = game:GetService("TextService")

---

local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local Style = require(PluginModules:FindFirstChild("Style"))
local util = require(PluginModules:FindFirstChild("util"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local BuiltInPalettes = require(Components:FindFirstChild("BuiltInPalettes"))
local Button = require(Components:FindFirstChild("Button"))
local Padding = require(Components:FindFirstChild("Padding"))
local Pages = require(Components:FindFirstChild("Pages"))
local Palette = require(Components:FindFirstChild("Palette"))
local TextInput = require(Components:FindFirstChild("TextInput"))

---

local DELETE_PROMPT_TEXT = "Are you sure you want to permanently delete\n\n%s?"

local DISALLOWED_PALETTE_NAMES = {
    brickcolor = true,
    brickcolors = true,
    colorbrewer = true,
    ["web colors"] = true,
}

local shallowCompare = util.shallowCompare

---

local PalettePages = Roact.Component:extend("PalettePages")

PalettePages.init = function(self)
    self.prompt = Roact.createRef()

    self:setState({
        showRemovePalettePrompt = false,
        promptWidth = 0
    })
end

PalettePages.shouldUpdate = function(self, nextProps, nextState)
    local propsDiff = shallowCompare(self.props, nextProps)
    local stateDiff = shallowCompare(self.state, nextState)

    if (#stateDiff > 0) then return true end

    if ((#propsDiff == 1) and (propsDiff[1] ~= "palettes")) then
        -- props.lastPaletteModification will tell us if the palettes changed without having to compare them
        return true
    elseif (#propsDiff > 1) then
        return true
    end

    return false
end

PalettePages.didMount = function(self)
    local prompt = self.prompt:getValue()
    if (not prompt) then return end

    self:setState({
        promptWidth = prompt.AbsoluteSize.X
    })
end

PalettePages.render = function(self)
    local palettes = self.props.palettes
    local theme = self.props.theme

    local currentPage = self.props.lastPalettePage
    local displayPage

    local promptText = self.state.showRemovePalettePrompt and
        string.format(DELETE_PROMPT_TEXT, self.state.removePaletteName)
    or nil

    local promptTextHeight = self.state.showRemovePalettePrompt and
        TextService:GetTextSize(
            promptText,
            Style.LargeTextSize,
            Style.StandardFont,
            Vector2.new(self.state.promptWidth - (Style.MajorElementPadding * 2), math.huge)
        ).Y
    or nil

    local numBuiltInPalettes = #BuiltInPalettes
    local palettePages = {}

    for i = 1, numBuiltInPalettes do
        local palette = BuiltInPalettes[i]

        palettePages[#palettePages + 1] = {
            name = palette.name,
            content = palette.getContent()
        }
    end

    for i = 1, #palettes do
        local palette = palettes[i]

        palettePages[#palettePages + 1] = {
            name = palette.name,

            content = Roact.createElement(Palette, {
                palette = palette
            })
        }
    end

    if (not (self.state.showRemovePalettePrompt or self.state.showRenamePalettePrompt)) then
        displayPage = Roact.createElement(Pages, {
            initPage = currentPage,
            pages = palettePages,
            onPageChanged = self.props.updatePalettePage,

            options = {
                {
                    name = "Create a New Palette",
                    onActivated = function()
                        local newPage = (#palettes + 1) + numBuiltInPalettes

                        self:setState({
                            currentPage = newPage,
                            showRemovePalettePrompt = false,
                            removePaletteName = Roact.None,
                        })

                        self.props.updatePalettePage(newPage)
                        self.props.addPalette()
                    end
                },

                (currentPage > numBuiltInPalettes) and {
                    name = "Rename this Palette",
                    onActivated = function()
                        self:setState({
                            showRenamePalettePrompt = true,
                            renamePaletteName = palettePages[currentPage].name,
                            newPaletteName = palettePages[currentPage].name,
                        })
                    end
                } or nil,

                (currentPage > numBuiltInPalettes) and {
                    name = "Delete this Palette",
                    onActivated = function()
                        self:setState({
                            showRemovePalettePrompt = true,
                            removePaletteName = palettePages[currentPage].name
                        })
                    end
                } or nil,

                (currentPage > numBuiltInPalettes) and {
                    name = "Duplicate this Palette",
                    onActivated = function()
                        local duplicatePaletteName = palettePages[currentPage].name
                        local newPage = (#palettes + 1) + numBuiltInPalettes

                        self:setState({
                            currentPage = newPage,
                        })

                        self.props.updatePalettePage(newPage)
                        self.props.duplicatePalette(duplicatePaletteName)
                    end
                } or nil,
            }
        })
    elseif (self.state.showRemovePalettePrompt) then
        displayPage = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            [Roact.Ref] = self.prompt,

            [Roact.Change.AbsoluteSize] = function(obj)
                self:setState({
                    promptWidth = obj.AbsoluteSize.X
                })
            end
        }, {
            UIPadding = Roact.createElement(Padding, {0, Style.MajorElementPadding}),

            WarningText = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 0.5, -4),
                Size = UDim2.new(1, 0, 0, promptTextHeight),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Font = Style.StandardFont,
                TextSize = Style.LargeTextSize,
                Text = promptText,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Bottom,

                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),

                [Roact.Ref] = self.promptText,

                [Roact.Change.AbsoluteSize] = function(obj)
                    self:setState({
                        promptTextHeight = obj.TextBounds.Y
                    })
                end
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
                        self:setState({
                            showRemovePalettePrompt = false,
                            removePaletteName = Roact.None,
                        })
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
                        local removePaletteName = self.state.removePaletteName

                        self:setState({
                            currentPage = 1,
                            showRemovePalettePrompt = false,
                            removePaletteName = Roact.None,
                        })

                        self.props.updatePalettePage(1)
                        self.props.removePalette(removePaletteName)
                    end
                }),
            }),
        })
    elseif (self.state.showRenamePalettePrompt) then
        displayPage = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            [Roact.Ref] = self.prompt,

            [Roact.Change.AbsoluteSize] = function(obj)
                self:setState({
                    promptWidth = obj.AbsoluteSize.X
                })
            end
        }, {
            RenameLabel = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, Style.StandardTextSize),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
    
                Font = Style.StandardFont,
                TextSize = Style.StandardTextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                Text = "Rename '" .. self.state.renamePaletteName .. "'",
                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
            }),

            NameInput = Roact.createElement(TextInput, {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, Style.LargeTextSize),
                Size = UDim2.new(1, 0, 0, Style.LargeButtonSize),

                TextSize = Style.LargeTextSize,
                Text = self.state.newPaletteName,

                canClear = false,

                isTextAValidValue = function(text)
                    return (not DISALLOWED_PALETTE_NAMES[string.lower(text)]) and true or false
                end,

                onTextChanged = function(text)
                    self:setState({
                        newPaletteName = text,
                    })
                end
            }),

            Buttons = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, Style.StandardTextSize + Style.LargeButtonSize + (Style.MinorElementPadding * 2)),
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
                        self:setState({
                            showRenamePalettePrompt = false,
                            renamePaletteName = Roact.None,
                            newPaletteName = Roact.None,
                        })
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
                        local oldPaletteName = self.state.renamePaletteName
                        local newPaletteName = self.state.newPaletteName

                        self:setState({
                            showRenamePalettePrompt = false,
                            renamePaletteName = Roact.None,
                            newPaletteName = Roact.None,
                        })

                        if (not newPaletteName) then return end
                        self.props.changePaletteName(oldPaletteName, newPaletteName)
                    end
                }),
            }),
        })
    end

    return displayPage
end

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,

        palettes = state.colorEditor.palettes,
        lastPaletteModification = state.colorEditor.lastPaletteModification,
        lastPalettePage = state.sessionData.lastPalettePage,
    }
end, function(dispatch)
    return {
        updatePalettePage = function(palettePage)
            dispatch({
                type = PluginEnums.StoreActionType.UpdateSessionData,
                slice = {
                    lastPalettePage = palettePage
                }
            })
        end,

        addPalette = function()
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_AddPalette,
            })
        end,

        removePalette = function(paletteName)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_RemovePalette,
                name = paletteName,
            })
        end,

        duplicatePalette = function(paletteName)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_DuplicatePalette,
                name = paletteName
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
end)(PalettePages)