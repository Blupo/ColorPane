local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")

---

local root = script.Parent.Parent
local Common = root.Common

local CommonPluginModules = Common.PluginModules
local Style = require(CommonPluginModules.Style)
local Translator = require(CommonPluginModules.Translator)

local CommonIncludes = Common.Includes
local Roact = require(CommonIncludes.RoactRodux.Roact)
local RoactRodux = require(CommonIncludes.RoactRodux.RoactRodux)

local CommonComponents = Common.Components
local Button = require(CommonComponents.Button)

local StandardComponents = CommonComponents.StandardComponents
local StandardTextLabel = require(StandardComponents.TextLabel)
local StandardUIListLayout = require(StandardComponents.UIListLayout)

local PluginModules = root.PluginModules
local Util = require(PluginModules.Util)

local Components = root.Components
local Dropdown = require(Components.Dropdown)
local RadioButtonGroup = require(Components.RadioButtonGroup)

---

local exportTypes = { "ModuleScript", "StringValue" }

local uiTranslations = Translator.GenerateTranslationTable({
    "ExportScriptInjection_Warning",
    "ModuleScriptExport_Label",

    "Export_ButtonText",
    "Cancel_ButtonText",
})

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
                    name = "",
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
                Position = UDim2.new(0.5, 0, 0, Style.Constants.LargeButtonHeight + Style.Constants.SpaciousElementPadding),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                
                Size = UDim2.new(
                    1, 0, 1, -(
                        Style.Constants.LargeButtonHeight +
                        Style.Constants.StandardButtonHeight +
                        Style.Constants.SpaciousElementPadding * 2
                    )
                ),
            }, {
                UIListLayout = Roact.createElement(StandardUIListLayout, {
                    Padding = UDim.new(0, Style.Constants.SpaciousElementPadding),

                    preset = 1,
                }),

                ExportType = Roact.createElement(RadioButtonGroup, {
                    Size = UDim2.new(1, 0, 0, (Style.Constants.StandardInputHeight * 2) + Style.Constants.MinorElementPadding),
                    LayoutOrder = 2,

                    selected = table.find(exportTypes, exportType),
                    options = exportTypes,

                    onSelected = function(i)
                        self:setState({
                            exportType = exportTypes[i]
                        })
                    end,
                }),

                ScriptInjectionWarning = (exportType == "ModuleScript") and
                    Roact.createElement(StandardTextLabel, {
                        Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize * 2),
                        LayoutOrder = 3,

                        Text = uiTranslations["ExportScriptInjection_Warning"],
                        TextWrapped = true,

                        TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.WarningText),
                    })
                or nil,

                ExportLocation = paletteName and
                    Roact.createElement(StandardTextLabel, {
                        Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize * 2),
                        LayoutOrder = 4,
                        Text = Translator.FormatByKey("ExportDestination_Message", { paletteName }),
                    })
                or nil,
            })
        or nil,

        Buttons = (not dropdownExpanded) and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, 0, 1, 0),
                Size = UDim2.new(0, (Style.Constants.DialogButtonWidth * 2) + Style.Constants.SpaciousElementPadding, 0, Style.Constants.StandardButtonHeight),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                UIListLayout = Roact.createElement(StandardUIListLayout, {
                    Padding = UDim.new(0, Style.Constants.SpaciousElementPadding),
                    
                    preset = 2,
                }),

                CancelButton = Roact.createElement(Button, {
                    Size = UDim2.new(0, Style.Constants.DialogButtonWidth, 0, Style.Constants.StandardButtonHeight),
                    LayoutOrder = 0,

                    displayType = "text",
                    text = uiTranslations["Cancel_ButtonText"],

                    backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton),
                    borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                    hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton, Enum.StudioStyleGuideModifier.Hover),
                    displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonText),

                    onActivated = function()
                        self.props.onPromptClosed(false)
                    end
                }),

                ExportButton = Roact.createElement(Button, {
                    Size = UDim2.new(0, Style.Constants.DialogButtonWidth, 0, Style.Constants.StandardButtonHeight),
                    LayoutOrder = 1,

                    disabled = (not (paletteIndex and exportType)),
                    displayType = "text",
                    text = uiTranslations["Export_ButtonText"],

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
                            instance.Source = "-- " .. uiTranslations["ModuleScriptExport_Label"] .. "\n" ..
                                "-- " .. paletteName .. "\n" ..
                                "-- " .. os.date("%Y-%m-%dT%H:%M:%S%z") .. "\n" .. -- 
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
                                warn("[ColorPane] " .. Translator.FormatByKey("ModuleScriptExportFailure_Message", { paletteName }))
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