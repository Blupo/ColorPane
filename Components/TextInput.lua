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

        canClear: boolean?
        disabled: boolean?
        usesTextBinding: boolean?
        selectTextOnFocus: boolean?

        isTextAValidValue: (string)? -> boolean
        onTextChanged: (string)?
        onSubmit: (string)?
]]

local TextInput = Roact.PureComponent:extend("TextInput")

TextInput.init = function(self, initProps)
    self.lastText = initProps.usesTextBinding and initProps.Text:getValue() or initProps.Text

    self:setState({
        focused = false,
        hover = false,
        invalidInput = false,
    })
end

TextInput.didUpdate = function(self, prevProps)
    if (self.props.usesTextBinding) then return end

    local newText = self.props.Text
    local prevText = prevProps.Text

    if (newText ~= prevText) then
        self.lastText = newText

        self:setState({
            invalidInput = false
        })
    end
end

TextInput.render = function(self)
    local theme = self.props.theme
    local disabled = self.props.disabled
    local usesTextBinding = self.props.usesTextBinding

    local isTextAValidValue = self.props.isTextAValidValue
    local onTextChanged = self.props.onTextChanged
    local onSubmit = self.props.onSubmit

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
            if (self.state.focused or disabled) then return end

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
            TextEditable = (not disabled),

            Font = Style.StandardFont,
            ClearTextOnFocus = false,
            TextSize = self.props.TextSize or Style.StandardTextSize,
            TextXAlignment = self.props.TextXAlignment or Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            PlaceholderText = self.props.PlaceholderText or "",

            Text = usesTextBinding and
                self.props.Text:map(function(text)
                    if (self.state.invalidInput) then
                        if (text ~= self.lastBindingText) then
                            self:setState({
                                invalidInput = false
                            })
                        else
                            return self.lastText
                        end
                    end

                    self.lastBindingText = text
                    return text
                end)
            or self.props.Text,

            TextColor3 = theme:GetColor(
                Enum.StudioStyleGuideColor.MainText,
                disabled and Enum.StudioStyleGuideModifier.Disabled or nil
            ),

            BackgroundColor3 = backgroundColor,
            PlaceholderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Disabled),

            [Roact.Event.Focused] = function(obj)
                if (disabled) then return end
                
                if (self.props.selectTextOnFocus) then
                    obj.CursorPosition = string.len(obj.Text) + 1
                    obj.SelectionStart = 1
                end

                self:setState({
                    focused = true,
                    hover = false,
                    invalidInput = false,
                })
            end,

            [Roact.Event.FocusLost] = function(obj)
                if (disabled) then return end

                local newText = string.match(obj.Text, "^%s*(.-)%s*$")
                local isValid = (not isTextAValidValue) and true or isTextAValidValue(newText)
                local originalText = usesTextBinding and self.props.Text:getValue() or self.props.Text

                if (newText == originalText) then
                    self:setState({
                        focused = false,
                    })

                    obj.Text = originalText
                    self.lastText = originalText
                    return
                end

                if (isValid and onSubmit) then
                    --[[
                        Since we can't know if the Text prop will change after onSubmit,
                        we need to reset the TextBox's Text to its original value.

                        If Text does change, the TextBox's Text will briefly flicker.
                        If Text doesn't change, that's what this line of code is for.
                    --]]
                    obj.Text = originalText

                    onSubmit(newText)
                end

                self:setState({
                    focused = false,
                    invalidInput = (not isValid),
                })
            end,

            [Roact.Change.Text] = function(obj)
                if (disabled) then return end

                local newText = string.match(obj.Text, "^%s*(.-)%s*$")

                if ((not self.props.canClear) and (newText == "")) then
                    obj.Text = self.lastText
                    return
                else
                    self.lastText = newText
                end

                if (onTextChanged) then
                    onTextChanged(newText)
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