local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local ColorEditorInputSignals = require(PluginModules:FindFirstChild("EditorInputSignals")).ColorEditor
local RepeatingCallback = require(PluginModules:FindFirstChild("RepeatingCallback"))
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local ConnectTheme = require(Components:FindFirstChild("ConnectTheme"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardScrollingFrame = StandardComponents.ScrollingFrame
local StandardTextLabel = StandardComponents.TextLabel
local StandardUIListLayout = StandardComponents.UIListLayout
local StandardUIPadding = StandardComponents.UIPadding

---

local KEY_CODE_DELTAS = {
    [Enum.KeyCode.Up] = function(cellsPerRow) return -cellsPerRow end,
    [Enum.KeyCode.Down] = function(cellsPerRow) return cellsPerRow end,
    [Enum.KeyCode.Left] = function() return -1 end,
    [Enum.KeyCode.Right] = function() return 1 end,
}

--[[
    props

        AnchorPoint?
        Position?

        colors: array<Color3>
        title: string?
        selected: number?

        onColorSelected: (number) -> nil

    store props
    
        theme: StudioTheme
]]

local ColorGrid = Roact.PureComponent:extend("ColorGrid")

ColorGrid.init = function(self)
    self.gridLength, self.updateGridLength = Roact.createBinding(0)
    self.cellsPerRow, self.updateCellsPerRow = Roact.createBinding(0)
    self.keyInputRepeaters = {}

    for keyCode, deltaCallback in pairs(KEY_CODE_DELTAS) do
        local repeater = RepeatingCallback.new(function()
            local colors = self.props.colors
            local selected = self.props.selected
            if (not selected) then return end

            local nextSelected = selected + deltaCallback(self.cellsPerRow:getValue())
            if (not colors[nextSelected]) then return end

            self.props.onColorSelected(nextSelected)
        end, 0.25, 0.1)

        self.keyInputRepeaters[keyCode] = repeater
    end
end

ColorGrid.didMount = function(self)
    self.keyDown = ColorEditorInputSignals.InputBegan:Connect(function(input)
        if (input.UserInputType ~= Enum.UserInputType.Keyboard) then return end

        local inputRepeater = self.keyInputRepeaters[input.KeyCode]
        if (not inputRepeater) then return end

        for _, repeater in pairs(self.keyInputRepeaters) do
            repeater:stop()
        end

        inputRepeater:start()
    end)

    self.keyUp = ColorEditorInputSignals.InputEnded:Connect(function(input)
        if (input.UserInputType ~= Enum.UserInputType.Keyboard) then return end

        local inputRepeater = self.keyInputRepeaters[input.KeyCode]
        if (not inputRepeater) then return end

        inputRepeater:stop()
    end)
end

ColorGrid.willUnmount = function(self)
    for _, repeater in pairs(self.keyInputRepeaters) do
        repeater:destroy()
    end

    self.keyInputRepeaters = nil
    self.keyDown:Disconnect()
    self.keyUp:Disconnect()
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

    colorElements.UIGridLayout = Roact.createElement("UIGridLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        StartCorner = Enum.StartCorner.TopLeft,

        CellSize = Style.UDim2.StandardButtonSize,
        CellPadding = Style.UDim2.MinorElementPaddingSize,

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateGridLength(obj.AbsoluteContentSize.Y)
        end,

        [Roact.Change.AbsoluteCellCount] = function(obj)
            self.updateCellsPerRow(obj.AbsoluteCellCount.X)
        end,
    })

    return Roact.createElement("Frame", {
        AnchorPoint = self.props.AnchorPoint,
        Position = self.props.Position,

        Size = self.gridLength:map(function(gridLength)
            return UDim2.new(1, 0, 0, gridLength + (self.props.title and (Style.Constants.StandardTextSize + Style.Constants.MinorElementPadding) or 0))
        end),

        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        GridLabel = self.props.title and
            Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
                Text = self.props.title,
            })
        or nil,

        Grid = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, 0, 1, self.props.title and -(Style.Constants.StandardTextSize + Style.Constants.MinorElementPadding) or 0),
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

    listElements.UIPadding = Roact.createElement(StandardUIPadding, {Style.Constants.MinorElementPadding})
    listElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        Padding = UDim.new(0, Style.Constants.MinorElementPadding),
        SortOrder = Enum.SortOrder.Name,

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateListLength(obj.AbsoluteContentSize.Y)
        end,

        preset = 1,
    })

    return Roact.createElement(StandardScrollingFrame, {
        AnchorPoint = self.props.AnchorPoint,
        Position = self.props.Position,
        Size = self.props.Size,

        CanvasSize = self.listLength:map(function(listLength)
            return UDim2.new(0, 0, 0, listLength + (Style.Constants.MinorElementPadding * 2))
        end)
    }, listElements)
end

---

ColorGrid = ConnectTheme(ColorGrid)

return ColorGrids