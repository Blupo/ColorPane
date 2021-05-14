local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local ConnectTheme = require(Components:FindFirstChild("ConnectTheme"))
local Padding = require(Components:FindFirstChild("Padding"))

---

--[[
    props

        AnchorPoint?
        Position?
        Size?
        TextSize?

        itemHeight: number
        itemPadding: number?
        
        sections: array<{
            name: string,

            items: array<{
                name: string,
                onActivated: () -> nil,

                LayoutOrder: number?
                [Roact.Children]: dictionary<any, Element>? 
            }>
        }>
]]

local SimpleList = Roact.PureComponent:extend("SimpleList")

SimpleList.init = function(self)
    self.listLength, self.updateListLength = Roact.createBinding(0)
end

SimpleList.render = function(self)
    local theme = self.props.theme
    local sections = self.props.sections

    local listItems = {}

    for i = 1, #sections do
        local section = sections[i]
        local shouldShowSectionHeader = true

        if ((not self.props.showAllSections) and (((i == 1) and (#sections == 1)) or (#section.items < 1))) then
            shouldShowSectionHeader = false
        end

        if (shouldShowSectionHeader) then
            table.insert(listItems, Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, self.props.itemHeight),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                LayoutOrder = #listItems + 1,

                Font = Enum.Font.SourceSansBold,
                TextSize = self.props.TextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                Text = section.name,

                BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.HeaderSection),
                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
            }, {
                UIPadding = self.props.itemPadding and
                    Roact.createElement(Padding, {0, 0, self.props.itemPadding, 0})
                or nil,
            }))
        end

        for j = 1, #section.items do
            local item = section.items[j]
            local children

            if (item[Roact.Children]) then
                children = item[Roact.Children]
            else
                if (self.props.itemPadding) then
                    children = {
                        UIPadding = Roact.createElement(Padding, {0, 0, self.props.itemPadding, 0})
                    }
                end
            end

            table.insert(listItems, Roact.createElement("TextButton", {
                Size = UDim2.new(1, 0, 0, self.props.itemHeight),
                AutoButtonColor = false,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                LayoutOrder = #listItems + 1,
    
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
    
                [Roact.Event.Activated] = function()
                    item.onActivated()
                end,
            }, children))
        end
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