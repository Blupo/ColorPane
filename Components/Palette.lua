local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local ButtonBar = require(Components:FindFirstChild("ButtonBar"))
local PaletteColorGrid = require(Components:FindFirstChild("PaletteColorGrid"))
local PaletteColorList = require(Components:FindFirstChild("PaletteColorList"))
local TextInput = require(Components:FindFirstChild("TextInput"))

---

--[[
    props

    palette: Palette
    readOnly: boolean?
]]

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
    local paletteLayout = self.props.paletteLayout

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
            paletteColorsSlice[i] = color
        end
    end

    if (searchTerm) then
        for paletteIndex in pairs(paletteColorsSlice) do 
            table.insert(paletteColorsSliceToWholeMap, paletteIndex)
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
            UIListLayout = Roact.createElement("UIListLayout", {
                Padding = UDim.new(0, Style.MinorElementPadding),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            }),

            SearchBar = Roact.createElement(TextInput, {
                Size = UDim2.new(
                    1, -((Style.StandardButtonSize * 2) + 2 + Style.MinorElementPadding + (isReadOnly and 0 or (Style.StandardButtonSize + Style.MinorElementPadding))),
                    1, 0
                ),

                LayoutOrder = 0,
                PlaceholderText = "Search",
                Text = self.state.searchDisplayText,

                canClear = true,
                onTextChanged = function(newText)
                    local newSearchTerm = string.lower(string.gsub(newText, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%0"))
                    local resetSelected

                    if (selectedColor) then
                        local start = string.find(string.lower(selectedColor.name), newSearchTerm)
                        
                        resetSelected = (not start) and true or false
                    else
                        resetSelected = false
                    end

                    self:setState({
                        selectedColorIndex = resetSelected and Roact.None or nil,

                        searchDisplayText = newText,
                        searchTerm = (newSearchTerm ~= "") and newSearchTerm or Roact.None
                    })
                end
            }),

            LayoutPicker = Roact.createElement(ButtonBar, {
                Size = UDim2.new(0, (Style.StandardButtonSize * 2) + 2, 1, 0),
                LayoutOrder = 1,

                displayType = "image",
                selected = (paletteLayout == "grid") and 1 or 2,

                buttons = {
                    {
                        name = "grid",
                        image = Style.PaletteGridViewImage,
                    },

                    {
                        name = "list",
                        image = Style.PaletteListViewImage,
                    }
                },

                onButtonActivated = function(i)
                    self.props.updatePaletteLayout((i == 1) and "grid" or "list")
                end,
            }),

            AddColorButton = (not isReadOnly) and
                Roact.createElement(Button, {
                    LayoutOrder = 2,

                    displayType = "image",
                    image = Style.AddImage,

                    onActivated = function()
                        self.props.addCurrentColorToPalette(palette.name)
                    end
                })
            or nil,
        }),

        Colors = Roact.createElement((paletteLayout == "grid") and PaletteColorGrid or PaletteColorList, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, Style.StandardButtonSize + Style.MinorElementPadding + 1),
            Size = UDim2.new(1, -2, 1, -(Style.StandardButtonSize + Style.MinorElementPadding + 2)),

            readOnly = isReadOnly,
            colors = searchTerm and paletteColorsSliceArray or paletteColorsSlice,
            selected = searchTerm and paletteColorsWholeToSliceMap[self.state.selectedColorIndex] or self.state.selectedColorIndex,

            onColorSelected = function(i)
                self:setState({
                    selectedColorIndex = searchTerm and paletteColorsSliceToWholeMap[i] or i
                })
            end,

            onColorSet = function(i)
                i = searchTerm and paletteColorsSliceToWholeMap[i] or i
                
                self.props.setColor(palette.colors[i].color)
            end,

            onColorRemoved = function()
                self:setState({
                    selectedColorIndex = Roact.None,
                })
                
                self.props.removePaletteColor(palette.name, selectedColor.name)
            end,

            onColorNameChanged = function(newName)
                self.props.changePaletteColorName(palette.name, selectedColor.name, newName)
            end,

            onColorMovedUp = function()
                self:setState(function(prevState)
                    return {
                        selectedColorIndex = prevState.selectedColorIndex - 1
                    }
                end)
                
                self.props.changePaletteColorPosition(palette.name, selectedColor.name, -1)
            end,

            onColorMovedDown = function()
                self:setState(function(prevState)
                    return {
                        selectedColorIndex = prevState.selectedColorIndex + 1
                    }
                end)

                self.props.changePaletteColorPosition(palette.name, selectedColor.name, 1)
            end,
        })
    })
end

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,
        paletteLayout = state.sessionData.paletteLayout,
    }
end, function(dispatch)
    return {
        updatePaletteLayout = function(newLayout)
            dispatch({
                type = PluginEnums.StoreActionType.UpdateSessionData,
                slice = {
                    paletteLayout = newLayout
                }
            })
        end,

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