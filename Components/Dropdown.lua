local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local ConnectTheme = require(Components:FindFirstChild("ConnectTheme"))
local Padding = require(Components:FindFirstChild("Padding"))
local SimpleList = require(Components:FindFirstChild("SimpleList"))

---

--[[
    props

        selectedItem: {number, number}

        itemSections: array<{
            name: string,

            items: array<{
                name: string,
                layoutOrder: number?
            }>
        }>

        options: array<{
            name: string
            onActivated: () -> nil
        }>?

        onExpandedStateToggle: (boolean) -> nil
        onItemChanged: (number, number) -> nil
]]

local Dropdown = Roact.PureComponent:extend("Dropdown")

Dropdown.init = function(self)
    self:setState({
        dropdownOpen = false,
        optionsOpen = false,
    })
end

Dropdown.didUpdate = function(self, _, prevState)
    local dropdownOpen = self.state.dropdownOpen
    local optionsOpen = self.state.optionsOpen

    if ((dropdownOpen == prevState.dropdownOpen) and (optionsOpen == prevState.optionsOpen)) then return end
    self.props.onExpandedStateToggle(dropdownOpen or optionsOpen)
end

Dropdown.render = function(self)
    local theme = self.props.theme
    local itemSections = self.props.itemSections

    local selectedItemIndices = self.props.selectedItem
    local selectedItemSectionNum, selectedItemNum = selectedItemIndices[1], selectedItemIndices[2]

    local selectedItemSection = itemSections[selectedItemSectionNum]
    if (not selectedItemSection) then return end

    local selectedItem = selectedItemSection.items[selectedItemNum]
    if (not selectedItem) then return end

    local list
    local numItemsListItems = 0

    for i = 1, #itemSections do
        local items = itemSections[i].items

        for j = 1, #items do
            if (items[j] ~= selectedItem) then
                numItemsListItems = numItemsListItems + 1
            end
        end
    end

    if (self.state.dropdownOpen) then
        local itemListSections = {}

        for i = 1, #itemSections do
            local section = itemSections[i]
            local sectionItems = section.items
            local newIndex = #itemListSections + 1

            itemListSections[newIndex] = {
                name = section.name,
                items = {}
            }

            local itemListSection = itemListSections[newIndex]

            for j = 1, #sectionItems do
                local item = sectionItems[j]

                if (item ~= selectedItem) then
                    table.insert(itemListSection.items, {
                        name = item.name,
                        layoutOrder = item.layoutOrder,
    
                        onActivated = function()
                            self:setState({
                                dropdownOpen = false,
                            })
                            
                            if (self.props.onItemChanged) then
                                self.props.onItemChanged(i, j)
                            end
                        end,
                    })
                end
            end
        end

        list = Roact.createElement(SimpleList, {
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 1, 1, 5),
            Size = UDim2.new(1, self.props.options and (-Style.LargeButtonSize - 6) or -2, 0, Style.LargeButtonSize * 5),
            TextSize = Style.LargeTextSize,

            itemHeight = Style.LargeButtonSize,
            itemPadding = Style.SpaciousElementPadding,
            sections = itemListSections,
        })
    elseif ((self.state.optionsOpen) and (self.props.options)) then
        local options = self.props.options
        local optionListItems = {}
        local numOptionsListItems = #options

        for i = 1, #options do
            local option = options[i]

            table.insert(optionListItems, {
                name = option.name,

                onActivated = function()
                    self:setState({
                        optionsOpen = false,
                        dropdownOpen = false,
                    })
                    
                    option.onActivated()
                end,

                [Roact.Children] = {
                    Padding = Roact.createElement(Padding, {0, 0, Style.SpaciousElementPadding, 0}),
                }
            })
        end

        list = Roact.createElement(SimpleList, {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -1, 1, 5),
            Size = UDim2.new(1, self.props.options and (-Style.LargeButtonSize - 6) or -2, 0, Style.LargeButtonSize * ((numOptionsListItems <= 8) and numOptionsListItems or 8)),
            TextSize = Style.LargeTextSize,

            itemHeight = Style.LargeButtonSize,
            
            sections = {
                {
                    name = "",
                    items = optionListItems
                }
            },
        })
    end

    return Roact.createElement("Frame", {
        AnchorPoint = self.props.AnchorPoint or Vector2.new(0.5, 0),
        Position = self.props.Position or UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, Style.LargeButtonSize),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        SelectionButton = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, self.props.options and (-Style.LargeButtonSize - 4) or 0, 1, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ClipsDescendants = true,

            BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ButtonBorder),
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, 4),
            }),

            Display = Roact.createElement("TextButton", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                AutoButtonColor = false,

                Font = Style.StandardFont,
                TextSize = Style.LargeTextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                Text = selectedItem.name,

                BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button),
                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ButtonText),

                [Roact.Event.InputChanged] = function(_, input)
                    if (self.state.dropdownOpen) then return end
                    if (input.UserInputType ~= Enum.UserInputType.MouseWheel) then return end

                    local delta = input.Position.Z
                    local nextItem = selectedItemNum - delta
                    local nextSection

                    if (nextItem <= 0) then
                        nextSection = selectedItemSectionNum - 1
                        nextSection = (nextSection > 0) and nextSection or #itemSections

                        nextItem = #itemSections[nextSection].items
                    elseif (nextItem > #selectedItemSection.items) then
                        nextSection = selectedItemSectionNum + 1
                        nextSection = (nextSection <= #itemSections) and nextSection or 1

                        nextItem = 1
                    else
                        nextSection = selectedItemSectionNum
                    end

                    -- handle the case of empty sections
                    -- note: this will cause an infinite loop if every section is empty
                    local section = itemSections[nextSection]

                    while (#section.items < 1) do
                        nextSection = nextSection - delta
                        
                        if (nextSection <= 0) then
                            nextSection = #itemSections
                        elseif (nextSection > #itemSections) then
                            nextSection = 1
                        end

                        section = itemSections[nextSection]
                        
                        if (delta == -1) then
                            nextItem = 1
                        elseif (delta == 1) then
                            nextItem = #section.items
                        end
                    end

                    self.props.onItemChanged(nextSection, nextItem)
                end,

                [Roact.Event.MouseEnter] = function(obj)
                    if (numItemsListItems < 1) then return end

                    obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
                end,

                [Roact.Event.MouseLeave] = function(obj)
                    if (numItemsListItems < 1) then return end

                    obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button)
                end,

                [Roact.Event.Activated] = function()
                    if (numItemsListItems < 1) then return end
    
                    self:setState(function(oldState)
                        return {
                            dropdownOpen = (not oldState.dropdownOpen),
                            optionsOpen = false,
                        }
                    end)
                end,
            }, {
                UICorner = Roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                }),

                UIPadding = Roact.createElement(Padding, {0, 0, Style.SpaciousElementPadding, 0}),

                Icon = (numItemsListItems >= 1) and
                    Roact.createElement("ImageLabel", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -2, 0.5, 0),
                        Size = UDim2.new(0, Style.StandardButtonSize, 0, Style.StandardButtonSize),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
    
                        Image = self.state.dropdownOpen and Style.DropdownCloseImage or Style.DropdownOpenImage,
                        ImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ButtonText),
                    })
                or nil
            }),
        }),

        OptionsButton = self.props.options and
            Roact.createElement(Button, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, Style.LargeButtonSize, 0, Style.LargeButtonSize),

                displayType = "image",
                image = Style.PageOptionsImage,

                onActivated = function()
                    self:setState(function(oldState)
                        return {
                            optionsOpen = (not oldState.optionsOpen),
                            dropdownOpen = false,
                        }
                    end)
                end
            })
        or nil,

        List = list,
    })
end

---

return ConnectTheme(Dropdown)