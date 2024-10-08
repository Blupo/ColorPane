-- A selection button and list

local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local Style = require(CommonModules.Style)

local CommonIncludes = Common.Includes
local Roact = require(CommonIncludes.RoactRodux.Roact)

local CommonComponents = Common.Components
local Button = require(CommonComponents.Button)
local ConnectTheme = require(CommonComponents.ConnectTheme)

local StandardComponents = CommonComponents.StandardComponents
local StandardUICorner = require(StandardComponents.UICorner)
local StandardUIPadding = require(StandardComponents.UIPadding)

local Components = root.Components
local SimpleList = require(Components.SimpleList)

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

    store props
        theme: StudioTheme
]]

local Selection = Roact.PureComponent:extend("Selection")

Selection.init = function(self)
    self:setState({
        dropdownOpen = false,
        optionsOpen = false,
    })

    self.updateSelection = function(delta)
        return function()
            if (self.state.dropdownOpen) then return end
            
            local itemSections = self.props.itemSections
            local selectedItemIndices = self.props.selectedItem
            if (not (itemSections and selectedItemIndices)) then return end

            local selectedItemSectionNum, selectedItemNum = selectedItemIndices[1], selectedItemIndices[2]

            local nextSection
            local nextItem = selectedItemNum + delta
            
            if (nextItem <= 0) then
                nextSection = selectedItemSectionNum - 1
                nextSection = if (nextSection == 0) then #itemSections else nextSection

                nextItem = #itemSections[nextSection].items
            elseif (nextItem > #itemSections[selectedItemSectionNum].items) then
                nextSection = selectedItemSectionNum + 1
                nextSection = if (nextSection > #itemSections) then 1 else nextSection

                nextItem = 1
            else
                nextSection = selectedItemSectionNum
            end

            if (nextSection ~= selectedItemSectionNum) then
                -- This does not account for the case where every section is empty,
                -- which should not happen in production.

                local section = itemSections[nextSection]

                while (#section.items <= 0) do
                    nextSection = nextSection + delta

                    if (nextSection <= 0) then
                        nextSection = #itemSections
                    elseif (nextSection > #itemSections) then
                        nextSection = 1
                    end

                    section = itemSections[nextSection]
                end
                
                if (delta == -1) then
                    nextItem = #section.items
                elseif (delta == 1) then
                    nextItem = 1
                end
            end

            self.props.onItemChanged(nextSection, nextItem)
        end
    end
end

Selection.didUpdate = function(self, _, prevState)
    local dropdownOpen = self.state.dropdownOpen
    local optionsOpen = self.state.optionsOpen

    if ((dropdownOpen ~= prevState.dropdownOpen) or (optionsOpen ~= prevState.optionsOpen)) then
        self.props.onExpandedStateToggle(dropdownOpen or optionsOpen)
    elseif (optionsOpen and (not self.props.options)) then
        self:setState({
            optionsOpen = false,
        })
    end
end

Selection.render = function(self)
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
            TextSize = Style.Constants.LargeTextSize,
            
            Size = UDim2.new(
                1, if self.props.options then (-Style.Constants.LargeButtonHeight - 6) else -2,
                0, Style.Constants.LargeButtonHeight * 5
            ),

            itemHeight = Style.Constants.LargeButtonHeight,
            itemPadding = Style.Constants.SpaciousElementPadding,
            sections = itemListSections,
        })
    elseif (self.state.optionsOpen and self.props.options) then
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
                    UIPadding = Roact.createElement(StandardUIPadding, {
                        paddings = {0, 0, Style.Constants.SpaciousElementPadding, 0}
                    }),
                }
            })
        end

        list = Roact.createElement(SimpleList, {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -1, 1, 5),
            TextSize = Style.Constants.LargeTextSize,
            
            Size = UDim2.new(
                1, if self.props.options then (-Style.Constants.LargeButtonHeight - 6) else -2,
                0, Style.Constants.LargeButtonHeight * (if (numOptionsListItems <= 8) then numOptionsListItems else 8)
            ),

            itemHeight = Style.Constants.LargeButtonHeight,
            
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
        Size = UDim2.new(1, 0, 0, Style.Constants.LargeButtonHeight),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        SelectionButton = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, if self.props.options then (-Style.Constants.LargeButtonHeight - 4) else 0, 1, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ClipsDescendants = true,

            BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ButtonBorder),
        }, {
            UICorner = Roact.createElement(StandardUICorner),

            Display = Roact.createElement("TextButton", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                AutoButtonColor = false,

                Font = Style.Fonts.Standard,
                TextSize = Style.Constants.LargeTextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                Text = selectedItem.name,

                BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button),
                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ButtonText),

                [Roact.Event.MouseWheelForward] = self.updateSelection(-1),
                [Roact.Event.MouseWheelBackward] = self.updateSelection(1),

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
                UICorner = Roact.createElement(StandardUICorner),
                
                UIPadding = Roact.createElement(StandardUIPadding, {
                    paddings = {0, 0, Style.Constants.SpaciousElementPadding, 0}
                }),

                Icon = if (numItemsListItems >= 1) then
                    Roact.createElement("ImageLabel", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -2, 0.5, 0),
                        Size = Style.UDim2.StandardButtonSize,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
    
                        Image = if self.state.dropdownOpen then Style.Images.CloseDropdownButtonIcon else Style.Images.OpenDropdownButtonIcon,
                        ImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ButtonText),
                    })
                else nil
            }),
        }),

        OptionsButton = if self.props.options then
            Roact.createElement(Button, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, Style.Constants.LargeButtonHeight, 0, Style.Constants.LargeButtonHeight),

                displayType = "image",
                image = Style.Images.PageOptionsButtonIcon,

                onActivated = function()
                    self:setState(function(oldState)
                        return {
                            optionsOpen = (not oldState.optionsOpen),
                            dropdownOpen = false,
                        }
                    end)
                end
            })
        else nil,

        List = list,
    })
end

---

return ConnectTheme(Selection)