-- Palette page for ColorBrewer palettes

local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local Style = require(CommonModules.Style)
local Translator = require(CommonModules.Translator)

local CommonIncludes = Common.Includes
local Color = require(CommonIncludes.Color).Color
local Roact = require(CommonIncludes.RoactRodux.Roact)
local RoactRodux = require(CommonIncludes.RoactRodux.RoactRodux)

local CommonComponents = Common.Components
local StandardTextLabel = require(CommonComponents.StandardComponents.TextLabel)

local Modules = root.Modules
local ColorBrewerPalette = require(Modules.BuiltInPalettes.ColorBrewer)
local Enums = require(Modules.Enums)

local Components = root.Components
local ButtonBar = require(Components.ButtonBar)
local ColorGrids = require(Components.ColorGrids)

---

local buttonBarHeight = Style.Constants.StandardButtonHeight + Style.Constants.StandardTextSize + Style.Constants.MinorElementPadding

local uiTranslations = Translator.GenerateTranslationTable({
    "DataClass_SelectorText",
    "NumDataClass_SelectorText",
    "NoMatchingSchemes_Message",
})

local dataClasses = {
    {
        name = Translator.FormatByKey("Sequential_CBDataClass"),
        image = Style.Images.SequentialDataTypeButtonIcon,
        order = 1,
    },

    {
        name = Translator.FormatByKey("Diverging_CBDataClass"),
        image = Style.Images.DivergingDataTypeButtonIcon,
        order = 2,
    },

    {
        name = Translator.FormatByKey("Qualitative_CBDataClass"),
        image = Style.Images.QualitativeDataTypeButtonIcon,
        order = 3,
    }
}

local numDataClassesButtons = {}

---

for i = 1, 10 do
    local num = i + 2

    table.insert(numDataClassesButtons, {
        name = num,
        text = num,
    })
end

for _, scheme in pairs(ColorBrewerPalette) do
    for _, colors in pairs(scheme.colorSets) do
        for i = 1, #colors do
            local color = colors[i]

            colors[i] = Color3.fromRGB(color[1], color[2], color[3])
        end
    end
end

---

--[[
    store props
        dataClass: number
        numDataClasses: number

        setColor: (Color3) -> nil
        setDataClass: (number) -> nil
        setNumDataClasses: (number) -> nil
]]

local ColorBrewerPalettes = Roact.PureComponent:extend("ColorBrewerPalettes")

ColorBrewerPalettes.render = function(self)
    local includedColorSchemes = {}
    local numIncludedColorSchemes = 0

    for schemeName, scheme in pairs(ColorBrewerPalette) do
        local colorSet = scheme.colorSets[self.props.numDataClasses]

        if ((scheme.type == dataClasses[self.props.dataClass].name) and colorSet) then
            includedColorSchemes[schemeName] = colorSet
            numIncludedColorSchemes = numIncludedColorSchemes + 1
        end
    end

    return Roact.createFragment({
        DataTypeSelector = Roact.createElement(ButtonBar, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, buttonBarHeight),

            displayType = "image",
            title = uiTranslations["DataClass_SelectorText"],
            selected = self.props.dataClass,
            buttons = dataClasses,

            onButtonActivated = self.props.setDataClass
        }),

        NumDataClassesSelector = Roact.createElement(ButtonBar, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, buttonBarHeight + Style.Constants.MinorElementPadding),
            Size = UDim2.new(1, 0, 0, buttonBarHeight),

            displayType = "text",
            title = uiTranslations["NumDataClass_SelectorText"],
            selected = self.props.numDataClasses - 2,
            buttons = numDataClassesButtons,

            onButtonActivated = function(i)
                self.props.setNumDataClasses(i + 2)
            end
        }),

        InfoText = if (numIncludedColorSchemes == 0) then
            Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, 0),
                Size = UDim2.new(1, -2, 1, -((buttonBarHeight * 2) + Style.Constants.MajorElementPadding)),

                Text = uiTranslations["NoMatchingSchemes_Message"],
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
            })
        else nil,

        Schemes = Roact.createElement(ColorGrids, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, -2, 1, -((buttonBarHeight * 2) + Style.Constants.MajorElementPadding)),

            named = true,
            colorLists = includedColorSchemes,

            onColorSelected = function(index, schemeName)
                self.props.setColor(Color.fromColor3(includedColorSchemes[schemeName][index]))
            end
        }),
    })
end

return RoactRodux.connect(function(state)
    local sessionData = state.sessionData

    return {
        dataClass = sessionData.cbDataClass,
        numDataClasses = sessionData.cbNumDataClasses,
    }
end, function(dispatch)
    return {
        setColor = function(newColor)
            dispatch({
                type = Enums.StoreActionType.ColorEditor_SetColor,
                color = newColor
            })
        end,

        setDataClass = function(dataClass)
            dispatch({
                type = Enums.StoreActionType.UpdateSessionData,
                slice = {
                    cbDataClass = dataClass
                }
            })
        end,

        setNumDataClasses = function(numDataClasses)
            dispatch({
                type = Enums.StoreActionType.UpdateSessionData,
                slice = {
                    cbNumDataClasses = numDataClasses
                }
            })
        end,
    }
end)(ColorBrewerPalettes)