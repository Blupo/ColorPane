local root = script.Parent.Parent

local PluginModules = root.PluginModules
local PluginEnums = require(PluginModules.PluginEnums)
local Style = require(PluginModules.Style)
local Translator = require(PluginModules.Translator)
local Util = require(PluginModules.Util)

local includes = root.includes
local Color = require(includes.Color).Color
local Roact = require(includes.Roact)
local RoactRodux = require(includes.RoactRodux)

local Components = root.Components
local Button = require(Components.Button)
local ColorGrids = require(Components.ColorGrids)
local StandardComponents = require(Components.StandardComponents)

local StandardTextLabel = StandardComponents.TextLabel
local StandardUIListLayout = StandardComponents.UIListLayout

---

local uiTranslations = Translator.GenerateTranslationTable({
    "CompareTo_Label",
    "EmptySortAnchor_Indicator",
    "Sort_ButtonText",
    "Clear_ButtonText",
})

---

--[[
    store props

        currentColor: Color
        sortAnchor: Color
        colors: array<Color>

        setColor: (Color) -> nil
        setSortAnchor: (Color) -> nil
        setSortColors: (array<Color>) -> nil
]]

local ColorSorter = Roact.PureComponent:extend("ColorSorter")

ColorSorter.render = function(self)
    local currentColor = self.props.currentColor
    local sortAnchor = self.props.sortAnchor
    local colors = self.props.colors

    return Roact.createFragment({
        SortAnchor = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardButtonHeight +
                Style.Constants.StandardTextSize +
                Style.Constants.MinorElementPadding
            ),
        }, {
            Label = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),

                Text = uiTranslations["CompareTo_Label"],
            }),

            Color = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, 0),
                Size = UDim2.new(0, 60, 0, Style.Constants.StandardButtonHeight),

                displayType = sortAnchor and "color" or "text",
                text = (not sortAnchor) and uiTranslations["EmptySortAnchor_Indicator"] or nil,
                color = sortAnchor and sortAnchor:toColor3() or nil,

                onActivated = function()
                    self.props.setSortAnchor(currentColor)
                end,
            })
        }),

        ListActions = Roact.createElement("Frame",{
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize + Style.Constants.MinorElementPadding),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Size = UDim2.new(0, (
                Style.Constants.StandardButtonHeight +
                (40 * 2) +
                (Style.Constants.MinorElementPadding * 2)
            ), 0, Style.Constants.StandardButtonHeight),
        }, {
            UIListLayout = Roact.createElement(StandardUIListLayout, {
                Padding = UDim.new(0, Style.Constants.MinorElementPadding),

                preset = 2,
            }),

            ClearListButton = Roact.createElement(Button, {
                Size = UDim2.new(0, 40, 0, Style.Constants.StandardButtonHeight),
                LayoutOrder = 2,

                displayType = "text",
                text = uiTranslations["Clear_ButtonText"],
                disabled = (#colors <= 0),

                onActivated = function()
                    self.props.setSortColors({})
                end,
            }),

            SortListButton = Roact.createElement(Button, {
                Size = UDim2.new(0, 40, 0, Style.Constants.StandardButtonHeight),
                LayoutOrder = 1,

                displayType = "text",
                text = uiTranslations["Sort_ButtonText"],
                disabled = (#colors <= 1),

                onActivated = function()
                    local newColorList = Util.table.deepCopy(colors)

                    table.sort(newColorList, function(a, b)
                        return Color.fromColor3(a):deltaE(sortAnchor) < Color.fromColor3(b):deltaE(sortAnchor)
                    end)

                    self.props.setSortColors(newColorList)
                end,
            }),

            AddColorButton = Roact.createElement(Button, {
                Size = Style.UDim2.StandardButtonSize,
                LayoutOrder = 3,

                displayType = "image",
                image = Style.Images.AddButtonIcon,

                onActivated = function()
                    local newColorList = Util.table.deepCopy(colors)
                    table.insert(newColorList, currentColor:toColor3())

                    self.props.setSortColors(newColorList)
                end,
            })
        }),

        Colors = Roact.createElement(ColorGrids, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -1),
            Size = UDim2.new(1, -2, 1, -(
                Style.Constants.StandardTextSize +
                Style.Constants.StandardButtonHeight +
                Style.Constants.MinorElementPadding +
                Style.Constants.SpaciousElementPadding -
                2
            )),

            colorLists = {colors},
            named = false,

            onColorSelected = function(i)
                self.props.setColor(Color.fromColor3(colors[i]))
            end,
        })
    })
end

---

return RoactRodux.connect(function(state)
    local sessionData = state.sessionData

    return {
        currentColor = state.colorEditor.color,
        sortAnchor = sessionData.colorSorterAnchor,
        colors = sessionData.colorSorterColors,
    }
end, function(dispatch)
    return {
        setColor = function(newColor)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_SetColor,
                color = newColor
            })
        end,

        setSortAnchor = function(newColor)
            dispatch({
                type = PluginEnums.StoreActionType.UpdateSessionData,

                slice = {
                    colorSorterAnchor = newColor
                }
            })
        end,

        setSortColors = function(newColors)
            dispatch({
                type = PluginEnums.StoreActionType.UpdateSessionData,

                slice = {
                    colorSorterColors = newColors
                }
            })
        end,
    }
end)(ColorSorter)