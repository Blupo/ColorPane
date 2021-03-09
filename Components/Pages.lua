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

local Pages = Roact.Component:extend("Pages")

Pages.init = function(self, initProps)
    self:setState({
        page = initProps.initPage or 1,
        dropdownOpen = false,
        optionsOpen = false,
    })
end

Pages.didUpdate = function(self, prevProps)
    if (self.props.pages ~= prevProps.pages) then
        self:setState({
            page = self.props.initPage or 1,
        --  dropdownOpen = false,
        --  optionsOpen = false,
        })
    end
end

Pages.render = function(self)
    local theme = self.props.theme

    local currentPage = self.props.pages[self.state.page]
    if (not currentPage) then return end

    local list
    local numPagesListItems = #self.props.pages - 1

    if (self.state.dropdownOpen) then
        local pages = self.props.pages
        local pageListItems = {}

        for i = 1, #pages do
            local page = pages[i]

            if (page.name ~= currentPage.name) then
                pageListItems[#pageListItems + 1] = {
                    name = page.name,
                    layoutOrder = page.layoutOrder,

                    onActivated = function()
                        self:setState({
                            page = i,
                            dropdownOpen = false,
                        })
                        
                        if (self.props.onPageChanged) then
                            self.props.onPageChanged(i)
                        end
                    end,

                    [Roact.Children] = {
                        Padding = Roact.createElement(Padding, {0, 0, Style.SpaciousElementPadding, 0}),
                    }
                }
            end
        end

        list = Roact.createElement(SimpleList, {
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 1, 1, 5),
            Size = UDim2.new(1, self.props.options and (-Style.LargeButtonSize - 6) or -2, 0, Style.LargeButtonSize * ((numPagesListItems <= 5) and numPagesListItems or 5)),

            customLayout = self.props.customLayout,
            itemHeight = Style.LargeButtonSize,
            textSize = Style.LargeTextSize,
            items = pageListItems,
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

            itemHeight = Style.LargeButtonSize,
            textSize = Style.LargeTextSize,
            items = optionListItems,
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
                        local nextPage = (self.state.page - delta) % #self.props.pages

                        if (nextPage <= 0) then
                            nextPage = #self.props.pages
                        end

                        self:setState({
                            page = nextPage
                        })

                        if (self.props.onPageChanged) then
                            self.props.onPageChanged(nextPage)
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