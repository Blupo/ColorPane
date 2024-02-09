local root = script.Parent.Parent
local Common = root.Common

local CommonPluginModules = Common.PluginModules
local Style = require(CommonPluginModules.Style)
local Translator = require(CommonPluginModules.Translator)

local CommonIncludes = Common.Includes
local Color = require(CommonIncludes.Color).Color
local Roact = require(CommonIncludes.RoactRodux.Roact)
local RoactRodux = require(CommonIncludes.RoactRodux.RoactRodux)

local CommonComponents = Common.Components
local Button = require(CommonComponents.Button)
local StandardComponents = require(CommonComponents.StandardComponents)
local TextInput = require(CommonComponents.TextInput)

local PluginModules = root.PluginModules
local PluginEnums = require(PluginModules.PluginEnums)
local Util = require(PluginModules.Util)

local Components = root.Components
local ButtonBar = require(Components.ButtonBar)
local PaletteColorGrid = require(Components.PaletteColorGrid)
local PaletteColorList = require(Components.PaletteColorList)

local StandardUIListLayout = StandardComponents.UIListLayout

---

local searchPrompt = Translator.FormatByKey("Searchbar_Prompt")

---

--[[
    props

        palette: Palette?
            OR
        paletteIndex: number?

        readOnly: boolean?

    store props

        theme: StudioTheme
        paletteLayout: number

        updatePaletteLayout: (number) -> nil
        setColor: (Color) -> nil
        addCurrentColorToPalette: (number) -> nil
        removePaletteColor: (number, number) -> nil
        changePaletteColorName: (number, number, string) -> nil
        changePaletteColorPosition: (number, number, number) -> nil
]]

local Palette = Roact.PureComponent:extend("Palette")

Palette.init = function(self)
    self:setState({
        searchDisplayText = "",

        lastSelectTime = os.clock(),
    })
end

Palette.didUpdate = function(self, prevProps)
    if (self.props.paletteIndex ~= prevProps.paletteIndex) then
        self:setState({
            selectedColorIndex = Roact.None,
        })
    end
end

Palette.render = function(self)
    local palette = self.props.palette
    local paletteIndex = self.props.paletteIndex
    local paletteLayout = self.props.paletteLayout
    local isReadOnly = self.props.readOnly or (not paletteIndex)

    local searchTerm = self.state.searchTerm
    local selectedColorIndex = self.state.selectedColorIndex
    local selectedColor = palette.colors[selectedColorIndex]

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

    return Roact.createFragment({
        Tools = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardButtonHeight),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            UIListLayout = Roact.createElement(StandardUIListLayout, {
                Padding = UDim.new(0, Style.Constants.MinorElementPadding),
                
                preset = 2,
            }),

            SearchBar = Roact.createElement(TextInput, {
                Size = UDim2.new(
                    1, -(
                        Style.Constants.StandardButtonHeight * 2 +
                        2 +
                        Style.Constants.MinorElementPadding +
                        (isReadOnly and 0 or (Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding))
                    ),
                    1, 0
                ),

                LayoutOrder = 0,
                PlaceholderText = searchPrompt,
                Text = self.state.searchDisplayText,

                onTextChanged = function(newText)
                    local newSearchTerm = string.lower(Util.escapeText(newText))
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
                end,

                canSubmitEmptyString = true,
            }),

            LayoutPicker = Roact.createElement(ButtonBar, {
                Size = UDim2.new(0, (Style.Constants.StandardButtonHeight * 2) + 2, 1, 0),
                LayoutOrder = 1,

                displayType = "image",
                selected = (paletteLayout == "grid") and 1 or 2,

                buttons = {
                    {
                        name = "grid",
                        image = Style.Images.GridViewButtonIcon,
                    },

                    {
                        name = "list",
                        image = Style.Images.ListViewButtonIcon,
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
                    image = Style.Images.AddButtonIcon,

                    onActivated = function()
                        self:setState({
                            selectedColorIndex = #palette.colors + 1,

                            searchDisplayText = "",
                            searchTerm = Roact.None,
                        })

                        self.props.addCurrentColorToPalette(paletteIndex)
                    end
                })
            or nil,
        }),

        Colors = Roact.createElement((paletteLayout == "grid") and PaletteColorGrid or PaletteColorList, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding + 1),
            Size = UDim2.new(1, -2, 1, -(Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding + 2)),

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
                
                self.props.setColor(Color.fromColor3(palette.colors[i].color))
            end,

            onColorRemoved = function()
                self:setState({
                    selectedColorIndex = Roact.None,
                })
                
                self.props.removePaletteColor(paletteIndex, selectedColorIndex)
            end,

            onColorNameChanged = function(newName)
                self.props.changePaletteColorName(paletteIndex, selectedColorIndex, newName)
            end,

            onColorMovedUp = function()
                self:setState({
                    selectedColorIndex = selectedColorIndex - 1
                })
                
                self.props.changePaletteColorPosition(paletteIndex, selectedColorIndex, -1)
            end,

            onColorMovedDown = function()
                self:setState({
                    selectedColorIndex = selectedColorIndex + 1
                })

                self.props.changePaletteColorPosition(paletteIndex, selectedColorIndex, 1)
            end,
        })
    })
end

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,
        paletteLayout = state.sessionData.paletteLayout
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

        addCurrentColorToPalette = function(paletteIndex)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_AddCurrentColorToPalette,
                paletteIndex = paletteIndex
            })
        end,

        removePaletteColor = function(paletteIndex, colorIndex)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_RemovePaletteColor,
                paletteIndex = paletteIndex,
                colorIndex = colorIndex
            })
        end,

        changePaletteColorName = function(paletteIndex, colorIndex, newName)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_ChangePaletteColorName,
                paletteIndex = paletteIndex,
                colorIndex = colorIndex,
                newName = newName
            })
        end,

        changePaletteColorPosition = function(paletteIndex, colorIndex, offset)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_ChangePaletteColorPosition,
                paletteIndex = paletteIndex,
                colorIndex = colorIndex,
                offset = offset,
            })
        end
    }
end)(Palette)