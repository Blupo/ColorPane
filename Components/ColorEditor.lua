local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Color = require(PluginModules:FindFirstChild("Color"))
local ColorEditorInput = require(PluginModules:FindFirstChild("ColorEditorInput"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local Style = require(PluginModules:FindFirstChild("Style"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local ButtonBar = require(Components:FindFirstChild("ButtonBar"))
local ColorInfo = require(Components:FindFirstChild("ColorInfo"))
local ColorWheel = require(Components:FindFirstChild("ColorWheel"))
local PalettePages = require(Components:FindFirstChild("PalettePages"))
local SliderPages = require(Components:FindFirstChild("SliderPages"))
local TextInput = require(Components:FindFirstChild("TextInput"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardTextLabel = StandardComponents.TextLabel
local StandardUICorner = StandardComponents.UICorner
local StandardUIListLayout = StandardComponents.UIListLayout
local StandardUIPadding = StandardComponents.UIPadding

---

local EDITOR_ICON_DISPLAY_COLOR = Color3.new(1, 1, 1)
local EDITOR_ICON_SELECTED_COLOR = Color3.new(1, 1, 1)
local EDITOR_ICON_DISABLED_COLOR = Color3.new(1/2, 1/2, 1/2)

local indicatorContainerSize = Style.StandardButtonSize * 2 + Style.MinorElementPadding
local shallowCompare = Util.shallowCompare
local editorInputBindableEvents = ColorEditorInput.GetInputBindableEvents()

local getMaxPages = function(width)
    local maxPagesNoPadding = math.floor(width / Style.EditorPageWidth)
    local maxPaddingSpaces = math.floor((width % Style.EditorPageWidth) / Style.MajorElementPadding)

    return (maxPaddingSpaces >= (maxPagesNoPadding - 1)) and maxPagesNoPadding or (maxPagesNoPadding - 1)
end

local editorTabs = {
    {
        name = "ColorWheel",
        image = Style.ColorWheelEditorImage,

        displayColor = EDITOR_ICON_DISPLAY_COLOR,
        selectedDisplayColor = EDITOR_ICON_SELECTED_COLOR,
        disabledDisplayColor = EDITOR_ICON_DISABLED_COLOR,

        getElement = function()
            return Roact.createElement(ColorWheel, {
                ringWidth = Style.ColorWheelRingWidth,
            })
        end
    },

    {
        name = "Sliders",
        image = Style.SliderEditorImage,

        displayColor = EDITOR_ICON_DISPLAY_COLOR,
        selectedDisplayColor = EDITOR_ICON_SELECTED_COLOR,
        disabledDisplayColor = EDITOR_ICON_DISABLED_COLOR,

        getElement = function()
            return Roact.createElement(SliderPages)
        end
    },

    {
        name = "Palettes",
        image = Style.PaletteEditorImage,

        displayColor = EDITOR_ICON_DISPLAY_COLOR,
        selectedDisplayColor = EDITOR_ICON_SELECTED_COLOR,
        disabledDisplayColor = EDITOR_ICON_DISABLED_COLOR,

        getElement = function()
            return Roact.createElement(PalettePages)
        end
    },

    {
        name = "ColorInfo",
        image = Style.ColorInfoEditorImage,

        getElement = function()
            return Roact.createElement(ColorInfo)
        end
    }
}

---

local ColorEditor = Roact.Component:extend("ColorEditor")

ColorEditor.init = function(self)
    self:setState({
        editorWidth = 0,
    })
end

ColorEditor.shouldUpdate = function(self, nextProps, nextState)
    local propsDiff = shallowCompare(self.props, nextProps)
    local stateDiff = shallowCompare(self.state, nextState)

    if (#stateDiff == 1) then
        if (stateDiff[1] == "editorWidth") then
            local oldMaxPages = math.clamp(getMaxPages(self.state.editorWidth), 1, #editorTabs)
            local newMaxPages = math.clamp(getMaxPages(nextState.editorWidth), 1, #editorTabs)

            return (oldMaxPages ~= newMaxPages)
        else
            return true
        end
    elseif (#stateDiff > 1) then
        return true
    end

    if (#propsDiff == 1) then
        if (propsDiff[1] == "quickPalette") then
            return (#shallowCompare(self.props.quickPalette, nextProps.quickPalette) > 0)
        else
            return true
        end
    elseif (#propsDiff > 1) then
        return true
    end

    return false
end

ColorEditor.render = function(self)
    local theme = self.props.theme
    local selectedEditor = self.props.editorPage

    local editorPageElements = {}
    local quickPaletteElements = {}
    local editorTabButtons = {}

    local maxPages = math.clamp(getMaxPages(self.state.editorWidth), 1, #editorTabs)
    local numDisabledButtons

    if (maxPages == #editorTabs) then
        numDisabledButtons = #editorTabs
    else
        numDisabledButtons = maxPages - 1
    end

    if (selectedEditor <= numDisabledButtons) then
        selectedEditor = numDisabledButtons + 1
    end

    for i = 1, maxPages do
        local page

        if (maxPages ~= #editorTabs) then
            page = (i ~= maxPages) and i or selectedEditor
        else
            page = i
        end

        local editorTab = editorTabs[page]

        editorPageElements[editorTab.name] = Roact.createElement("Frame", {
            Size = UDim2.new(1 / maxPages, -Style.MajorElementPadding * (maxPages - 1) / maxPages, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = i
        }, {
            Page = editorTab.getElement(),
        })
    end

    for i = 1, #editorTabs do
        local tab = editorTabs[i]

        table.insert(editorTabButtons, {
            name = tab.name,
            image = tab.image,
            disabled = (i <= numDisabledButtons),

            displayColor = tab.displayColor,
            selectedDisplayColor = tab.selectedDisplayColor,
            disabledDisplayColor = tab.disabledDisplayColor,
        })
    end

    for i = 1, #self.props.quickPalette do
        local color = self.props.quickPalette[i]

        quickPaletteElements[i] = Roact.createElement(Button, {
            LayoutOrder = i,

            displayType = "color",
            color = color,

            onActivated = function()
                self.props.setColor(color)
            end
        })
    end

    editorPageElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        Padding = UDim.new(0, Style.MajorElementPadding),
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

    quickPaletteElements.UIGridLayout = Roact.createElement("UIGridLayout", {
        CellPadding = UDim2.new(0, Style.MinorElementPadding, 0, Style.MinorElementPadding),
        CellSize = UDim2.new(0, Style.StandardButtonSize, 0, Style.StandardButtonSize),
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        StartCorner = Enum.StartCorner.TopLeft,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    quickPaletteElements.AddColorButton = Roact.createElement(Button, {
        LayoutOrder = 0,
        
        displayType = "image",
        image = Style.AddImage,

        onActivated = function()
            self.props.addQuickPaletteColor(self.props.color)
        end
    })

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame),

        [Roact.Event.InputBegan] = function(_, input, gameProcessedEvent)
            editorInputBindableEvents.InputBegan:Fire(input, gameProcessedEvent)
        end,

        [Roact.Event.InputChanged] = function(_, input, gameProcessedEvent)
            editorInputBindableEvents.InputChanged:Fire(input, gameProcessedEvent)
        end,

        [Roact.Event.InputEnded] = function(_, input, gameProcessedEvent)
            editorInputBindableEvents.InputEnded:Fire(input, gameProcessedEvent)
        end,
    }, {
        UIPadding = Roact.createElement(StandardUIPadding, {Style.PagePadding}),

        EditorPages = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, -(Style.LargeButtonSize + 2 + Style.MajorElementPadding), 1, -118),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            [Roact.Change.AbsoluteSize] = function(obj)
                local absoluteSize = obj.AbsoluteSize
    
                self:setState({
                    editorWidth = absoluteSize.X
                })
            end
        }, editorPageElements),

        EditorPagePicker = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(0, Style.LargeButtonSize + 2, 0, ((Style.LargeButtonSize + Style.MinorElementPadding) * #editorTabs) + 2),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }, {
            Pickers = Roact.createElement(ButtonBar, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 1, 0),

                displayType = "image",
                vertical = true,
                selected = selectedEditor,
                buttons = editorTabButtons,

                onButtonActivated = self.props.setEditorPage
            })
        }),

        Tools = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -38),
            Size = UDim2.new(1, 0, 0, indicatorContainerSize),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Separator = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, -Style.MajorElementPadding),
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Separator),
            }),

            IndicatorContainer = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(0, indicatorContainerSize, 0, indicatorContainerSize),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
            }, {
                UICorner = Roact.createElement(StandardUICorner),

                ColorIndicator = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Position = UDim2.new(0.5, 0, 0, 1),
                    Size = UDim2.new(1, -2, 0.5, -1),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,

                    BackgroundColor3 = self.props.color,
                }),

                OriginalColorIndicator = Roact.createElement("TextButton", {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Position = UDim2.new(0.5, 0, 1, -1),
                    Size = UDim2.new(1, -2, 0.5, 1),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
    
                    Text = "",
                    TextTransparency = 1,
    
                    BackgroundColor3 = self.props.originalColor,
    
                    [Roact.Event.Activated] = function()
                        self.props.setColor(self.props.originalColor)
                    end
                })
            }),

            QuickPalette = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(1, -indicatorContainerSize - Style.MinorElementPadding, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
            }, quickPaletteElements)
        }),

        Hex = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(0, Style.DialogButtonWidth, 0, Style.StandardButtonSize),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Label = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(0, 6, 1, 0),
    
                Text = "#",
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
            }),

            Input = Roact.createElement(TextInput, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(1, -6 - Style.MinorElementPadding, 0, Style.StandardInputHeight),
                
                Text = string.upper(Color.toHex(Color.fromColor3(self.props.color))),
                TextXAlignment = Enum.TextXAlignment.Center,

                isTextAValidValue = function(text)
                    return Color.fromHex(text) and true or false
                end,

                onSubmit = function(text)
                    self.props.setColor(Color.toColor3(Color.fromHex(text)))
                end,
                
                selectTextOnFocus = true,
            }),
        }),

        Actions = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, 0, 1, 0),
            Size = UDim2.new(0, Style.DialogButtonWidth * 2 + Style.SpaciousElementPadding, 0, Style.StandardButtonSize),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            UIListLayout = Roact.createElement(StandardUIListLayout, {
                Padding = UDim.new(0, Style.SpaciousElementPadding),
                
                preset = 2,
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
                    self.props.finishedEvent:Fire(false)
                end
            }),

            ConfirmButton = Roact.createElement(Button, {
                Size = UDim2.new(0, Style.DialogButtonWidth, 0, Style.StandardButtonSize),
                LayoutOrder = 1,

                displayType = "text",
                text = "OK",

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton, Enum.StudioStyleGuideModifier.Hover),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText),

                onActivated = function()
                    self.props.finishedEvent:Fire(true)
                end
            }),
        })
    })
end

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,

        editorPage = state.sessionData.editorPage,
        color = state.colorEditor.color,
        quickPalette = state.colorEditor.quickPalette,
    }
end, function(dispatch)
    return {
        setColor = function(color)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_SetColor,
                color = color
            })
        end,

        addQuickPaletteColor = function(color)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_AddQuickPaletteColor,
                color = color,
            })
        end,

        setEditorPage = function(page)
            dispatch({
                type = PluginEnums.StoreActionType.UpdateSessionData,
                slice = {
                    editorPage = page
                }
            })
        end,
    }
end)(ColorEditor)