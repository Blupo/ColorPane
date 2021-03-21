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

local DELETE_PROMPT_TEXT = "Are you sure you want to permanently delete %s?"

local shallowCompare = util.shallowCompare

---

local PalettePages = Roact.PureComponent:extend("PalettePages")

PalettePages.init = function(self)
    self.promptWidth, self.updatePromptWidth = Roact.createBinding(0)

    self:setState({
        showRemovePalettePrompt = false,
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

PalettePages.render = function(self)
    local palettes = self.props.palettes
    local theme = self.props.theme

    local currentPage = self.props.lastPalettePage
    local currentPageSection, currentPageNum = currentPage[1], currentPage[2]
    local numBuiltInPalettes = #BuiltInPalettes
    
    local displayPage
    local builtInPalettePages = {}
    local userPalettePages = {}

    for i = 1, numBuiltInPalettes do
        local palette = BuiltInPalettes[i]

        builtInPalettePages[#builtInPalettePages + 1] = {
            name = palette.name,
            content = palette.getContent()
        }
    end

    for i = 1, #palettes do
        local palette = palettes[i]

        userPalettePages[#userPalettePages + 1] = {
            name = palette.name,

            content = Roact.createElement(Palette, {
                palette = palette
            })
        }
    end

    if (not (self.state.showRemovePalettePrompt or self.state.showRenamePalettePrompt)) then
        displayPage = Roact.createElement(Pages, {
            initPage = currentPage,
            showAllSections = true,
            onPageChanged = self.props.updatePalettePage,

            pageSections = {
                {
                    name = "Built-In Palettes",
                    pages = builtInPalettePages,
                },

                {
                    name = "User Palettes",
                    pages = userPalettePages,
                }
            },

            options = {
                {
                    name = "Create a New Palette",
                    onActivated = function()
                        self:setState({
                            showRemovePalettePrompt = false,
                            removePaletteName = Roact.None,
                        })

                        self.props.addPalette()
                        self.props.updatePalettePage(2, #palettes + 1)
                    end
                },

                (currentPageSection == 2) and {
                    name = "Rename this Palette",
                    onActivated = function()
                        self:setState({
                            showRenamePalettePrompt = true,
                            renamePaletteName = palettes[currentPageNum].name,
                            newPaletteName = palettes[currentPageNum].name,
                        })
                    end
                } or nil,

                (currentPageSection == 2) and {
                    name = "Delete this Palette",
                    onActivated = function()
                        self:setState({
                            showRemovePalettePrompt = true,
                            removePaletteName = palettes[currentPageNum].name
                        })
                    end
                } or nil,

                (currentPageSection == 2) and {
                    name = "Duplicate this Palette",
                    onActivated = function()
                        local duplicatePaletteName = palettes[currentPageNum].name

                        self.props.duplicatePalette(duplicatePaletteName)
                        self.props.updatePalettePage(2, #palettes + 1)
                    end
                } or nil,
            }
        })
    elseif (self.state.showRemovePalettePrompt) then
        local promptText = string.format(DELETE_PROMPT_TEXT, self.state.removePaletteName)

        displayPage = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            [Roact.Change.AbsoluteSize] = function(obj)
                self.updatePromptWidth(obj.AbsoluteSize.X)
            end
        }, {
            UIPadding = Roact.createElement(Padding, {0, Style.MajorElementPadding}),

            WarningText = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 0.5, -4),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Size = self.promptWidth:map(function(promptWidth)
                    local promptTextHeight = TextService:GetTextSize(
                        promptText,
                        Style.LargeTextSize,
                        Style.StandardFont,
                        Vector2.new(promptWidth - (Style.MajorElementPadding * 2), math.huge)
                    ).Y

                    return UDim2.new(1, 0, 0, promptTextHeight)
                end),

                Font = Style.StandardFont,
                TextSize = Style.LargeTextSize,
                Text = promptText,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Bottom,

                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
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
                            showRemovePalettePrompt = false,
                            removePaletteName = Roact.None,
                        })

                        self.props.updatePalettePage(1, 1)
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

            [Roact.Change.AbsoluteSize] = function(obj)
                self.updatePromptWidth(obj.AbsoluteSize.X)
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
        updatePalettePage = function(section, page)
            dispatch({
                type = PluginEnums.StoreActionType.UpdateSessionData,
                slice = {
                    lastPalettePage = {section, page}
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