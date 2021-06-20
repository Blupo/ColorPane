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
        
        Text
        PlaceholderText?
        TextSize?
        TextXAlignment?

        usesTextBinding: boolean?

        canClear: boolean?
        disabled: boolean?
        isTextAValidValue: () -> boolean?
        onTextChanged: ()
]]

local TextInput = Roact.PureComponent:extend("TextInput")

TextInput.init = function(self)
    self.textBox = Roact.createRef()

    self:setState({
        focused = false,
        hover = false,
        invalidInput = false,
    })
end

TextInput.didUpdate = function(self, prevProps)
    if (self.props.usesTextBinding) then return end

    local text = self.props.Text

    if (self.state.invalidInput) then
        if (text ~= prevProps.Text) then
            self:setState({
                invalidInput = false,
            })
        end
    else
        local textBox = self.textBox:getValue()
        
        if (text ~= textBox.Text) then
            textBox.Text = text
        end
    end
end

TextInput.render = function(self)
    local theme = self.props.theme

    local borderColor
    local backgroundColor

    if (self.state.focused) then
        borderColor = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder, Enum.StudioStyleGuideModifier.Selected)
        backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground, Enum.StudioStyleGuideModifier.Selected)
    elseif (self.state.invalidInput) then
        borderColor = theme:GetColor(Enum.StudioStyleGuideColor.ErrorText)

        backgroundColor = theme:GetColor(
            Enum.StudioStyleGuideColor.InputFieldBackground,
            self.state.hover and Enum.StudioStyleGuideModifier.Hover or nil
        )
    else
        borderColor = theme:GetColor(
            Enum.StudioStyleGuideColor.InputFieldBorder,
            self.state.hover and Enum.StudioStyleGuideModifier.Hover or nil
        )

        backgroundColor = theme:GetColor(
            Enum.StudioStyleGuideColor.InputFieldBackground,
            self.state.hover and Enum.StudioStyleGuideModifier.Hover or nil
        )
    end

    return Roact.createElement("Frame", {
        AnchorPoint = self.props.AnchorPoint,
        Position = self.props.Position,
        Size = self.props.Size,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = borderColor,

        [Roact.Event.MouseEnter] = function()
            if ((self.state.focused) or (self.props.disabled)) then return end

            self:setState({
                hover = true
            })
        end,

        [Roact.Event.MouseLeave] = function()
            if (not self.state.hover) then return end

            self:setState({
                hover = false,
            })
        end
    }, {
        UICorner = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, 4),
        }),

        Input = Roact.createElement("TextBox", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, -2, 1, -2),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            TextEditable = (not self.props.disabled),

            Font = Style.StandardFont,
            ClearTextOnFocus = false,
            TextSize = self.props.TextSize or Style.StandardTextSize,
            TextXAlignment = self.props.TextXAlignment or Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            PlaceholderText = self.props.PlaceholderText or "",

            Text = self.props.usesTextBinding and
                self.props.Text:map(function(text)
                    if (not self.prevText) then
                        self.prevText = text
                    end

                    if (self.state.invalidInput) then
                        if (self.prevText ~= text) then
                            self:setState({
                                invalidInput = false,
                            })
                        else
                            return self.textBox:getValue().Text
                        end
                    end

                    self.prevText = text
                    return text
                end)
            or self.props.Text,

            BackgroundColor3 = backgroundColor,
            PlaceholderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Disabled),
            TextColor3 = theme:GetColor(
                Enum.StudioStyleGuideColor.MainText,
                self.props.disabled and Enum.StudioStyleGuideModifier.Disabled or nil
            ),

            [Roact.Ref] = self.textBox,

            [Roact.Event.Focused] = function()
                if (self.props.disabled) then return end

                self:setState({
                    focused = true,
                    hover = false,
                })
            end,

            [Roact.Event.FocusLost] = function(obj)
                if (self.props.disabled) then return end
                
                local originalText = self.props.usesTextBinding and self.props.Text:getValue() or self.props.Text
                local text = string.match(obj.Text, "^%s*(.-)%s*$")

                if (text == originalText) then
                    if (self.props.isTextAValidValue) then
                        self:setState({
                            focused = false,
                            invalidInput = (not self.props.isTextAValidValue(originalText)),
                        })
                    else
                        self:setState({
                            focused = false
                        })
                    end

                    return
                end

                if ((not self.props.canClear) and (text == "")) then
                    obj.Text = originalText

                    self:setState({
                        focused = false,
                        invalidInput = false,
                    })

                    return
                end

                if (self.props.isTextAValidValue and (not self.props.isTextAValidValue(text))) then
                    self:setState({
                        focused = false,
                        invalidInput = true,
                    })
                else
                    self:setState({
                        focused = false,
                        invalidInput = false,
                    })

                    self.props.onTextChanged(text)
                end
            end
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, 4),
            }),

            UIPadding = Roact.createElement(Padding, {0, Style.TextObjectPadding}),
        })
    })
    end

return ConnectTheme(TextInput)