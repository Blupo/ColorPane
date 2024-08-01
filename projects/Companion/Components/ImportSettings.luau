-- Interface for importing settings

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local StudioService = game:GetService("StudioService")

---

local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local ColorPaneUserDataDefaultValues = require(CommonModules.ColorPaneUserDataDefaultValues)
local ColorPaneUserDataValidators = require(CommonModules.ColorPaneUserDataValidators)
local Style = require(CommonModules.Style)
local Translator = require(CommonModules.Translator)

local CommonIncludes = Common.Includes
local Cryo = require(CommonIncludes.Cryo)
local Promise = require(CommonIncludes.Promise)
local Roact = require(CommonIncludes.RoactRodux.Roact)
local t = require(CommonIncludes.t)

local CommonComponents = Common.Components
local Button = require(CommonComponents.Button)
local ConnectTheme = require(CommonComponents.ConnectTheme)
local RadioButtonGroup = require(CommonComponents.RadioButtonGroup)

local StandardComponents = CommonComponents.StandardComponents
local StandardScrollingFrame = require(StandardComponents.ScrollingFrame)
local StandardTextLabel = require(StandardComponents.TextLabel)
local StandardUIListLayout = require(StandardComponents.UIListLayout)
local StandardUIPadding = require(StandardComponents.UIPadding)

local Modules = root.Modules
local CompanionUserDataDefaultValues = require(Modules.CompanionUserDataDefaultValues)
local CompanionUserDataValidators = require(Modules.CompanionUserDataValidators)
local Constants = require(Modules.Constants)

---

local importTypes = { "ModuleScript", "StringValue", "File" }

local importOptions = {
    "ModuleScript",
    "StringValue",
    Translator.FormatByKey("JSONFile_ImportType"),
}

local uiTranslations = Translator.GenerateTranslationTable({
    "JSONFile_ImportType",

    "UseSelection_ButtonText",
    "SelectAFile_ButtonText",
    "Import_ButtonText",
    "Cancel_ButtonText",

    "WaitingForImport_Message",
    "EmptySelection_Message",
    "MultipleSelections_Message",
})

local settingsTableValidator: (any) -> (boolean, string?) = t.interface({
    [Constants.COLORPANE_USERDATA_KEY] = t.interface({
        AskNameBeforePaletteCreation = t.optional(ColorPaneUserDataValidators.AskNameBeforePaletteCreation),
        SnapValue = t.optional(ColorPaneUserDataValidators.SnapValue),
        UserColorPalettes = t.optional(ColorPaneUserDataValidators.UserColorPalettes),
        UserGradientPalettes = t.optional(ColorPaneUserDataValidators.UserGradientPalettes),
    }),

    [Constants.COMPANION_USERDATA_KEY] = t.interface({
        AutoLoadColorPropertiesAPIData = t.optional(CompanionUserDataValidators.AutoLoadColorPropertiesAPIData),
        CacheColorPropertiesAPIData = t.optional(CompanionUserDataValidators.CacheColorPropertiesAPIData),
        RobloxApiDump = t.optional(CompanionUserDataValidators.RobloxApiDump),
    }),
})

local statusIcons = {
    ok = Style.Images.ResultOkIcon,
    notOk = Style.Images.ResultNotOkIcon,
    wait = Style.Images.ResultWaitingIcon,
}

local statusColorGenerators = {
    ok = function()
        return Color3.fromRGB(0, 170, 0)
    end,

    notOk = function(theme)
        return theme:GetColor(Enum.StudioStyleGuideColor.ErrorText)
    end,
}

---

--[[
    props

        onPromptClosed: ({}?) -> ()

    store props

        theme: StudioTheme
]]
local ImportSettings = Roact.PureComponent:extend("ImportSettings")

