local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local ConnectTheme = require(Components:FindFirstChild("ConnectTheme"))

---

--[[
    props

        AnchorPoint?
        Position?
        Size?
        TextSize?

        itemHeight: number
        customLayout: boolean?
        
        items: array<{
            name: string,
            onActivated: () -> nil,

            LayoutOrder: number?
            [Roact.Children]: dictionary<any, Element>? 
        }>
]]

local SimpleList = Roact.PureComponent:extend("SimpleList")

SimpleList.init = function(self)
    self.listLength, self.updateListLength = Roact.createBinding(0)
end

SimpleList.render = function(self)
    local theme = self.props.theme

    local listItems = {}

    for i = 1, #self.props.items do
        local item = self.props.items[i]

        listItems[#listItems + 1] = Roact.createElement("TextButton", {
            Size = UDim2.new(1, 0, 0, self.props.itemHeight),
            AutoButtonColor = false,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            LayoutOrder = self.props.customLayout and item.LayoutOrder or i,

            Font = Enum.Font.SourceSans,
            TextSize = self.props.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Text = item.name,

            BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button),
            TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ButtonText),

            [Roact.Event.MouseEnter] = function(obj)
                obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
            end,

            [Roact.Event.MouseLeave] = function(obj)
                obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button)
            end,

            [Roact.Event.MouseButton1Down] = function(obj)
                obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Pressed)
            end,

            [Roact.Event.MouseButton1Up] = function(obj)
                obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button)
            end,

            [Roact.Event.Activated] = item.onActivated,

            [Roact.Children] = item[Roact.Children]
        })
    end

    listItems["UIListLayout"] = Roact.createElement("UIListLayout", {
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
        ClipsDescendants = true,
       
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

        ScrollBarImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ScrollBar),
        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame),
        BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
    }, listItems)
end

return ConnectTheme(SimpleList)