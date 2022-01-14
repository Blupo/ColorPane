local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local Style = require(PluginModules:FindFirstChild("Style"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local Color = require(includes:FindFirstChild("Color")).Color
local BuiltInPalettes = require(includes:FindFirstChild("BuiltInPalettes"))
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local TextInput = require(Components:FindFirstChild("TextInput"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardTextLabel = StandardComponents.TextLabel
local StandardUIListLayout = StandardComponents.UIListLayout

local WebColorsPalette = BuiltInPalettes.WebColors

---

local webColors = Util.typeColorPalette(WebColorsPalette, "Color").colors

local parseComponents = function(componentString, numComponents)
    local pattern = string.rep("(.+), ?", numComponents - 1) .. "(.+)"
    local components = {string.match(componentString, pattern)}

    for i = 1, #components do
        if (not tonumber(components[i])) then
            components[i] = nil
        end
    end

    return table.unpack(components)
end

local infoComponents = {
    {
        name = "RGB",

        getComponentString = function(color)
            local r, g, b = color:toRGB()

            return string.format("%d, %d, %d", r, g, b)
        end,

        getColor = function(componentString)
            local r, g, b = parseComponents(componentString, 3)
            r, g, b = tonumber(r), tonumber(g), tonumber(b)
            if (not (r and g and b)) then return end

            return Color.fromRGB(r, g, b)
        end
    },

    {
        name = "CMYK",

        getComponentString = function(color)
            local c, m, y, k = color:toCMYK()
            c, m, y, k = math.floor(c * 100), math.floor(m * 100), math.floor(y * 100), math.floor(k * 100)

            return string.format("%d, %d, %d, %d", c, m, y, k)
        end,

        getColor = function(componentString)
            local c, m, y, k = parseComponents(componentString, 4)
            c, m, y, k = tonumber(c), tonumber(m), tonumber(y), tonumber(k)
            if (not (c and m and y and k)) then return end

            return Color.fromCMYK(c / 100, m / 100, y / 100, k / 100)
        end
    },

    {
        name = "HSB",

        getComponentString = function(color)
            local h, s, b = color:toHSB()
            h = (h ~= h) and 0 or h
            s, b = math.floor(s * 100), math.floor(b * 100)

            return string.format("%d, %d, %d", h, s, b)
        end,

        getColor = function(componentString)
            local h, s, b = parseComponents(componentString, 3)
            h, s, b = tonumber(h), tonumber(s), tonumber(b)
            if (not (h and s and b)) then return end

            return Color.fromHSB(h, s / 100, b / 100)
        end
    },

    {
        name = "HSL",

        getComponentString = function(color)
            local h, s, l = color:toHSL()
            h = (h ~= h) and 0 or h
            s, l = math.floor(s * 100), math.floor(l * 100)

            return string.format("%d, %d, %d", h, s, l)
        end,

        getColor = function(componentString)
            local h, s, l = parseComponents(componentString, 3)
            h, s, l = tonumber(h), tonumber(s), tonumber(l)
            if (not (h and s and l)) then return end

            return Color.fromHSL(h, s / 100, l / 100)
        end
    },

    {
        name = "Hex",

        getComponentString = function(color)
            return string.upper(color:toHex())
        end,

        getColor = Color.fromHex
    },

    {
        name = "Web",

        getComponentString = function(color)
            for i = 1, #webColors do
                local webColor = webColors[i]

                if (webColor.color:toHex() == color:toHex()) then
                    return table.concat(webColor.keywords, ", ")
                end
            end

            return "n/a"
        end,

        getColor = function(componentString)
            componentString = string.lower(componentString)

            for i = 1, #webColors do
                local webColor = webColors[i]

                if (table.find(webColor.keywords, componentString)) then
                    return webColor.color
                end
            end
        end
    }
}

---

--[[
    store props

        color: Color
        setColor: (Color) -> nil
]]

local ColorInfo = Roact.PureComponent:extend("ColorInfo")

ColorInfo.render = function(self)
    local color = self.props.color

    local pageElement = {}

    for i = 1, #infoComponents do
        local component = infoComponents[i]

        table.insert(pageElement, Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, Style.StandardButtonSize),
            LayoutOrder = i,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            ComponentLabel = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(0, 30, 1, 0),
                Text = component.name,
            }),

            ComponentInput = Roact.createElement(TextInput, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(1, -(30 + Style.SpaciousElementPadding), 1, 0),
                Text = component.getComponentString(color),

                isTextAValidValue = function(text)
                    return (component.getColor(text) and true or false)
                end,

                onSubmit = function(newText)
                    self.props.setColor(component.getColor(newText))
                end,

                selectTextOnFocus = (component.name == "Hex"),
            })
        }))
    end

    pageElement.UIListLayout = Roact.createElement(StandardUIListLayout, {
        Padding = UDim.new(0, Style.SpaciousElementPadding),

        preset = 1,
    })

    return Roact.createFragment(pageElement)
end

return RoactRodux.connect(function(state)
    return {
        color = state.colorEditor.color,
    }
end, function(dispatch)
    return {
        setColor = function(newColor)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_SetColor,
                color = newColor
            })
        end
    }
end)(ColorInfo)