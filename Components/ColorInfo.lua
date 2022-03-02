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
local StandardScrollingFrame = StandardComponents.ScrollingFrame
local StandardTextLabel = StandardComponents.TextLabel
local StandardUIListLayout = StandardComponents.UIListLayout
local StandardUIPadding = StandardComponents.UIPadding

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
        name = "HWB",

        getComponentString = function(color)
            local h, w, b = color:toHWB()
            h = (h ~= h) and 0 or h
            w, b = math.floor(w * 100), math.floor(b * 100)

            return string.format("%d, %d, %d", h, w, b)
        end,

        getColor = function(componentString)
            local h, w, b = parseComponents(componentString, 3)
            h, w, b = tonumber(h), tonumber(w), tonumber(b)
            if (not (h and w and b)) then return end

            return Color.fromHWB(h, w / 100, b / 100)
        end,
    },

    {
        name = "Lab",

        getComponentString = function(color)
            local l, a, b = color:toLab()
            l, a, b = l * 100, a * 100, b * 100

            return string.format("%.03f, %.03f, %.03f", l, a, b)
        end,

        getColor = function(componentString)
            local l, a, b = parseComponents(componentString, 3)
            l, a, b = tonumber(l), tonumber(a), tonumber(b)
            if (not (l and a and b)) then return end

            return Color.fromLab(l / 100, a / 100, b / 100)
        end
    },

    {
        name = "Luv",

        getComponentString = function(color)
            local l, u, v = color:toLuv()
            l, u, v = l * 100, u * 100, v * 100

            return string.format("%.03f, %.03f, %.03f", l, u, v)
        end,

        getColor = function(componentString)
            local l, u, v = parseComponents(componentString, 3)
            l, u, v = tonumber(l), tonumber(u), tonumber(v)
            if (not (l and u and v)) then return end

            return Color.fromLuv(l / 100, u / 100, v / 100)
        end
    },

    {
        name = "LCh(ab)",

        getComponentString = function(color)
            local l, c, h = color:toLChab()
            h = (h ~= h) and 0 or h
            l, c = l * 100, c * 100

            return string.format("%.03f, %.03f, %.03f", l, c, h)
        end,

        getColor = function(componentString)
            local l, c, h = parseComponents(componentString, 3)
            l, c, h = tonumber(l), tonumber(c), tonumber(h)
            if (not (l and c and h)) then return end

            return Color.fromLChab(l / 100, c / 100, h)
        end
    },

    {
        name = "LCh(uv)",

        getComponentString = function(color)
            local l, c, h = color:toLChuv()
            h = (h ~= h) and 0 or h
            l, c = l * 100, c * 100

            return string.format("%.03f, %.03f, %.03f", l, c, h)
        end,

        getColor = function(componentString)
            local l, c, h = parseComponents(componentString, 3)
            l, c, h = tonumber(l), tonumber(c), tonumber(h)
            if (not (l and c and h)) then return end

            return Color.fromLChuv(l / 100, c / 100, h)
        end
    },

    {
        name = "xyY",

        getComponentString = function(color)
            local x, y, Y = color:to("xyY")
            x, y, Y = x * 100, y * 100, Y * 100

            return string.format("%.03f, %.03f, %.03f", x, y, Y)
        end,

        getColor = function(componentString)
            local x, y, Y = parseComponents(componentString, 3)
            x, y, Y = tonumber(x), tonumber(y), tonumber(Y)
            if (not (x and y and Y)) then return end

            return Color.from("xyY", x / 100, y / 100, Y / 100)
        end,
    },

    {
        name = "XYZ",

        getComponentString = function(color)
            local x, y, z = color:toXYZ()
            x, y, z = x * 100, y * 100, z * 100

            return string.format("%.03f, %.03f, %.03f", x, y, z)
        end,

        getColor = function(componentString)
            local x, y, z = parseComponents(componentString, 3)
            x, y, z = tonumber(x), tonumber(y), tonumber(z)
            if (not (x and y and z)) then return end

            return Color.fromXYZ(x / 100, y / 100, z / 100)
        end,
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

ColorInfo.init = function(self)
    self.listLength, self.updateListLength = Roact.createBinding(0)
end

ColorInfo.render = function(self)
    local color = self.props.color
    local colorInfoElements = {}

    for i = 1, #infoComponents do
        local component = infoComponents[i]
        local name = component.name

        colorInfoElements[name] = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, Style.StandardButtonSize),
            LayoutOrder = i,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            ComponentLabel = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(0, 40, 1, 0),
                Text = name,
            }),

            ComponentInput = Roact.createElement(TextInput, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(1, -(40 + Style.SpaciousElementPadding), 1, 0),
                Text = component.getComponentString(color),

                isTextAValidValue = function(text)
                    return (component.getColor(text) and true or false)
                end,

                onSubmit = function(newText)
                    self.props.setColor(component.getColor(newText))
                end,

                selectTextOnFocus = (name == "Hex"),
            })
        })
    end

    colorInfoElements.UIPadding = Roact.createElement(StandardUIPadding, {0, 0, 0, Style.SpaciousElementPadding})

    colorInfoElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        Padding = UDim.new(0, Style.SpaciousElementPadding),

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateListLength(obj.AbsoluteContentSize.Y)
        end,

        preset = 1,
    })

    return Roact.createElement(StandardScrollingFrame, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        
        CanvasSize = self.listLength:map(function(length)
            return UDim2.new(0, 0, 0, length)
        end),
    }, colorInfoElements)
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