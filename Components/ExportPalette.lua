local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")

---

local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Style = require(PluginModules:FindFirstChild("Style"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local Dropdown = require(Components:FindFirstChild("Dropdown"))
local RadioButtonGroup = require(Components:FindFirstChild("RadioButtonGroup"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardTextLabel = StandardComponents.TextLabel
local StandardUIListLayout = StandardComponents.UIListLayout

---

local exportTypeKeys = {
    [1] = "ModuleScript",
    [2] = "StringValue",
}

---

--[[
    props

        paletteIndex: number?
        onPromptClosed: (boolean) -> nil

    store props

        theme: StudioTheme
        palettes: array<Palette>
]]

local ExportPalette = Roact.PureComponent:extend("ExportPalette")

ExportPalette.init = function(self, initProps)
    self:setState({
        dropdownExpanded = false,
        paletteIndex = initProps.paletteIndex or 1,
    })
end

ExportPalette.render = function(self)
    local theme = self.props.theme
    local palettes = self.props.palettes

    local dropdownExpanded = self.state.dropdownExpanded
    local exportType = self.state.exportType

    local paletteIndex = self.state.paletteIndex
    local paletteName = paletteIndex and palettes[paletteIndex].name or nil

    local nameItems = {}

    for i = 1, #palettes do
        table.insert(nameItems, {
            name = palettes[i].name
        })
    end

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        Dropdown = Roact.createElement(Dropdown, {
            selectedItem = {1, self.state.paletteIndex},

            itemSections = {
                {
                    name = "Palettes",
                    items = nameItems,
                }
            },

            onExpandedStateToggle = function(expanded)
                self:setState({
                    dropdownExpanded = expanded
                })
            end,

            onItemChanged = function(_, j)
                self:setState({
                    paletteIndex = j,
                })
            end,
        }),

        Dialog = ((not dropdownExpanded) and paletteIndex) and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, 0, 1, -(Style.LargeButtonSize + Style.StandardButtonSize + (Style.SpaciousElementPadding * 2))),
                Position = UDim2.new(0.5, 0, 0, Style.LargeButtonSize + Style.SpaciousElementPadding),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                UIListLayout = Roact.createElement(StandardUIListLayout, {
                    Padding = UDim.new(0, Style.SpaciousElementPadding),

                    preset = 1,
                }),

                ExportType = Roact.createElement(RadioButtonGroup, {
                    Size = UDim2.new(1, 0, 0, (Style.StandardInputHeight * 2) + Style.MinorElementPadding),
                    LayoutOrder = 2,

                    options = { "ModuleScript", "StringValue" },

                    onSelected = function(i)
                        self:setState({
                            exportType = exportTypeKeys[i]
                        })
                    end,
                }),

                ExportLocation = paletteName and
                    Roact.createElement(StandardTextLabel, {
                        Size = UDim2.new(1, 0, 0, Style.StandardTextSize * 2),
                        LayoutOrder = 4,
                        Text = "The palette will be exported to ServerStorage as:\n" .. paletteName .. ".palette",
                    })
                or nil,
            })
        or nil,

        Buttons = (not dropdownExpanded) and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, 0, 1, 0),
                Size = UDim2.new(0, Style.DialogButtonWidth * 2 + Style.SpaciousElementPadding, 0, Style.StandardButtonSize),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                UIListLayout = Roact.createElement(StandardUIListLayout, {
                    Padding = UDim.new(0, Style.SpaciousElementPadding),
                    
                    preset = 2,
                }),

                CancelButton = Roact.createElement(Button, {
                    Size = UDim2.new(0, Style.DialogButtonWidth, 0, Style.StandardButtonSize),
                    LayoutOrder = 0,

                    displayType = "text",
                    text = "Cancel",

                    backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton),
                    borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                    hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton, Enum.StudioStyleGuideModifier.Hover),
                    displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonText),

                    onActivated = function()
                        self.props.onPromptClosed(false)
                    end
                }),

                ExportButton = Roact.createElement(Button, {
                    Size = UDim2.new(0, Style.DialogButtonWidth, 0, Style.StandardButtonSize),
                    LayoutOrder = 1,

                    disabled = (not (paletteIndex and exportType)),
                    displayType = "text",
                    text = "Export",

                    backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton),
                    borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                    hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton, Enum.StudioStyleGuideModifier.Hover),
                    displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText),

                    onActivated = function()
                        local palette = Util.table.deepCopy(palettes[paletteIndex])
                        local colors = palette.colors

                        -- convert Color3s to tables
                        for i = 1, #colors do
                            local color = colors[i].color

                            colors[i].color = {color.R, color.G, color.B}
                        end

                        local instance
                        local jsonPalette = HttpService:JSONEncode(palette)

                        if (exportType == "ModuleScript") then
                            local highestLevelStringBrackets = -1

                            for lBracket, equals, rBracket in string.gmatch(jsonPalette, "([%[%]])(=*)([%[%]])") do
                                if ((lBracket == "[") and (rBracket == "[")) or ((lBracket == "]") and (rBracket == "]")) then
                                    local numEquals = string.len(equals)

                                    if (numEquals > highestLevelStringBrackets) then
                                        highestLevelStringBrackets = numEquals
                                    end
                                end
                            end
                            
                            instance = Instance.new("ModuleScript")
                            instance.Source = "-- ColorPane Palette Export\n" ..
                                "-- " .. paletteName .. "\n" ..
                                "-- " .. os.date("%x, %H:%M:%S") .. "\n" ..
                                "\n" ..
                                "return [" .. string.rep("=", highestLevelStringBrackets + 1) .. "[" ..
                                jsonPalette ..
                                "]" .. string.rep("=", highestLevelStringBrackets + 1) .. "]"
                        elseif (exportType == "StringValue") then
                            instance = Instance.new("StringValue")
                            instance.Value = jsonPalette
                        end

                        instance.Name = paletteName .. ".palette"

                        local success = pcall(function()
                            instance.Parent = ServerStorage
                        end)
                        
                        if (not success) then
                            if (exportType == "ModuleScript") then
                                warn("[ColorPane] The palette export ModuleScript for \"" .. paletteName .."\" could not be parented to ServerStorage, most likely because script injection was denied.")
                            end
                        else
                            Selection:Set({instance})
                        end
                        
                        self.props.onPromptClosed(true)
                    end
                }),
            })
        or nil
    })
end

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,
        palettes = state.colorEditor.palettes,
    }
end)(ExportPalette)