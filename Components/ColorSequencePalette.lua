local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Color = require(PluginModules:FindFirstChild("Color"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local RepeatingCallback = require(PluginModules:FindFirstChild("RepeatingCallback"))
local Style = require(PluginModules:FindFirstChild("Style"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local TextInput = require(Components:FindFirstChild("TextInput"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardScrollingFrame = StandardComponents.ScrollingFrame
local StandardTextLabel = StandardComponents.TextLabel
local StandardUIListLayout = StandardComponents.UIListLayout
local StandardUIPadding = StandardComponents.UIPadding

---

local KELVIN_LOWER_RANGE = 1000
local KELVIN_UPPER_RANGE = 10000

local KEY_CODE_DELTAS = {
    [Enum.KeyCode.Up] = -1,
    [Enum.KeyCode.Down] = 1,
}

local shallowCompare = Util.shallowCompare

local getKelvinRangeValue = function(k)
    k = math.clamp(k, KELVIN_LOWER_RANGE, KELVIN_UPPER_RANGE)

    return (k - KELVIN_LOWER_RANGE) / (KELVIN_UPPER_RANGE - KELVIN_LOWER_RANGE)
end

local builtInSequences = {
    {
        name = "Black to White",

        color = ColorSequence.new(
            Color3.new(0, 0, 0),
            Color3.new(1, 1, 1)
        )
    },

    {
        name = "Hue",

        color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
            ColorSequenceKeypoint.new(1/6, Color3.fromHSV(1/6, 1, 1)),
            ColorSequenceKeypoint.new(2/6, Color3.fromHSV(2/6, 1, 1)),
            ColorSequenceKeypoint.new(3/6, Color3.fromHSV(3/6, 1, 1)),
            ColorSequenceKeypoint.new(4/6, Color3.fromHSV(4/6, 1, 1)),
            ColorSequenceKeypoint.new(5/6, Color3.fromHSV(5/6, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
        })
    },

    {
        name = "Temperature",

        color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color.toColor3(Color.fromKelvin(1000))),
            ColorSequenceKeypoint.new(getKelvinRangeValue(2000), Color.toColor3(Color.fromKelvin(2000))),
            ColorSequenceKeypoint.new(getKelvinRangeValue(6000), Color.toColor3(Color.fromKelvin(6000))),
            ColorSequenceKeypoint.new(getKelvinRangeValue(6500), Color.toColor3(Color.fromKelvin(6500))),
            ColorSequenceKeypoint.new(getKelvinRangeValue(7000), Color.toColor3(Color.fromKelvin(7000))),
            ColorSequenceKeypoint.new(1, Color.toColor3(Color.fromKelvin(10000))),
        })
    }
}

local numBuiltInSequences = #builtInSequences

---

--[[
    props

        getCurrentColorSequence: () -> ColorSequence
        setCurrentColorSequence: (ColorSequence) -> nil
]]

local ColorSequencePalette = Roact.Component:extend("ColorSequencePalette")

ColorSequencePalette.init = function(self)
    self.listLength, self.updateListLength = Roact.createBinding(0)
    self.keyInputRepeaters = {}

    self.combinePaletteItems = function()
        local combinedPalette = {}
        local userColorSequences = self.props.colorSequences

        for i = 1, numBuiltInSequences do
            table.insert(combinedPalette, builtInSequences[i])
        end
    
        for i = 1, #userColorSequences do
            table.insert(combinedPalette, userColorSequences[i])
        end

        return combinedPalette
    end

    for keyCode, delta in pairs(KEY_CODE_DELTAS) do
        local repeater = RepeatingCallback.new(function()
            local selected = self.state.selected
            if (not selected) then return end

            local nextSelected
            local searchTerm = self.state.searchTerm

            if (searchTerm) then
                local colorSequences = self.combinePaletteItems()
                local paletteColorsSlice = {}
                local paletteColorsSliceToWholeMap = {} --> slice index to palette index

                for i = 1, #colorSequences do
                    local color = colorSequences[i]
                    local include = true
            
                    if (searchTerm) then
                        local start = string.find(string.lower(color.name), searchTerm)
            
                        include = start and true or false
                    end
            
                    if (include) then
                        paletteColorsSlice[i] = color
                    end
                end

                for paletteColorIndex in pairs(paletteColorsSlice) do 
                    table.insert(paletteColorsSliceToWholeMap, paletteColorIndex)
                end
        
                table.sort(paletteColorsSliceToWholeMap)
        
                local sliceIndex = table.find(paletteColorsSliceToWholeMap, selected)
                if (not sliceIndex) then return end

                nextSelected = paletteColorsSliceToWholeMap[sliceIndex + delta]
                if (not nextSelected) then return end
            else
                nextSelected = selected + delta
            end

            if ((nextSelected < 1) or (nextSelected > (numBuiltInSequences + #self.props.colorSequences))) then return end

            self:setState({
                selected = nextSelected
            })
        end, 0.25, 0.1)

        self.keyInputRepeaters[keyCode] = repeater
    end

    self:setState({
        searchDisplayText = "",
    })
end

ColorSequencePalette.shouldUpdate = function(self, nextProps, nextState)
    local propsDiff = shallowCompare(self.props, nextProps)
    local stateDiff = shallowCompare(self.state, nextState)

    if (#stateDiff > 0) then return true end

    if ((#propsDiff == 1) and (propsDiff[1] ~= "palettes")) then
        -- props.lastPaletteModification will tell us if the palettes changed without having to compare them
        return true
    elseif (#propsDiff > 1) then
        return true
    end

    return false
end

ColorSequencePalette.willUnmount = function(self)
    for _, repeater in pairs(self.keyInputRepeaters) do
        repeater:destroy()
    end

    self.keyInputRepeaters = nil
end

ColorSequencePalette.render = function(self)
    local theme = self.props.theme
    local selected = self.state.selected

    local colorSequences = self.combinePaletteItems()
    local listElements = {}

    local searchTerm = self.state.searchTerm
    local paletteColorsSlice = {}
    local paletteColorsSliceArray = {}
    local paletteColorsSliceToWholeMap = {} --> slice index to palette index
    local paletteColorsWholeToSliceMap = {} --> palette index to slice index

    for i = 1, #colorSequences do
        local color = colorSequences[i]
        local include = true

        if (searchTerm) then
            local start = string.find(string.lower(color.name), searchTerm)

            include = start and true or false
        end

        if (include) then
            paletteColorsSlice[i] = color
        end
    end

    if (searchTerm) then
        for paletteColorIndex in pairs(paletteColorsSlice) do 
            table.insert(paletteColorsSliceToWholeMap, paletteColorIndex)
        end

        table.sort(paletteColorsSliceToWholeMap)

        for sliceColorIndex, paletteColorIndex in pairs(paletteColorsSliceToWholeMap) do
            paletteColorsWholeToSliceMap[paletteColorIndex] = sliceColorIndex
        end

        for i = 1, #paletteColorsSliceToWholeMap do
            paletteColorsSliceArray[i] = paletteColorsSlice[paletteColorsSliceToWholeMap[i]]
        end
    end

    for i, color in pairs(searchTerm and paletteColorsSliceArray or paletteColorsSlice) do
        local wholeIndex = searchTerm and paletteColorsSliceToWholeMap[i] or i
        local isReadOnly = (wholeIndex <= numBuiltInSequences)
        local isSelected = (selected == wholeIndex)
        local realIndex = wholeIndex - numBuiltInSequences

        local listItemHeight

        if (isSelected) then
            listItemHeight = (Style.StandardButtonSize * (isReadOnly and 1 or 2)) + (Style.MinorElementPadding * (isReadOnly and 2 or 3))
        else
            listItemHeight = (Style.StandardButtonSize * 1) + (Style.MinorElementPadding * 2)
        end

        table.insert(listElements, Roact.createElement("TextButton", {
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, listItemHeight),

            Text = "",
            TextTransparency = 1,

            BackgroundColor3 = isSelected and
                theme:GetColor(Enum.StudioStyleGuideColor.TableItem, Enum.StudioStyleGuideModifier.Selected)
            or theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame),

            [Roact.Event.MouseEnter] = function(obj)
                if (isSelected) then return end

                obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.TableItem, Enum.StudioStyleGuideModifier.Hover)
            end,

            [Roact.Event.MouseLeave] = function(obj)
                if (isSelected) then return end

                obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)
            end,

            [Roact.Event.Activated] = function()
                if (isSelected) then return end

                self:setState({
                    selected = wholeIndex
                })
            end
        }, {
            UIPadding = Roact.createElement(StandardUIPadding, {Style.MinorElementPadding}),

            ColorIndicator = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, Style.ColorSequencePreviewWidth, 0, Style.StandardButtonSize),

                displayType = "colorSequence",
                color = color.color,

                onActivated = function()
                    self.props.setCurrentColorSequence(color.color)

                    self:setState({
                        selected = wholeIndex
                    })
                end,
            }),

            ColorName = isSelected and
                Roact.createElement(TextInput, {
                    AnchorPoint = Vector2.new(0, 0),
                    Position = UDim2.new(0, Style.ColorSequencePreviewWidth + Style.MinorElementPadding, 0, 0),
                    Size = UDim2.new(1, -(Style.ColorSequencePreviewWidth + Style.MinorElementPadding), 0, Style.StandardButtonSize),

                    Text = color.name,
                    TextXAlignment = Enum.TextXAlignment.Left,

                    onSubmit = function(newText)
                        self.props.changePaletteColorName(realIndex, newText)
                    end,
                    
                    disabled = isReadOnly,
                })
            or
                Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0, 0),
                    Position = UDim2.new(0, Style.ColorSequencePreviewWidth + Style.SpaciousElementPadding + 1, 0, 0),
                    Size = UDim2.new(1, -(Style.ColorSequencePreviewWidth + Style.SpaciousElementPadding + 1), 1, 0),
                    Text = color.name,

                    TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText, isSelected and Enum.StudioStyleGuideModifier.Selected or nil),
                }),

            ColorActions = (isSelected and (not isReadOnly)) and
                Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, Style.ColorSequencePreviewWidth + Style.MinorElementPadding, 1, 0),
                    Size = UDim2.new(0, (Style.StandardButtonSize * 3) + (Style.MinorElementPadding * 2), 0, Style.StandardButtonSize),

                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, {
                    UIListLayout = Roact.createElement(StandardUIListLayout, {
                        Padding = UDim.new(0, Style.MinorElementPadding),
                        
                        preset = 2,
                    }),

                    RemoveColorButton = (isSelected and (not isReadOnly)) and
                        Roact.createElement(Button, {
                            LayoutOrder = 1,
            
                            displayType = "image",
                            image = Style.DeleteImage,

                            onActivated = function()
                                self:setState({
                                    selected = Roact.None,
                                })

                                self.props.removePaletteColor(realIndex)
                            end,
                        })
                    or nil,
        
                    MoveUpButton = (isSelected and (not isReadOnly)) and
                        Roact.createElement(Button, {
                            LayoutOrder = 2,
            
                            displayType = "image",
                            image = Style.PaletteColorMoveUpImage,
                            disabled = (selected == (numBuiltInSequences + 1)),
                                    
                            onActivated = function()
                                self:setState({
                                    selected = selected - 1,
                                })

                                self.props.changePaletteColorPosition(realIndex, -1)
                            end,
                        })
                    or nil,
        
                    MoveDownButton = (isSelected and (not isReadOnly)) and
                        Roact.createElement(Button, {
                            LayoutOrder = 3,
            
                            displayType = "image",
                            image = Style.PaletteColorMoveDownImage,
                            disabled = (selected == #colorSequences),

                            onActivated = function()
                                self:setState({
                                    selected = selected + 1,
                                })

                                self.props.changePaletteColorPosition(realIndex, 1)
                            end,
                        })
                    or nil,
                })
            or nil,
        }))
    end

    listElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateListLength(obj.AbsoluteContentSize.Y)
        end,

        preset = 1,
    })

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame),
    }, {
        UIPadding = Roact.createElement(StandardUIPadding, {Style.PagePadding}),

        SearchBar = Roact.createElement(TextInput, {
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, -(Style.StandardButtonSize + Style.MinorElementPadding), 0, Style.StandardInputHeight),

            PlaceholderText = "Search",
            Text = self.state.searchDisplayText,

            onTextChanged = function(newText)
                local newSearchTerm = string.lower(string.gsub(newText, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%0"))

                local selectedColor = colorSequences[selected]
                local resetSelected

                if (selectedColor) then
                    local start = string.find(string.lower(selectedColor.name), newSearchTerm)
                    
                    resetSelected = (not start) and true or false
                else
                    resetSelected = false
                end

                self:setState({
                    selected = resetSelected and Roact.None or nil,

                    searchDisplayText = newText,
                    searchTerm = (newSearchTerm ~= "") and newSearchTerm or Roact.None
                })
            end,

            canSubmitEmptyString = true,
        }),

        AddColorButton = Roact.createElement(Button, {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),

            displayType = "image",
            image = Style.AddImage,

            onActivated = function()
                self:setState({
                    selected = #colorSequences + 1,

                    searchDisplayText = "",
                    searchTerm = Roact.None,
                })

                self.props.addPaletteColor(self.props.getCurrentColorSequence())
            end,
        }),

        Sequences = Roact.createElement(StandardScrollingFrame, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, -2, 1, -(Style.StandardInputHeight + Style.MinorElementPadding + 2)),
    
            CanvasSize = self.listLength:map(function(listLength)
                return UDim2.new(0, 0, 0, listLength)
            end),
    
            [Roact.Event.InputBegan] = function(_, input)
                if (input.UserInputType ~= Enum.UserInputType.Keyboard) then return end
        
                local inputRepeater = self.keyInputRepeaters[input.KeyCode]
                if (not inputRepeater) then return end
        
                for _, repeater in pairs(self.keyInputRepeaters) do
                    repeater:stop()
                end
        
                inputRepeater:start()
            end,
    
            [Roact.Event.InputEnded] = function(_, input)
                if (input.UserInputType ~= Enum.UserInputType.Keyboard) then return end
    
                local inputRepeater = self.keyInputRepeaters[input.KeyCode]
                if (not inputRepeater) then return end
    
                inputRepeater:stop()
            end,

            useMainBackgroundColor = true,
        }, listElements)
    })
end

---

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,

        colorSequences = state.colorSequenceEditor.palette,
        lastPaletteModification = state.colorSequenceEditor.lastPaletteModification,
    }
end, function(dispatch)
    return {
        addPaletteColor = function(color)
            dispatch({
                type = PluginEnums.StoreActionType.ColorSequenceEditor_AddPaletteColor,
                color = color,
            })
        end,

        removePaletteColor = function(index)
            dispatch({
                type = PluginEnums.StoreActionType.ColorSequenceEditor_RemovePaletteColor,
                index = index,
            })
        end,

        changePaletteColorName = function(index, newColorName)
            dispatch({
                type = PluginEnums.StoreActionType.ColorSequenceEditor_ChangePaletteColorName,
                index = index,
                newName = newColorName
            })
        end,

        changePaletteColorPosition = function(index, positionOffset)
            dispatch({
                type = PluginEnums.StoreActionType.ColorSequenceEditor_ChangePaletteColorPosition,
                index = index,
                offset = positionOffset,
            })
        end
    }
end)(ColorSequencePalette)