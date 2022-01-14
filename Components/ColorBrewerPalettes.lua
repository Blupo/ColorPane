local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local Style = require(PluginModules:FindFirstChild("Style"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local BuiltInPalettes = require(includes:FindFirstChild("BuiltInPalettes"))
local Color = require(includes:FindFirstChild("Color")).Color
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local ButtonBar = require(Components:FindFirstChild("ButtonBar"))
local ColorGrids = require(Components:FindFirstChild("ColorGrids"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardTextLabel = StandardComponents.TextLabel

local ColorBrewer = BuiltInPalettes.ColorBrewer

---

local colorSchemes = Util.table.deepCopy(ColorBrewer)
local buttonBarHeight = Style.StandardButtonSize + Style.StandardTextSize + Style.MinorElementPadding

local dataClasses = {
    {
        name = "Sequential",
        image = Style.CBDataTypeSequentialImage,
        order = 1,
    },

    {
        name = "Diverging",
        image = Style.CBDataTypeDivergingImage,
        order = 2,
    },

    {
        name = "Qualitative",
        image = Style.CBDataTypeQualitativeImage,
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

for _, scheme in pairs(colorSchemes) do
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

    for schemeName, scheme in pairs(colorSchemes) do
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
            title = "Data Type",
            selected = self.props.dataClass,
            buttons = dataClasses,

            onButtonActivated = self.props.setDataClass
        }),

        NumDataClassesSelector = Roact.createElement(ButtonBar, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, buttonBarHeight + Style.MinorElementPadding),
            Size = UDim2.new(1, 0, 0, buttonBarHeight),

            displayType = "text",
            title = "Number of Data Classes",
            selected = self.props.numDataClasses - 2,
            buttons = numDataClassesButtons,

            onButtonActivated = function(i)
                self.props.setNumDataClasses(i + 2)
            end
        }),

        InfoText = (numIncludedColorSchemes == 0) and
            Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, 0),
                Size = UDim2.new(1, -2, 1, -((buttonBarHeight * 2) + Style.MajorElementPadding)),

                Text = "There are no schemes that satisfy this criteria",
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
            })
        or nil,

        Schemes = Roact.createElement(ColorGrids, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, -2, 1, -((buttonBarHeight * 2) + Style.MajorElementPadding)),

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
                type = PluginEnums.StoreActionType.ColorEditor_SetColor,
                color = newColor
            })
        end,

        setDataClass = function(dataClass)
            dispatch({
                type = PluginEnums.StoreActionType.UpdateSessionData,
                slice = {
                    cbDataClass = dataClass
                }
            })
        end,

        setNumDataClasses = function(numDataClasses)
            dispatch({
                type = PluginEnums.StoreActionType.UpdateSessionData,
                slice = {
                    cbNumDataClasses = numDataClasses
                }
            })
        end,
    }
end)(ColorBrewerPalettes)