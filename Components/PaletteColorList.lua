local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local ConnectTheme = require(Components:FindFirstChild("ConnectTheme"))
local Padding = require(Components:FindFirstChild("Padding"))
local TextInput = require(Components:FindFirstChild("TextInput"))

---

--[[
    props

        AnchorPoint?
        Position?
        Size?

        colors: array<{
            name: string?,
            color: Color3
        }>

        readOnly: boolean?
        selected: number?

        onColorSelected = (number) -> nil

        onColorSet: (number) -> nil
        onColorRemoved: () -> nil
        onColorNameChanged: (string) -> nil
        onColorMovedUp: () -> nil
        onColorMovedDown: () -> nil
]]

local PaletteColorList = Roact.PureComponent:extend("PaletteColorList")

PaletteColorList.init = function(self)
    self.listLength, self.updateListLength = Roact.createBinding(0)
end

PaletteColorList.render = function(self)
    local theme = self.props.theme
    local colors = self.props.colors

    local isReadOnly = self.props.readOnly
    local selected = self.props.selected

    local listElements = {}

    for i = 1, #colors do
        local color = colors[i]
        local isSelected = (selected == i)

        local listItemHeight

        if (isSelected) then
            listItemHeight = (Style.StandardButtonSize * (isReadOnly and 1 or 2)) + (Style.MinorElementPadding * (isReadOnly and 2 or 3))
        else
            listItemHeight = (Style.StandardButtonSize * 1) + (Style.MinorElementPadding * 2)
        end

        table.insert(listElements, Roact.createElement("TextButton", {
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, listItemHeight),

            Text = "",
            TextTransparency = 1,

            BackgroundColor3 = isSelected and
                theme:GetColor(Enum.StudioStyleGuideColor.TableItem, Enum.StudioStyleGuideModifier.Selected)
            or theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame),

            [Roact.Event.MouseEnter] = function(obj)
                if (isSelected) then return end

                obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.TableItem, Enum.StudioStyleGuideModifier.Hover)
            end,

            [Roact.Event.MouseLeave] = function(obj)
                if (isSelected) then return end

                obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)
            end,

            [Roact.Event.Activated] = function()
                if (isSelected) then return end

                self.props.onColorSelected(i)
            end
        }, {
            UIPadding = Roact.createElement(Padding, {Style.MinorElementPadding}),

            ColorIndicator = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, 0),

                displayType = "color",
                color = color.color,

                onActivated = function()
                    self.props.onColorSet(i)
                    self.props.onColorSelected(i)
                end,
            }),

            ColorName = isSelected and
                Roact.createElement(TextInput, {
                    AnchorPoint = Vector2.new(0, 0),
                    Position = UDim2.new(0, Style.StandardButtonSize + Style.MinorElementPadding, 0, 0),
                    Size = UDim2.new(1, -(Style.StandardButtonSize + Style.MinorElementPadding), 0, Style.StandardButtonSize),

                    Text = color.name,
                    TextXAlignment = Enum.TextXAlignment.Left,

                    disabled = isReadOnly,
                    canClear = false,
                    onTextChanged = self.props.onColorNameChanged,
                })
            or
                Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(0, 0),
                    Position = UDim2.new(0, Style.StandardButtonSize + Style.SpaciousElementPadding + 1, 0, 0),
                    Size = UDim2.new(1, -(Style.StandardButtonSize + Style.SpaciousElementPadding + 1), 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Font = Style.StandardFont,
                    TextSize = Style.StandardTextSize,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    Text = color.name,

                    TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText, isSelected and Enum.StudioStyleGuideModifier.Selected or nil),
                }),

            ColorActions = (isSelected and (not isReadOnly)) and
                Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, Style.StandardButtonSize + Style.MinorElementPadding, 1, 0),
                    Size = UDim2.new(0, (Style.StandardButtonSize * 3) + (Style.MinorElementPadding * 2), 0, Style.StandardButtonSize),

                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, {
                    UIListLayout = Roact.createElement("UIListLayout", {
                        Padding = UDim.new(0, Style.MinorElementPadding),
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Right,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    }),

                    RemoveColorButton = (isSelected and (not isReadOnly)) and
                        Roact.createElement(Button, {
                            LayoutOrder = 1,
            
                            displayType = "image",
                            image = Style.RemoveImage,

                            onActivated = self.props.onColorRemoved,
                        })
                    or nil,
        
                    MoveUpButton = (isSelected and (not isReadOnly)) and
                        Roact.createElement(Button, {
                            LayoutOrder = 2,
            
                            displayType = "image",
                            image = Style.PaletteColorMoveUpImage,
                            disabled = (selected == 1),
                                    
                            onActivated = self.props.onColorMovedUp,
                        })
                    or nil,
        
                    MoveDownButton = (isSelected and (not isReadOnly)) and
                        Roact.createElement(Button, {
                            LayoutOrder = 3,
            
                            displayType = "image",
                            image = Style.PaletteColorMoveDownImage,
                            disabled = (selected == #colors),

                            onActivated = self.props.onColorMovedDown,
                        })
                    or nil,
                })
            or nil,
        }))
    end

    listElements["UIListLayout"] = Roact.createElement("UIListLayout", {
        Padding = UDim.new(0, 0),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateListLength(obj.AbsoluteContentSize.Y)
        end
    })

    return Roact.createElement("ScrollingFrame", {
        AnchorPoint = self.props.AnchorPoint,
        Position = self.props.Position,
        Size = self.props.Size,
        BackgroundTransparency = 0,
        BorderSizePixel = 1,

        CanvasSize = self.listLength:map(function(listLength)
            return UDim2.new(0, 0, 0, listLength)
        end),

        CanvasPosition = Vector2.new(0, 0),
        TopImage = Style.ScrollbarImage,
        MidImage = Style.ScrollbarImage,
        BottomImage = Style.ScrollbarImage,
        HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
        VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
        VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right,
        ScrollBarThickness = Style.ScrollbarThickness,
        ClipsDescendants = true,

        ScrollBarImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ScrollBar),
        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame),
        BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
    }, listElements)
end

return ConnectTheme(PaletteColorList)