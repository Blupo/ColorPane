local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local ColorGrids = require(Components:FindFirstChild("ColorGrids"))
local TextInput = require(Components:FindFirstChild("TextInput"))

---

local DOUBLE_CLICK_TIME = 0.5

---

local Palette = Roact.PureComponent:extend("Palette")

Palette.init = function(self)
    self.layout = Roact.createRef()

    self:setState({
        searchDisplayText = "",

        lastSelectTime = os.clock(),
    })
end

Palette.render = function(self)
    local isReadOnly = self.props.readOnly
    local palette = self.props.palette
    local searchTerm = self.state.searchTerm
    local selectedColor = palette.colors[self.state.selectedColorIndex]

    local paletteColorsSlice = {}
    local paletteColorsSliceArray = {}
    local paletteColorsSliceToWholeMap = {} --> slice index to palette index
    local paletteColorsWholeToSliceMap = {} --> palette index to slice index

    for i = 1, #palette.colors do
        local color = palette.colors[i]
        local include = true

        if (searchTerm) then
            local start = string.find(string.lower(color.name), searchTerm)

            include = start and true or false
        end

        if (include) then
            paletteColorsSlice[i] = color.color
        end
    end

    if (searchTerm) then
        for paletteIndex in pairs(paletteColorsSlice) do 
            paletteColorsSliceToWholeMap[#paletteColorsSliceToWholeMap + 1] = paletteIndex
        end

        table.sort(paletteColorsSliceToWholeMap)

        for sliceIndex, paletteIndex in pairs(paletteColorsSliceToWholeMap) do
            paletteColorsWholeToSliceMap[paletteIndex] = sliceIndex
        end

        for i = 1, #paletteColorsSliceToWholeMap do
            paletteColorsSliceArray[i] = paletteColorsSlice[paletteColorsSliceToWholeMap[i]]
        end
    end

    return Roact.createFragment({
        Tools = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, Style.StandardButtonSize),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            SearchBar = Roact.createElement(TextInput, {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(1, (not isReadOnly) and -(Style.StandardButtonSize + Style.MinorElementPadding) or 0, 1, 0),

                PlaceholderText = "Search",
                Text = self.state.searchDisplayText,

                canClear = true,
                onTextChanged = function(newText)
                    local text = string.match(newText, "^%s*(.-)%s*$")

                    self:setState({
                        selectedColorIndex = Roact.None,

                        searchDisplayText = text,
                        searchTerm = (text ~= "") and string.lower(string.gsub(text, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%0")) or Roact.None
                    })
                end
            }),

            AddColorButton = (not isReadOnly) and
                Roact.createElement(Button, {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),

                    displayType = "image",
                    image = Style.PaletteAddColorImage,

                    onActivated = function()
                        self.props.addCurrentColorToPalette(palette.name)
                    end
                })
            or nil,
        }),

        Colors = Roact.createElement(ColorGrids, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, Style.StandardButtonSize + Style.MinorElementPadding + 1),
            Size = UDim2.new(1, -2, 1, -(Style.StandardButtonSize * 3) - (Style.MinorElementPadding * 2) - Style.MajorElementPadding - 2),

            named = false,
            colorLists = {searchTerm and paletteColorsSliceArray or paletteColorsSlice},
            selected = searchTerm and paletteColorsWholeToSliceMap[self.state.selectedColorIndex] or self.state.selectedColorIndex,

            onColorSelected = function(index)
                index = searchTerm and paletteColorsSliceToWholeMap[index] or index

                if (self.state.selectedColorIndex == index) then
                    if ((os.clock() - self.state.lastSelectTime) <= DOUBLE_CLICK_TIME) then
                        self.props.setColor(paletteColorsSlice[index])
                    else
                        self:setState({
                            lastSelectTime = os.clock(),
                        })
                    end
                else
                    self:setState({
                        selectedColorIndex = index,
                        lastSelectTime = os.clock(),
                    })
                end
            end
        }),

        ColorInfo = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, (Style.StandardButtonSize * 2) + Style.MinorElementPadding),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            NameInput = Roact.createElement(TextInput, {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, Style.StandardButtonSize),
                Text = selectedColor and selectedColor.name or "",
                PlaceholderText = "Select a color",

                disabled = (isReadOnly or (not selectedColor)),
                onTextChanged = function(newText)
                    self.props.changePaletteColorName(palette.name, selectedColor.name, newText)
                end,
            }),

            SetColorButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, Style.DialogButtonWidth, 0, Style.StandardButtonSize),
                
                displayType = "text",
                text = "Set Color",
                disabled = (not selectedColor),

                onActivated = function()
                    self.props.setColor(selectedColor.color)
                end
            }),

            ColorActions = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.new(0, (Style.StandardButtonSize * 3) + (Style.MinorElementPadding * 2), 0, Style.StandardButtonSize),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                UIListLayout = Roact.createElement("UIListLayout", {
                    Padding = UDim.new(0, Style.MinorElementPadding),
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                }),

                RemoveColorButton = Roact.createElement(Button, {
                    LayoutOrder = 0,
    
                    displayType = "image",
                    image = Style.PaletteRemoveColorImage,
    
                    disabled = (isReadOnly or (not selectedColor)),
                    onActivated = function()
                        self:setState({
                            selectedColorIndex = Roact.None,
                        })
                        
                        self.props.removePaletteColor(palette.name, selectedColor.name)
                    end,
                }),
    
                MoveUpButton = Roact.createElement(Button, {
                    LayoutOrder = 1,
    
                    displayType = "image",
                    image = Style.PaletteColorMoveUpImage,
    
                    disabled = ((not selectedColor) or isReadOnly or (self.state.selectedColorIndex == 1)),
                    onActivated = function()
                        self:setState(function(prevState)
                            return {
                                selectedColorIndex = prevState.selectedColorIndex - 1
                            }
                        end)
                        
                        self.props.changePaletteColorPosition(palette.name, selectedColor.name, -1)
                    end,
                }),
    
                MoveDownButton = Roact.createElement(Button, {
                    LayoutOrder = 2,
    
                    displayType = "image",
                    image = Style.PaletteColorMoveDownImage,
    
                    disabled = ((not selectedColor) or isReadOnly or (self.state.selectedColorIndex == #palette.colors)),
                    onActivated = function()
                        self:setState(function(prevState)
                            return {
                                selectedColorIndex = prevState.selectedColorIndex + 1
                            }
                        end)
    
                        self.props.changePaletteColorPosition(palette.name, selectedColor.name, 1)
                    end,
                }),
            }),
        })
    })
end

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,
    }
end, function(dispatch)
    return {
        setColor = function(newColor)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_SetColor,
                color = newColor
            })
        end,

        addPaletteColor = function(paletteName, newColor, newColorName)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_AddPaletteColor,
                palette = paletteName,
                color = newColor,
                name = newColorName,
            })
        end,

        addCurrentColorToPalette = function(paletteName, newColorName)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_AddCurrentColorToPalette,
                palette = paletteName,
                name = newColorName,
            })
        end,

        removePaletteColor = function(paletteName, colorName)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_RemovePaletteColor,
                palette = paletteName,
                name = colorName
            })
        end,

        changePaletteColorName = function(paletteName, oldColorName, newColorName)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_ChangePaletteColorName,
                palette = paletteName,
                name = oldColorName,
                newName = newColorName
            })
        end,

        changePaletteColorPosition = function(paletteName, colorName, positionOffset)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_ChangePaletteColorPosition,
                palette = paletteName,
                name = colorName,
                offset = positionOffset,
            })
        end
    }
end)(Palette)