ImportSettings.init = function(self)
    self.statusIcon = Roact.createRef()
    self.listLength, self.updateListLength = Roact.createBinding(0)

    self.importSuccessHandler = function(message)
        return function(settings)
            if (settings) then
                self:setState({
                    settings = settings,
                    
                    status = "ok",
                    statusMessage = message
                })
            else
                self:setState({
                    status = Roact.None,
                    statusMessage = Roact.None,
                })
            end
        end
    end

    self.importErrorHandler = function(error)
        if (Promise.Error.is(error)) then
            error = error.error
        end

        self:setState({
            status = "notOk",
            statusMessage = error,
        })
    end
end

ImportSettings.didMount = function(self)
    self.rotator = RunService.Heartbeat:Connect(function(step)
        local statusIcon = self.statusIcon:getValue()
        if (not statusIcon) then return end

        if (self.state.status == "wait") then
            statusIcon.Rotation = (statusIcon.Rotation + (step * 60)) % 360  
        else
            statusIcon.Rotation = 0
        end
    end)
end

ImportSettings.willUnmount = function(self)
    self.rotator:Disconnect()
end

ImportSettings.render = function(self)
    local theme = self.props.theme

    local status = self.state.status
    local importType = self.state.importType
    local settings = self.state.settings
    local importPage

    if (importType == "ModuleScript") then
        importPage = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, (Style.Constants.StandardTextSize * 3) + Style.Constants.StandardButtonHeight + (Style.Constants.MinorElementPadding * 2)),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 3,
        }, {
            Instructions = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
                Position = UDim2.new(0, 0, 0, 0),
                Text = Translator.FormatByKey("SelectObject_Prompt", { "ModuleScript" }),
            }),

            ConfirmButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, Style.Constants.StandardTextSize + Style.Constants.MinorElementPadding),
                Size = UDim2.new(0, 80, 0, Style.Constants.StandardButtonHeight),
                
                displayType = "text",
                text = uiTranslations["UseSelection_ButtonText"],

                onActivated = function()
                    self:setState({
                        settings = Roact.None,
                    })

                    Promise.new(function(resolve, reject)
                        local selection = Selection:Get()

                        if (#selection > 1) then
                            reject(uiTranslations["MultipleSelections_Message"])
                            return
                        elseif (#selection < 1) then
                            reject(uiTranslations["EmptySelection_Message"])
                            return
                        end

                        local object = selection[1]

                        if (not object:IsA("ModuleScript")) then
                            reject(Translator.FormatByKey("InvalidSelection_Message", { "ModuleScript" }))
                            return
                        end

                        local newSettingsTable = require(selection[1])
                        
                        if (type(newSettingsTable) == "string") then
                            newSettingsTable = HttpService:JSONDecode(newSettingsTable)
                        end

                        local isValid, message = settingsTableValidator(newSettingsTable)

                        if (isValid) then
                            resolve(newSettingsTable)
                        else
                            reject(Translator.FormatByKey("NonConformantSettingsTable_Message", { message }))
                        end
                    end):andThen(
                        self.importSuccessHandler(Translator.FormatByKey("ValidSettingsTableImport_Message", { "ModuleScript" })),
                        self.importErrorHandler
                    )
                end,
            }),

            StatusIcon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = Style.UDim2.StandardButtonSize,
                Position = UDim2.new(0, 80 + Style.Constants.MinorElementPadding, 0, Style.Constants.StandardTextSize + Style.Constants.MinorElementPadding),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = if status then statusIcons[status] else "",

                ImageColor3 = if statusColorGenerators[status] then
                    statusColorGenerators[status](theme)
                else theme:GetColor(Enum.StudioStyleGuideColor.MainText),

                [Roact.Ref] = self.statusIcon,
            }),

            StatusText = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize * 2),
                Position = UDim2.new(0, 0, 0, Style.Constants.StandardTextSize + Style.Constants.StandardButtonHeight + (Style.Constants.MinorElementPadding * 2)),

                Text = self.state.statusMessage or uiTranslations["WaitingForImport_Message"],
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
            }),
        })
    elseif (importType == "StringValue") then
        importPage = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, (Style.Constants.StandardTextSize * 3) + Style.Constants.StandardButtonHeight + (Style.Constants.MinorElementPadding * 2)),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 3,
        }, {
            Instructions = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
                Position = UDim2.new(0, 0, 0, 0),
                Text = Translator.FormatByKey("SelectObject_Prompt", { "StringValue" }),
            }),

            ConfirmButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, Style.Constants.StandardTextSize + Style.Constants.MinorElementPadding),
                Size = UDim2.new(0, 80, 0, Style.Constants.StandardButtonHeight),
                
                displayType = "text",
                text = uiTranslations["UseSelection_ButtonText"],

                onActivated = function()
                    self:setState({
                        settings = Roact.None,
                    })

                    Promise.new(function(resolve, reject)
                        local selection = Selection:Get()

                        if (#selection > 1) then
                            reject(uiTranslations["MultipleSelections_Message"])
                            return
                        elseif (#selection < 1) then
                            reject(uiTranslations["EmptySelection_Message"])
                            return
                        end

                        local object = selection[1]

                        if (not object:IsA("StringValue")) then
                            reject(Translator.FormatByKey("InvalidSelection_Message", { "StringValue" }))
                            return
                        end

                        local newSettingsTable = HttpService:JSONDecode(object.Value)
                        local isValid, message = settingsTableValidator(newSettingsTable)

                        if (isValid) then
                            resolve(newSettingsTable)
                        else
                            reject(Translator.FormatByKey("NonConformantSettingsTable_Message", { message }))
                        end
                    end):andThen(
                        self.importSuccessHandler(Translator.FormatByKey("ValidSettingsTableImport_Message", { "StringValue" })),
                        self.importErrorHandler
                    )
                end,
            }),

            StatusIcon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = Style.UDim2.StandardButtonSize,
                Position = UDim2.new(0, 80 + Style.Constants.MinorElementPadding, 0, Style.Constants.StandardTextSize + Style.Constants.MinorElementPadding),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = if status then statusIcons[status] else "",

                ImageColor3 = if statusColorGenerators[status] then
                    statusColorGenerators[status](theme)
                else theme:GetColor(Enum.StudioStyleGuideColor.MainText),

                [Roact.Ref] = self.statusIcon,
            }),

            StatusText = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize * 2),
                Position = UDim2.new(0, 0, 0, Style.Constants.StandardTextSize + Style.Constants.StandardButtonHeight + (Style.Constants.MinorElementPadding * 2)),

                Text = self.state.statusMessage or uiTranslations["WaitingForImport_Message"],
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
            }),
        })
    elseif (importType == "File") then
        importPage = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding + (Style.Constants.StandardTextSize * 2)),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 3,
        }, {
            ImportButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, 0),
                Size = Style.UDim2.DialogButtonSize,
                
                disabled = (status == "wait"),
                displayType = "text",
                text = uiTranslations["SelectAFile_ButtonText"],

                onActivated = function()
                    self:setState({
                        settings = Roact.None,
                        status = "wait",
                    })

                    local file

                    Promise.new(function(resolve, reject)
                        file = StudioService:PromptImportFile({"json"})
                        
                        if (not file) then
                            resolve()
                            return
                        end
                        
                        local newSettingsTable = HttpService:JSONDecode(file:GetBinaryContents())
                        local isValid, message = settingsTableValidator(newSettingsTable)

                        if (isValid) then
                            resolve(newSettingsTable)
                        else
                            reject(Translator.FormatByKey("NonConformantSettingsTable_Message", { message }))
                        end
                    end):andThen(
                        self.importSuccessHandler(Translator.FormatByKey("ValidSettingsTableImport_Message", { "file" })),
                        self.importErrorHandler
                    ):finally(function()
                        if (file) then
                            file:Destroy()
                            file = nil
                        end
                    end)
                end,
            }),

            StatusIcon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = Style.UDim2.StandardButtonSize,
                Position = UDim2.new(0, Style.Constants.DialogButtonWidth + Style.Constants.MinorElementPadding, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = if status then statusIcons[status] else "",

                ImageColor3 = if statusColorGenerators[status] then
                    statusColorGenerators[status](theme)
                else theme:GetColor(Enum.StudioStyleGuideColor.MainText),

                [Roact.Ref] = self.statusIcon,
            }),

            StatusText = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize * 2),
                Position = UDim2.new(0, 0, 0, Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding),

                Text = self.state.statusMessage or uiTranslations["WaitingForImport_Message"],
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
            }),
        })
    end

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
    }, {
        UIPadding = Roact.createElement(StandardUIPadding, {
            paddings = {Style.Constants.PagePadding}
        }),

        Dialog = Roact.createElement(StandardScrollingFrame, {
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.new(1, 0, 1, -(Style.Constants.StandardButtonHeight + Style.Constants.SpaciousElementPadding)),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            CanvasSize = self.listLength:map(function(length)
                return UDim2.new(0, 0, 0, length)
            end),
        }, {
            UIPadding = Roact.createElement(StandardUIPadding, {
                paddings = {0, 0, 0, Style.Constants.SpaciousElementPadding}
            }),

            UIListLayout = Roact.createElement(StandardUIListLayout, {
                Padding = UDim.new(0, Style.Constants.SpaciousElementPadding),

                [Roact.Change.AbsoluteContentSize] = function(obj)
                    self.updateListLength(obj.AbsoluteContentSize.Y)
                end,

                preset = 1,
            }),
            
            ImportType = Roact.createElement(RadioButtonGroup, {
                Size = UDim2.new(1, 0, 0, (Style.Constants.StandardButtonHeight * 3) + (Style.Constants.MinorElementPadding * 2)),
                LayoutOrder = 1,
    
                selected = table.find(importTypes, importType),
                options = importOptions,

                onSelected = function(i)
                    self:setState({
                        importType = importTypes[i],
                        settings = Roact.None,

                        status = Roact.None,
                        statusMessage = Roact.None,
                    })
                end,
            }),

            Separator1 = if importType then
                Roact.createElement("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    LayoutOrder = 2,

                    BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Separator)
                })
            else nil,

            ImportPage = if importType then importPage else nil,
        }),

        Buttons = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, 0, 1, 0),
            Size = UDim2.new(0, Style.Constants.DialogButtonWidth * 2 + Style.Constants.SpaciousElementPadding, 0, Style.Constants.StandardButtonHeight),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            UIListLayout = Roact.createElement(StandardUIListLayout, {
                Padding = UDim.new(0, Style.Constants.SpaciousElementPadding),
                
                preset = 2,
            }),

            CancelButton = Roact.createElement(Button, {
                Size = Style.UDim2.DialogButtonSize,
                LayoutOrder = 0,

                displayType = "text",
                text = uiTranslations["Cancel_ButtonText"],

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton, Enum.StudioStyleGuideModifier.Hover),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonText),

                onActivated = function()
                    self.props.onPromptClosed(nil)
                end
            }),

            ImportButton = Roact.createElement(Button, {
                Size = Style.UDim2.DialogButtonSize,
                LayoutOrder = 1,

                disabled = (not settings),
                displayType = "text",
                text = uiTranslations["Import_ButtonText"],

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton, Enum.StudioStyleGuideModifier.Hover),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText),

                onActivated = function()
                    local filledSettingsTable = {
                        [Constants.COLORPANE_USERDATA_KEY] = Cryo.Dictionary.join(ColorPaneUserDataDefaultValues, settings[Constants.COLORPANE_USERDATA_KEY]),
                        [Constants.COMPANION_USERDATA_KEY] = Cryo.Dictionary.join(CompanionUserDataDefaultValues, settings[Constants.COMPANION_USERDATA_KEY]),
                    }

                    self.props.onPromptClosed(filledSettingsTable)
                end
            }),
        })
    })
end

return ConnectTheme(ImportSettings)