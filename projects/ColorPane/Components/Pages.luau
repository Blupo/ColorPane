--[[
    A container for multiple pages which can be selected with a dropdown,
    and also contains a button for showing page options
]]

local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local Style = require(CommonModules.Style)

local CommonIncludes = Common.Includes
local Roact = require(CommonIncludes.RoactRodux.Roact)

local Components = root.Components
local Selection = require(Components.Selection)

---

--[[
    props
        selectedPage: {number, number}

        pageSections: array<{
            name: string,

            items: array<{
                name: string,
                content: Element,
                layoutOrder: number?,
            }>
        }>

        options: array<{
            name: string
            onActivated: () -> nil
        }>

        onPageChanged: (number, number) -> nil
]]

local Pages = Roact.PureComponent:extend("Pages")

Pages.init = function(self)
    self:setState({
        dropdownExpanded = false,
    })
end

Pages.render = function(self)
    local pageSections = self.props.pageSections

    local selectedPageIndices = self.props.selectedPage
    local selectedPageSectionNum, selectedPageNum = selectedPageIndices[1], selectedPageIndices[2]

    local selectedPageSection = pageSections[selectedPageSectionNum]
    if (not selectedPageSection) then return end

    local selectedPage = selectedPageSection.items[selectedPageNum]
    if (not selectedPage) then return end
    
    return Roact.createFragment({
        Selection = Roact.createElement(Selection, {
            selectedItem = selectedPageIndices,
            itemSections = pageSections,
            options = self.props.options,

            onExpandedStateToggle = function(expanded)
                self:setState({
                    dropdownExpanded = expanded
                })
            end,

            onItemChanged = self.props.onPageChanged
        }),

        Page = if (not self.state.dropdownExpanded) then
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, 0),
                Size = UDim2.new(1, 0, 1, -(Style.Constants.LargeButtonHeight + Style.Constants.MajorElementPadding)),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                Content = selectedPage.content
            })
        else nil
    })
end

return Pages