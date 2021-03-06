local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local ConnectTheme = require(Components:FindFirstChild("ConnectTheme"))
local Padding = require(Components:FindFirstChild("Padding"))

---

--[[
    props

        AnchorPoint?
        Position?

        colors: array<Color3>
        title: string?
        selected: number?

        onColorSelected: (number) -> nil
]]

local ColorGrid = Roact.PureComponent:extend("ColorGrid")

ColorGrid.init = function(self)
    self.gridLength, self.updateGridLength = Roact.createBinding(0)
end

ColorGrid.render = function(self)
    local theme = self.props.theme
    local colors = self.props.colors

    local colorElements = {}

    for i = 1, #colors do
        local color = colors[i]

        colorElements[i] = Roact.createElement(Button, {
            LayoutOrder = i,

            displayType = "color",
            color = color,

            borderColor = (self.props.selected == i) and
                theme:GetColor(
                    Enum.StudioStyleGuideColor.InputFieldBorder,
                    Enum.StudioStyleGuideModifier.Selected
                )
            or nil,

            onActivated = function()
                self.props.onColorSelected(i)
            end
        })
    end

    colorElements["UIGridLayout"] = Roact.createElement("UIGridLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        StartCorner = Enum.StartCorner.TopLeft,

        CellSize = UDim2.new(0, Style.StandardButtonSize, 0, Style.StandardButtonSize),
        CellPadding = UDim2.new(0, Style.MinorElementPadding, 0, Style.MinorElementPadding),

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateGridLength(obj.AbsoluteContentSize.Y)
        end
    })

    return Roact.createElement("Frame", {
        AnchorPoint = self.props.AnchorPoint,
        Position = self.props.Position,

        Size = self.gridLength:map(function(gridLength)
            return UDim2.new(1, 0, 0, gridLength + (self.props.title and (Style.StandardTextSize + Style.MinorElementPadding) or 0))
        end),

        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        GridLabel = self.props.title and
            Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, Style.StandardTextSize),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Font = Enum.Font.SourceSans,
                TextSize = Style.StandardTextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                Text = self.props.title,
                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
            })
        or nil,

        Grid = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, 0, 1, self.props.title and -(Style.StandardTextSize + Style.MinorElementPadding) or 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, colorElements)
    })
end

---

--[[
    props

        AnchorPoint?
        Position?
        Size?

        colorLists: dictionary<string | number, array<Color3>>
        named: boolean?
        selected: number? (only works properly if there is only one color list)

        onColorSelected = (number, string | number) -> nil
]]

local ColorGrids = Roact.PureComponent:extend("ColorGrids")

ColorGrids.init = function(self)
    self.listLength, self.updateListLength = Roact.createBinding(0)
end

ColorGrids.render = function(self)
    local theme = self.props.theme

    local listElements = {}

    for gridName, gridColors in pairs(self.props.colorLists) do
        listElements[gridName] = Roact.createElement(ColorGrid, {
            colors = gridColors,
            title = (self.props.named) and gridName or nil,
            selected = self.props.selected,

            onColorSelected = function(i)
                self.props.onColorSelected(i, gridName)
            end,
        })
    end

    listElements["UIListLayout"] = Roact.createElement("UIListLayout", {
        Padding = UDim.new(0, Style.MinorElementPadding),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.Name,
        VerticalAlignment = Enum.VerticalAlignment.Top,

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateListLength(obj.AbsoluteContentSize.Y)
        end
    })

    listElements["UIPadding"] = Roact.createElement(Padding, {Style.MinorElementPadding})

    return Roact.createElement("ScrollingFrame", {
        AnchorPoint = self.props.AnchorPoint,
        Position = self.props.Position,
        Size = self.props.Size,
        BackgroundTransparency = 0,
        BorderSizePixel = 1,

        CanvasSize = self.listLength:map(function(listLength)
            return UDim2.new(0, 0, 0, listLength + (Style.MinorElementPadding * 2))
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

ColorGrid = ConnectTheme(ColorGrid)
return ConnectTheme(ColorGrids)