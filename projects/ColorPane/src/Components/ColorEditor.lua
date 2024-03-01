-- The entire color editor interface 

local root = script.Parent.Parent
local Common = root.Common

local CommonPluginModules = Common.PluginModules
local Style = require(CommonPluginModules.Style)
local Translator = require(CommonPluginModules.Translator)

local CommonIncludes = Common.Includes
local Color = require(CommonIncludes.Color).Color
local Roact = require(CommonIncludes.RoactRodux.Roact)
local RoactRodux = require(CommonIncludes.RoactRodux.RoactRodux)

local CommonComponents = Common.Components
local Button = require(CommonComponents.Button)
local TextInput = require(CommonComponents.TextInput)

local StandardComponents = CommonComponents.StandardComponents
local StandardTextLabel = require(StandardComponents.TextLabel)
local StandardUICorner = require(StandardComponents.UICorner)
local StandardUIListLayout = require(StandardComponents.UIListLayout)
local StandardUIPadding = require(StandardComponents.UIPadding)

local PluginModules = root.PluginModules
local ColorEditorInputSignals = require(PluginModules.EditorInputSignals).ColorEditor
local PluginEnums = require(PluginModules.PluginEnums)
local Util = require(PluginModules.Util)

local Components = root.Components
local ButtonBar = require(Components.ButtonBar)
local ColorToolPages = require(Components.ColorToolPages)
local ColorWheel = require(Components.ColorWheel)
local PalettePages = require(Components.PalettePages)
local SliderPages = require(Components.SliderPages)

---

local EDITOR_ICON_DISPLAY_COLOR = Color3.new(1, 1, 1)
local EDITOR_ICON_SELECTED_COLOR = Color3.new(1, 1, 1)
local EDITOR_ICON_DISABLED_COLOR = Color3.new(1/2, 1/2, 1/2)

local uiTranslations = Translator.GenerateTranslationTable({
    "Cancel_ButtonText",
    "OK_ButtonText"
})

local indicatorContainerSize = (Style.Constants.StandardButtonHeight * 2) + Style.Constants.MinorElementPadding

local getMaxPages = function(width)
    local maxPagesNoPadding = math.floor(width / Style.Constants.EditorPageWidth)
    local maxPaddingSpaces = math.floor((width % Style.Constants.EditorPageWidth) / Style.Constants.MajorElementPadding)

    return (maxPaddingSpaces >= (maxPagesNoPadding - 1)) and maxPagesNoPadding or (maxPagesNoPadding - 1)
end

local editorTabs = {
    {
        name = "ColorWheel",
        image = Style.Images.ColorWheelEditorButtonIcon,

        displayColor = EDITOR_ICON_DISPLAY_COLOR,
        selectedDisplayColor = EDITOR_ICON_SELECTED_COLOR,
        disabledDisplayColor = EDITOR_ICON_DISABLED_COLOR,

        getElement = function()
            return Roact.createElement(ColorWheel, {
                ringWidth = Style.Constants.ColorWheelRingWidth,
            })
        end
    },

    {
        name = "Sliders",
        image = Style.Images.SlidersEditorButtonIcon,

        displayColor = EDITOR_ICON_DISPLAY_COLOR,
        selectedDisplayColor = EDITOR_ICON_SELECTED_COLOR,
        disabledDisplayColor = EDITOR_ICON_DISABLED_COLOR,

        getElement = function()
            return Roact.createElement(SliderPages)
        end
    },

    {
        name = "Palettes",
        image = Style.Images.PaletteEditorButtonIcon,

        displayColor = EDITOR_ICON_DISPLAY_COLOR,
        selectedDisplayColor = EDITOR_ICON_SELECTED_COLOR,
        disabledDisplayColor = EDITOR_ICON_DISABLED_COLOR,

        getElement = function()
            return Roact.createElement(PalettePages)
        end
    },

    {
        name = "ColorTools",
        image = Style.Images.ColorToolsEditorButtonIcon,

        getElement = function()
            return Roact.createElement(ColorToolPages)
        end
    }
}

---

--[[
    props
        originalColor: Color
        fireFinished: FireSignal<boolean>

    store props
        theme: StudioTheme
        editorPage: number
        color: Color
        quickPalette: array<Color>

        setColor: (Color) -> nil
        addQuickPaletteColor: (Color) -> nil
        setEditorPage: (number) -> nil
]]

local ColorEditor = Roact.Component:extend("ColorEditor")

ColorEditor.init = function(self)
    self:setState({
        editorWidth = 0,
    })
end

