-- Component that presents text to be copied

local TextService = game:GetService("TextService")

---

local root = script.Parent.Parent

local Modules = root.Modules
local Style = require(Modules.Style)

local Includes = root.Includes
local Roact = require(Includes.RoactRodux.Roact)

local Components = root.Components
local ConnectTheme = require(Components.ConnectTheme)

local StandardComponents = Components.StandardComponents
local StandardTextLabel = require(StandardComponents.TextLabel)
local StandardUICorner = require(StandardComponents.UICorner)
local StandardUIPadding = require(StandardComponents.UIPadding)

---

--[[
    props

        text: string
        promptText: string
    
    store props

        theme: StudioTheme
]]
local ExportText = Roact.PureComponent:extend("ExportText")

ExportText.init = function(self)
    self:setState({
        width = 0,
    })
end

ExportText.render = function(self)
    local theme = self.props.theme
    local text = self.props.text
    local promptText = self.props.promptText

    local promptTextSize = TextService:GetTextSize(
        promptText,
        Style.Constants.StandardTextSize,
        Style.Fonts.Standard,
        Vector2.new(self.state.width - (Style.Constants.PagePadding * 2), math.huge)
    )

    local textSize = TextService:GetTextSize(
        text,
        Style.Constants.StandardTextSize,
        Enum.Font.Code,
        Vector2.new(math.huge, math.huge)
    )

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),

        [Roact.Change.AbsoluteSize] = function(obj)
            local absoluteSize = obj.AbsoluteSize

            self:setState({
                width = absoluteSize.X
            })
        end,
    }, {
        UIPadding = Roact.createElement(StandardUIPadding, {
            paddings = {Style.Constants.PagePadding}
        }),

        PromptText = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, promptTextSize.Y),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Text = promptText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
        }),

        CopyTextWrapper = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, 0, 1, -(promptTextSize.Y + Style.Constants.SpaciousElementPadding)),
            BorderSizePixel = 0,

            BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
        }, {
            UICorner = Roact.createElement(StandardUICorner),
        
            CopyText = Roact.createElement("ScrollingFrame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                CanvasSize = UDim2.new(
                    0, textSize.X + (Style.Constants.MinorElementPadding * 2),
                    0, textSize.Y + (Style.Constants.MinorElementPadding * 2)
                ),

                ClipsDescendants = true,
                TopImage = Style.Images.ScrollbarImage,
                MidImage = Style.Images.ScrollbarImage,
                BottomImage = Style.Images.ScrollbarImage,
                HorizontalScrollBarInset = Enum.ScrollBarInset.Always,
                VerticalScrollBarInset = Enum.ScrollBarInset.Always,
                VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right,
                ScrollBarThickness = Style.Constants.ScrollbarThickness / 4,

                ScrollBarImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ScrollBar),
            }, {
                UIPadding = Roact.createElement(StandardUIPadding, {
                    paddings = {Style.Constants.MinorElementPadding}
                }),

                TextBox = Roact.createElement("TextBox", {
                    AnchorPoint = Vector2.new(0, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,

                    Text = text,
                    Font = Enum.Font.Code,
                    TextSize = Style.Constants.StandardTextSize,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    ClearTextOnFocus = false,
                    TextEditable = false,

                    TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),

                    [Roact.Event.Focused] = function(obj)
                        obj.CursorPosition = string.len(obj.Text) + 1
                        obj.SelectionStart = 1
                    end,
                })
            })
        })
    })
end

return ConnectTheme(ExportText)