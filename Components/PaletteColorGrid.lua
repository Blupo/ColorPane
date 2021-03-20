local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local ColorGrids = require(Components:FindFirstChild("ColorGrids"))
local TextInput = require(Components:FindFirstChild("TextInput"))

---

local PaletteColorGrid = Roact.PureComponent:extend("PaletteColorGrid")

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

        onColorSelected: (number) -> nil

        onColorSet: () -> nil
        onColorRemoved: () -> nil
        onColorNameChanged: (string) -> nil
        onColorMovedUp: () -> nil
        onColorMovedDown: () -> nil
]]

PaletteColorGrid.render = function(self)
    local isReadOnly = self.props.readOnly
    local colors = self.props.colors
    local selected = self.props.selected

    local colorGridList = {}

    for i = 1, #colors do
        colorGridList[i] = colors[i].color
    end

    return Roact.createElement("Frame", {
        AnchorPoint = self.props.AnchorPoint,
        Position = self.props.Position,
        Size = self.props.Size,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        Grid = Roact.createElement(ColorGrids, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, -(Style.StandardButtonSize * 2) - (Style.MinorElementPadding * 1) - Style.MajorElementPadding),
    
            named = false,
            colorLists = {colorGridList},
            selected = self.props.selected,
    
            onColorSelected = function(i)
                if (selected == i) then
                    self.props.onColorSet(i)
                end

                self.props.onColorSelected(i)
            end,
        }),

        ColorInfo = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, (Style.StandardButtonSize * 2) + Style.MinorElementPadding),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            NameInput = Roact.createElement(TextInput, {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, Style.StandardButtonSize),
                
                Text = selected and colors[selected].name or "",
                PlaceholderText = "Select a color",

                canClear = false,
                disabled = ((not selected) or isReadOnly),

                onTextChanged = self.props.onColorNameChanged,
            }),

            SetColorButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, Style.DialogButtonWidth, 0, Style.StandardButtonSize),
                
                displayType = "image",
                image = Style.PaletteSetColorImage,
                disabled = (not selected),

                onActivated = function()
                    self.props.onColorSet(selected)
                end,
            }),

            ColorActions = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
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

                RemoveColorButton = Roact.createElement(Button, {
                    LayoutOrder = 0,
    
                    displayType = "image",
                    image = Style.PaletteRemoveColorImage,
                    disabled = ((not selected) or isReadOnly),

                    onActivated = self.props.onColorRemoved,
                }),
    
                MoveUpButton = Roact.createElement(Button, {
                    LayoutOrder = 1,
    
                    displayType = "image",
                    image = Style.PaletteColorMoveLeftImage,
                    disabled = ((not selected) or isReadOnly or (selected == 1)),

                    onActivated = self.props.onColorMovedUp,
                }),
    
                MoveDownButton = Roact.createElement(Button, {
                    LayoutOrder = 2,
    
                    displayType = "image",
                    image = Style.PaletteColorMoveRightImage,
                    disabled = ((not selected) or isReadOnly or (selected == #colors)),

                    onActivated = self.props.onColorMovedDown,
                }),
            }),
        })
    })
end

return PaletteColorGrid