ColorEditor.shouldUpdate = function(self, nextProps, nextState)
    local propsDiff = Util.table.shallowCompare(self.props, nextProps)
    local stateDiff = Util.table.shallowCompare(self.state, nextState)
    if (#propsDiff >= 1) then return true end

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

    return false
end

ColorEditor.render = function(self)
    local theme = self.props.theme
    local color = self.props.color
    local originalColor = self.props.originalColor
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
            Size = UDim2.new(1 / maxPages, -Style.Constants.MajorElementPadding * (maxPages - 1) / maxPages, 1, 0),
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
        local quickPaletteColor = self.props.quickPalette[i]

        quickPaletteElements[i] = Roact.createElement(Button, {
            LayoutOrder = i,

            displayType = "color",
            color = quickPaletteColor:toColor3(),

            onActivated = function()
                self.props.setColor(quickPaletteColor)
            end
        })
    end

    editorPageElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        Padding = UDim.new(0, Style.Constants.MajorElementPadding),
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

    quickPaletteElements.UIGridLayout = Roact.createElement("UIGridLayout", {
        CellPadding = Style.UDim2.MinorElementPaddingSize,
        CellSize = Style.UDim2.StandardButtonSize,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        StartCorner = Enum.StartCorner.TopLeft,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    quickPaletteElements.AddColorButton = Roact.createElement(Button, {
        LayoutOrder = 0,
        
        displayType = "image",
        image = Style.Images.AddButtonIcon,

        onActivated = function()
            self.props.addQuickPaletteColor(color)
        end
    })

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame),

        [Roact.Event.InputBegan] = function(_, input: InputObject)
            ColorEditorInputSignals.InputBegan.Fire(input)
        end,

        [Roact.Event.InputEnded] = function(_, input: InputObject)
            ColorEditorInputSignals.InputEnded.Fire(input)
        end,
    }, {
        UIPadding = Roact.createElement(StandardUIPadding, {
            paddings = {Style.Constants.PagePadding}
        }),

        EditorPages = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, -(Style.Constants.LargeButtonHeight + 2 + Style.Constants.MajorElementPadding), 1, -118),
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
            Size = UDim2.new(0, Style.Constants.LargeButtonHeight + 2, 0, ((Style.Constants.LargeButtonHeight + Style.Constants.MinorElementPadding) * #editorTabs) + 2),
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
                Position = UDim2.new(0.5, 0, 0, -Style.Constants.MajorElementPadding),
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

                    BackgroundColor3 = color:toColor3(),
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
    
                    BackgroundColor3 = originalColor:toColor3(),
    
                    [Roact.Event.Activated] = function()
                        self.props.setColor(originalColor)
                    end
                })
            }),

            QuickPalette = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(1, -indicatorContainerSize - Style.Constants.MinorElementPadding, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
            }, quickPaletteElements)
        }),

        Hex = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(0, Style.Constants.DialogButtonWidth, 0, Style.Constants.StandardButtonHeight),
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
                Size = UDim2.new(1, -6 - Style.Constants.MinorElementPadding, 0, Style.Constants.StandardInputHeight),
                
                Text = string.upper(color:toHex()),
                TextXAlignment = Enum.TextXAlignment.Center,

                isTextAValidValue = function(text)
                    return (pcall(Color.fromHex, text)) and true or false
                end,

                onSubmit = function(text)
                    self.props.setColor(Color.fromHex(text))
                end,
                
                selectTextOnFocus = true,
            }),
        }),

        RandomColorButton = Roact.createElement(Button, {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, Style.Constants.DialogButtonWidth + Style.Constants.MinorElementPadding, 1, 0),
            Size = UDim2.new(0, Style.Constants.StandardButtonHeight, 0, Style.Constants.StandardButtonHeight),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            displayType = "image",
            image = Style.Images.RandomColorButtonIcon,

            onActivated = function()
                self.props.setColor(Color.random())
            end,
        }),

        Actions = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, 0, 1, 0),
            Size = UDim2.new(0, Style.Constants.DialogButtonWidth * 2 + Style.Constants.SpaciousElementPadding, 0, Style.Constants.StandardButtonHeight),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            UIListLayout = Roact.createElement(StandardUIListLayout, {
                Padding = UDim.new(0, Style.Constants.SpaciousElementPadding),
                
                preset = 2,
            }),

            CancelButton = Roact.createElement(Button, {
                Size = UDim2.new(0, Style.Constants.DialogButtonWidth, 0, Style.Constants.StandardButtonHeight),
                LayoutOrder = 0,

                displayType = "text",
                text = uiTranslations["Cancel_ButtonText"],

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton, Enum.StudioStyleGuideModifier.Hover),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonText),

                onActivated = function()
                    self.props.fireFinished(false)
                end
            }),

            ConfirmButton = Roact.createElement(Button, {
                Size = UDim2.new(0, Style.Constants.DialogButtonWidth, 0, Style.Constants.StandardButtonHeight),
                LayoutOrder = 1,

                displayType = "text",
                text = uiTranslations["OK_ButtonText"],

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton, Enum.StudioStyleGuideModifier.Hover),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText),

                onActivated = function()
                    self.props.fireFinished(true)
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