local TextService = game:GetService("TextService")

---

local root = script.Parent.Parent

local PluginModules = root.PluginModules
local Style = require(PluginModules.Style)

local Includes = root.Includes
local Roact = require(Includes.RoactRodux.Roact)

local Components = root.Components
local ConnectTheme = require(Components.ConnectTheme)

local StandardComponents = Components.StandardComponents
local StandardUICorner = require(StandardComponents.UICorner)
local StandardUIPadding = require(StandardComponents.UIPadding)

---

--[[
    props
        AnchorPoint?
        Position?
        Size?
        LayoutOrder?
        
        Text
        PlaceholderText?
        TextSize?
        TextXAlignment?

        canSubmitEmptyString: boolean?
        disabled: boolean?
        selectTextOnFocus: boolean?

        isTextAValidValue: (string)? -> boolean
        onTextChanged: (string)?
        onSubmit: (string)?

    store props

        theme: StudioTheme
]]

local TextInput = Roact.PureComponent:extend("TextInput")

TextInput.init = function(self)
    self.textBox = Roact.createRef()
    self.textBoxContainer = Roact.createRef()
    self.textBoxOffset, self.updateTextBoxOffset = Roact.createBinding(0)

    self.updateOffsets = function()
        local textBox = self.textBox:getValue()
        local textBoxContainer = self.textBoxContainer:getValue()
        if (not (textBox and textBoxContainer)) then return end

        local textBounds = textBox.TextBounds
        local textBoxContainerSize = textBoxContainer.AbsoluteSize

        if (textBounds.X <= (textBoxContainerSize.X - (Style.Constants.TextObjectPadding * 2))) then
            self.updateTextBoxOffset(0)
            return
        end

        local cursorPosition = textBox.CursorPosition
        if (cursorPosition < 1) then return end
        
        local textBoxPosition = textBox.AbsolutePosition
        local textBoxPositionStart, textBoxPositionEnd = textBoxPosition.X, textBoxPosition.X + textBox.AbsoluteSize.X

        local textBoxContainerPosition = textBoxContainer.AbsolutePosition
        local textBoxContainerPositionStart = textBoxContainerPosition.X + Style.Constants.TextObjectPadding
        local textBoxContainerPositionEnd = textBoxContainerPosition.X + textBoxContainerSize.X - Style.Constants.TextObjectPadding

        local startToCursorSubstring = string.sub(textBox.Text, 1, cursorPosition - 1)
        local startToCursorSubstringBounds = TextService:GetTextSize(startToCursorSubstring, textBox.TextSize, textBox.Font, Vector2.new(math.huge, math.huge))
        local startToCursorSubstringEnd = textBoxPositionStart + startToCursorSubstringBounds.X

        local offset = 0
        
        if (textBoxPositionEnd < textBoxContainerPositionEnd) then
            offset = offset + (textBoxContainerPositionEnd - textBoxPositionEnd)
        end

        if (startToCursorSubstringEnd < textBoxContainerPositionStart) then
            offset = textBoxContainerPositionStart - startToCursorSubstringEnd
        elseif (startToCursorSubstringEnd > textBoxContainerPositionEnd)  then
            offset = textBoxContainerPositionEnd - startToCursorSubstringEnd
        end

        self.updateTextBoxOffset(self.textBoxOffset:getValue() + offset)
    end

    self:setState({
        focused = false,
        hover = false,
        invalidInput = false,
    })
end

TextInput.didUpdate = function(self, prevProps)
    local newText = self.props.Text
    local prevText = prevProps.Text

    if (newText ~= prevText) then
        self:setState({
            invalidInput = false
        })
    end
end

TextInput.willUnmount = function(self)
    --[[
        Some of TextBox's events that are used will fire when the
        object is about to be destroyed, which causes problems.
    ]]

    self.unmounting = true
end

TextInput.render = function(self)
    local theme = self.props.theme
    local disabled = self.props.disabled

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
        LayoutOrder = self.props.LayoutOrder,

        BackgroundColor3 = borderColor,

        [Roact.Ref] = self.textBoxContainer,
        [Roact.Change.AbsoluteSize] = self.updateOffsets,

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
        UICorner = Roact.createElement(StandardUICorner),

        Background = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, -2, 1, -2),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ClipsDescendants = true,

            BackgroundColor3 = backgroundColor,
        }, {
            UICorner = Roact.createElement(StandardUICorner),
            UIPadding = Roact.createElement(StandardUIPadding, {0, Style.Constants.TextObjectPadding}),

            Input = Roact.createElement("TextBox", {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                TextEditable = (not disabled),
    
                Position = self.textBoxOffset:map(function(offset)
                    return UDim2.new(0, offset, 0.5, 0)
                end),
    
                Font = Style.Fonts.Standard,
                MultiLine = false,
                ClearTextOnFocus = false,
                TextSize = self.props.TextSize or Style.Constants.StandardTextSize,
                TextXAlignment = self.props.TextXAlignment or Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                PlaceholderText = self.props.PlaceholderText or "",
                Text = self.props.Text,
    
                TextColor3 = theme:GetColor(
                    Enum.StudioStyleGuideColor.MainText,
                    disabled and Enum.StudioStyleGuideModifier.Disabled or nil
                ),
    
                PlaceholderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Disabled),
    
                [Roact.Ref] = self.textBox,
                [Roact.Change.CursorPosition] = self.updateOffsets,
    
                [Roact.Event.Focused] = function(obj)
                    if (disabled) then return end
                    
                    if (self.props.selectTextOnFocus) then
                        obj.CursorPosition = string.len(obj.Text) + 1
                        obj.SelectionStart = 1
                    end
    
                    self:setState({
                        focused = true,
                        hover = false,
                    })
                end,
    
                [Roact.Event.FocusLost] = function(obj)
                    if (self.unmounting) then return end -- we could also check if the InputObject is nil
                    if (disabled) then return end
    
                    local newText = string.match(obj.Text, "^%s*(.-)%s*$")
                    local isValid = (not isTextAValidValue) and true or isTextAValidValue(newText)
                    local originalText = self.props.Text
    
                    if (newText == originalText) then
                        self:setState({
                            focused = false,
                        })
    
                        obj.Text = originalText
                        return
                    end

                    if ((not self.props.canSubmitEmptyString) and (newText == "")) then
                        self:setState({
                            focused = false,
                        })

                        obj.Text = originalText
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
    
                    self.updateTextBoxOffset(0)
                    self:setState({
                        focused = false,
                        invalidInput = (not isValid),
                    })
                end,
    
                [Roact.Change.TextBounds] = function(obj)
                    if (self.unmounting) then return end

                    local textBoxContainer = obj.Parent
                    if (not textBoxContainer) then return end
    
                    local textBounds = obj.TextBounds
                    local containerSize = textBoxContainer.AbsoluteSize

                    local actualContainerSize = containerSize.X - (Style.Constants.TextObjectPadding * 2)
                    if (actualContainerSize <= 0) then return end
    
                    obj.Size = UDim2.new(
                        (textBounds.X > actualContainerSize) and UDim.new(0, textBounds.X) or UDim.new(1, 0),
                        UDim.new(1, 0)
                    )

                    self.updateOffsets()
                end,
    
                [Roact.Change.Text] = function(obj)
                    if (self.unmounting) then return end
                    if (disabled) then return end
    
                    local newText = string.match(obj.Text, "^%s*(.-)%s*$")
    
                    if (onTextChanged) then
                        onTextChanged(newText)
                    end
                end
            })
        })
    })
end

return ConnectTheme(TextInput)