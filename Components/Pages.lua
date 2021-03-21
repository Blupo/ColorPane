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
        initPage: number?

        pageSections: array<{
            name: string,

            pages: array<{
                name: string,
                layoutOrder: number
            }>
        }>

        options: array<{
            name: string
            onActivated: () -> nil
        }>

        onPageChanged = (number) -> nil
]]

local Pages = Roact.PureComponent:extend("Pages")

Pages.init = function(self, initProps)
    self:setState({
        page = initProps.initPage or {1, 1},
        dropdownOpen = false,
        optionsOpen = false,
    })
end

Pages.didUpdate = function(self, prevProps)
    if (self.props.pageSections ~= prevProps.pageSections) then
        self:setState({
            page = self.props.initPage or {1, 1},
        })
    end
end

Pages.render = function(self)
    local theme = self.props.theme
    local pageSections = self.props.pageSections

    local currentPageIndices = self.state.page
    local currentPageSectionNum, currentPageNum = currentPageIndices[1], currentPageIndices[2]

    local currentPageSection = pageSections[currentPageSectionNum]
    if (not currentPageSection) then return end

    local currentPage = currentPageSection.pages[currentPageNum]
    if (not currentPage) then return end

    local list
    local numPagesListItems = 0

    for i = 1, #pageSections do
        local pages = pageSections[i].pages

        for j = 1, #pages do
            if (pages[j] ~= currentPage) then
                numPagesListItems = numPagesListItems + 1
            end
        end
    end

    if (self.state.dropdownOpen) then
        local pageListSections = {}

        for i = 1, #pageSections do
            local section = pageSections[i]
            local sectionPages = section.pages
            local newIndex = #pageListSections + 1

            pageListSections[newIndex] = {
                name = section.name,
                items = {}
            }

            local pageListSection = pageListSections[newIndex]

            for j = 1, #sectionPages do
                local page = sectionPages[j]

                if (page ~= currentPage) then
                    pageListSection.items[#pageListSection.items + 1] = {
                        name = page.name,
                        layoutOrder = page.layoutOrder,
    
                        onActivated = function()
                            self:setState({
                                page = {i, j},
                                dropdownOpen = false,
                            })
                            
                            if (self.props.onPageChanged) then
                                self.props.onPageChanged(i, j)
                            end
                        end,
                    }
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
            sections = pageListSections,
        })
    elseif ((self.state.optionsOpen) and (self.props.options)) then
        local options = self.props.options
        local optionListItems = {}
        local numOptionsListItems = #options

        for i = 1, #options do
            local option = options[i]

            optionListItems[#optionListItems + 1] = {
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
            }
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
    
    return Roact.createFragment({
        Dropdown = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
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
                    Text = currentPage.name,

                    BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button),
                    TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ButtonText),

                    [Roact.Event.InputChanged] = function(_, input)
                        if (self.state.dropdownOpen) then return end
                        if (input.UserInputType ~= Enum.UserInputType.MouseWheel) then return end

                        local delta = input.Position.Z
                        local nextPage = currentPageNum - delta
                        local nextSection

                        if (nextPage <= 0) then
                            nextSection = currentPageSectionNum - 1
                            nextSection = (nextSection > 0) and nextSection or #pageSections

                            nextPage = #pageSections[nextSection].pages
                        elseif (nextPage > #currentPageSection.pages) then
                            nextSection = currentPageSectionNum + 1
                            nextSection = (nextSection <= #pageSections) and nextSection or 1

                            nextPage = 1
                        else
                            nextSection = currentPageSectionNum
                        end

                        self:setState({
                            page = {nextSection, nextPage}
                        })

                        if (self.props.onPageChanged) then
                            self.props.onPageChanged(nextSection, nextPage)
                        end
                    end,

                    [Roact.Event.MouseEnter] = function(obj)
                        if (numPagesListItems < 1) then return end

                        obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
                    end,

                    [Roact.Event.MouseLeave] = function(obj)
                        if (numPagesListItems < 1) then return end

                        obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button)
                    end,

                    [Roact.Event.Activated] = function()
                        if (numPagesListItems < 1) then return end
        
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

                    Icon = (numPagesListItems >= 1) and
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
        }),

        Page = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, 0, 1, -Style.LargeButtonSize - Style.MajorElementPadding),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Content = (not (self.state.dropdownOpen or self.state.optionsOpen)) and currentPage.content or nil
        })
    })
end

return ConnectTheme(Pages)