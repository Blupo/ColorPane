local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Constants = require(PluginModules:FindFirstChild("Constants"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local RepeatingCallback = require(PluginModules:FindFirstChild("RepeatingCallback"))
local Style = require(PluginModules:FindFirstChild("Style"))
local Translator = require(PluginModules:FindFirstChild("Translator"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local ColorLib = require(includes:FindFirstChild("Color"))
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

local Color, Gradient = ColorLib.Color, ColorLib.Gradient

---

local KEY_CODE_DELTAS = {
    [Enum.KeyCode.Up] = -1,
    [Enum.KeyCode.Down] = 1,
}

local searchPrompt = Translator.FormatByKey("Searchbar_Prompt")

local builtInGradients = {
    {
        name = Translator.FormatByKey("BlackToWhite_BuiltInGradientName"),

        keypoints = {
            { Time = 0, Color = Color.new(0, 0, 0) },
            { Time = 1, Color = Color.new(1, 1, 1) }
        }
    },

    {
        name = Translator.FormatByKey("Hue_BuiltInGradientName"),
        colorSpace = "HSB",

        keypoints = {
            { Time = 0, Color = Color.fromHSB(0, 1, 1) },
            { Time = 1/6, Color = Color.fromHSB(60, 1, 1) },
            { Time = 2/6, Color = Color.fromHSB(120, 1, 1) },
            { Time = 3/6, Color = Color.fromHSB(180, 1, 1) },
            { Time = 4/6, Color = Color.fromHSB(240, 1, 1) },
            { Time = 5/6, Color = Color.fromHSB(300, 1, 1) },
            { Time = 1, Color = Color.fromHSB(360, 1, 1) }
        }
    },

    {
        name = Translator.FormatByKey("Temperature_BuiltInGradientName"),

        keypoints = {
            { Time = 0, Color = Color.fromTemperature(1000) },
            { Time = Util.inverseLerp(Constants.KELVIN_LOWER_RANGE, Constants.KELVIN_UPPER_RANGE, 2000), Color = Color.fromTemperature(2000) },
            { Time = Util.inverseLerp(Constants.KELVIN_LOWER_RANGE, Constants.KELVIN_UPPER_RANGE, 6000), Color = Color.fromTemperature(6000) },
            { Time = Util.inverseLerp(Constants.KELVIN_LOWER_RANGE, Constants.KELVIN_UPPER_RANGE, 6500), Color = Color.fromTemperature(6500) },
            { Time = Util.inverseLerp(Constants.KELVIN_LOWER_RANGE, Constants.KELVIN_UPPER_RANGE, 7000), Color = Color.fromTemperature(7000) },
            { Time = 1, Color = Color.fromTemperature(10000) },
        }
    }
}

local numBuiltInGradients = #builtInGradients

---

--[[
    props

        beforeSetGradient: () -> nil

    store props

        theme: StudioTheme

        keypoints: array<GradientKeypoint>
        colorSpace: string
        hueAdjustment: string
        precision: number

        gradients: array<array<GradientKeypoint>>

        addPaletteColor: (array<GradientKeypoint>) -> nil
        removePaletteColor: (number) -> nil
        changePaletteColorName: (number, string) -> nil
        changePaletteColorPosition: (number, number) -> nil

        setGradient: (array<GradientKeypoint>, string, string, number) -> nil
]]

local GradientPalette = Roact.PureComponent:extend("GradientPalette")

GradientPalette.init = function(self)
    self.listLength, self.updateListLength = Roact.createBinding(0)
    self.keyInputRepeaters = {}

    self.getCombinedPalette = function()
        local combinedPalette = {}
        local userGradients = self.props.gradients

        for i = 1, numBuiltInGradients do
            table.insert(combinedPalette, builtInGradients[i])
        end

        for i = 1, #userGradients do
            table.insert(combinedPalette, userGradients[i])
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
                local gradients = self.combinePaletteItems()
                local paletteColorsSlice = {}
                local paletteColorsSliceToWholeMap = {} --> slice index to palette index

                for i = 1, #gradients do
                    local color = gradients[i]
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

            if ((nextSelected < 1) or (nextSelected > (numBuiltInGradients + #self.props.gradients))) then return end

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

GradientPalette.willUnmount = function(self)
    for _, repeater in pairs(self.keyInputRepeaters) do
        repeater:destroy()
    end

    self.keyInputRepeaters = nil
end

GradientPalette.render = function(self)
    local theme = self.props.theme
    local selected = self.state.selected

    local gradients = self.getCombinedPalette()
    local listElements = {}

    local searchTerm = self.state.searchTerm
    local paletteColorsSlice = {}
    local paletteColorsSliceArray = {}
    local paletteColorsSliceToWholeMap = {} --> slice index to palette index
    local paletteColorsWholeToSliceMap = {} --> palette index to slice index

    for i = 1, #gradients do
        local color = gradients[i]
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

    for i, gradient in pairs(searchTerm and paletteColorsSliceArray or paletteColorsSlice) do
        local wholeIndex = searchTerm and paletteColorsSliceToWholeMap[i] or i
        local isReadOnly = (wholeIndex <= numBuiltInGradients)
        local isSelected = (selected == wholeIndex)
        local realIndex = wholeIndex - numBuiltInGradients

        local listItemHeight

        if (isSelected) then
            listItemHeight = (Style.Constants.StandardButtonHeight * (isReadOnly and 1 or 2)) + (Style.Constants.MinorElementPadding * (isReadOnly and 2 or 3))
        else
            listItemHeight = Style.Constants.StandardButtonHeight + (Style.Constants.MinorElementPadding * 2)
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
            UIPadding = Roact.createElement(StandardUIPadding, {Style.Constants.MinorElementPadding}),

            ColorIndicator = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, Style.Constants.ColorSequencePreviewWidth, 0, Style.Constants.StandardButtonHeight),

                displayType = "colorSequence",

                color = Gradient.new(
                    Util.generateFullKeypointList(
                        gradient.keypoints,
                        gradient.colorSpace or "RGB",
                        gradient.hueAdjustment or "Shorter",
                        gradient.precision or 0
                    )
                ):colorSequence(),

                onActivated = function()
                    self.props.beforeSetGradient()

                    self.props.setGradient(
                        Util.table.deepCopy(gradient.keypoints),
                        gradient.colorSpace or "RGB",
                        gradient.hueAdjustment or "Shorter",
                        gradient.precision or 0
                    )

                    self:setState({
                        selected = wholeIndex
                    })
                end,
            }),

            ColorName = isSelected and
                Roact.createElement(TextInput, {
                    AnchorPoint = Vector2.new(0, 0),
                    Position = UDim2.new(0, Style.Constants.ColorSequencePreviewWidth + Style.Constants.MinorElementPadding, 0, 0),
                    Size = UDim2.new(1, -(Style.Constants.ColorSequencePreviewWidth + Style.Constants.MinorElementPadding), 0, Style.Constants.StandardButtonHeight),

                    Text = gradient.name,
                    TextXAlignment = Enum.TextXAlignment.Left,

                    onSubmit = function(newText)
                        self.props.changePaletteColorName(realIndex, newText)
                    end,
                    
                    disabled = isReadOnly,
                })
            or
                Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0, 0),
                    Position = UDim2.new(0, Style.Constants.ColorSequencePreviewWidth + Style.Constants.SpaciousElementPadding + 1, 0, 0),
                    Size = UDim2.new(1, -(Style.Constants.ColorSequencePreviewWidth + Style.Constants.SpaciousElementPadding + 1), 1, 0),
                    Text = gradient.name,

                    TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText, isSelected and Enum.StudioStyleGuideModifier.Selected or nil),
                }),

            ColorActions = (isSelected and (not isReadOnly)) and
                Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, Style.Constants.ColorSequencePreviewWidth + Style.Constants.MinorElementPadding, 1, 0),
                    Size = UDim2.new(0, (Style.Constants.StandardButtonHeight * 3) + (Style.Constants.MinorElementPadding * 2), 0, Style.Constants.StandardButtonHeight),

                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, {
                    UIListLayout = Roact.createElement(StandardUIListLayout, {
                        Padding = UDim.new(0, Style.Constants.MinorElementPadding),
                        
                        preset = 2,
                    }),

                    RemoveColorButton = (isSelected and (not isReadOnly)) and
                        Roact.createElement(Button, {
                            LayoutOrder = 1,
            
                            displayType = "image",
                            image = Style.Images.DeleteButtonIcon,

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
                            image = Style.Images.MoveUpButtonIcon,
                            disabled = (selected == (numBuiltInGradients + 1)),
                                    
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
                            image = Style.Images.MoveDownButtonIcon,
                            disabled = (selected == #gradients),

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
        UIPadding = Roact.createElement(StandardUIPadding, {Style.Constants.PagePadding}),

        SearchBar = Roact.createElement(TextInput, {
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, -(Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding), 0, Style.Constants.StandardInputHeight),

            PlaceholderText = searchPrompt,
            Text = self.state.searchDisplayText,

            onTextChanged = function(newText)
                local newSearchTerm = string.lower(Util.escapeText(newText))

                local selectedColor = gradients[selected]
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
            image = Style.Images.AddButtonIcon,

            onActivated = function()
                self:setState({
                    selected = #gradients + 1,

                    searchDisplayText = "",
                    searchTerm = Roact.None,
                })

                self.props.addPaletteColor(self.props.keypoints, self.props.colorSpace, self.props.hueAdjustment, self.props.precision)
            end,
        }),

        Sequences = Roact.createElement(StandardScrollingFrame, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, -2, 1, -(Style.Constants.StandardInputHeight + Style.Constants.MinorElementPadding + 2)),
    
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

        keypoints = state.gradientEditor.keypoints,
        colorSpace = state.gradientEditor.colorSpace,
        hueAdjustment = state.gradientEditor.hueAdjustment,
        precision = state.gradientEditor.precision,

        gradients = state.gradientEditor.palette,
    }
end, function(dispatch)
    return {
        setGradient = function(keypoints, colorSpace, hueAdjustment, precision)
            dispatch({
                type = PluginEnums.StoreActionType.GradientEditor_SetGradient,

                keypoints = keypoints,
                colorSpace = colorSpace,
                hueAdjustment = hueAdjustment,
                precision = precision,
            })
        end,

        addPaletteColor = function(keypoints, colorSpace, hueAdjustment, precision)
            dispatch({
                type = PluginEnums.StoreActionType.GradientEditor_AddPaletteColor,

                keypoints = keypoints,
                colorSpace = colorSpace,
                hueAdjustment = hueAdjustment,
                precision = precision,
            })
        end,

        removePaletteColor = function(index)
            dispatch({
                type = PluginEnums.StoreActionType.GradientEditor_RemovePaletteColor,
                index = index,
            })
        end,

        changePaletteColorName = function(index, newColorName)
            dispatch({
                type = PluginEnums.StoreActionType.GradientEditor_ChangePaletteColorName,
                index = index,
                newName = newColorName
            })
        end,

        changePaletteColorPosition = function(index, positionOffset)
            dispatch({
                type = PluginEnums.StoreActionType.GradientEditor_ChangePaletteColorPosition,
                index = index,
                offset = positionOffset,
            })
        end
    }
end)(GradientPalette)