-- Component for managing settings.

local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

---

local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local CommonConstants = require(CommonModules.Constants)
local CommonEnums = require(CommonModules.Enums)
local Prompt = require(CommonModules.Prompt)
local Style = require(CommonModules.Style)
local Translator = require(CommonModules.Translator)
local Window = require(CommonModules.Window)

local CommonIncludes = Common.Includes
local Roact = require(CommonIncludes.RoactRodux.Roact)

local CommonComponents = Common.Components
local Button = require(CommonComponents.Button)
local Checkbox = require(CommonComponents.Checkbox)
local ConnectTheme = require(CommonComponents.ConnectTheme)
local ExportText = require(CommonComponents.ExportText)
local TextInput = require(CommonComponents.TextInput)

local StandardComponents = CommonComponents.StandardComponents
local StandardScrollingFrame = require(StandardComponents.ScrollingFrame)
local StandardTextLabel = require(StandardComponents.TextLabel)
local StandardUIListLayout = require(StandardComponents.UIListLayout)
local StandardUIPadding = require(StandardComponents.UIPadding)

local Components = root.Components
local ImportSettings = require(Components.ImportSettings)

local Modules = root.Modules
local Constants = require(Modules.Constants)
local Enums = require(Modules.Enums)
local ManagedUserData = require(Modules.ManagedUserData)
local Store = require(Modules.Store)
local WidgetInfo = require(Modules.WidgetInfo)

---

local COLORPANE_SETTINGS_LIST = {
    [CommonEnums.ColorPaneUserDataKey.AskNameBeforePaletteCreation] = true,
    [CommonEnums.ColorPaneUserDataKey.SnapValue] = true,
}

local COMPANION_SETTINGS_LIST = {
    [Enums.CompanionUserDataKey.AutoLoadColorPropertiesAPIData] = true,
    [Enums.CompanionUserDataKey.CacheColorPropertiesAPIData] = true,
}

local UI_TRANSLATIONS = Translator.GenerateTranslationTable({
    "AskNameBeforePaletteCreation_SettingDescription",
    "AutoLoadColorProperties_SettingDescription",
    "CacheAPIData_SettingDescription",
    "ImportSettings_ButtonText",
    "ExportSettings_ButtonText",
    "ImportSettings_WindowTitle",
    "ExportSettings_WindowTitle",
    "ExportSettings_CopyPrompt",
    "ConfirmSettingsImport_WindowTitle",
    "ConfirmSettingsImport_PromptText",
    "Import_ButtonText",
    "SnapValue_SettingDescription",
})

local colorPaneUserData = ManagedUserData.ColorPane
local companionUserData = ManagedUserData.Companion

local round = function(n: number, optionalE: number?): number
    local e: number = optionalE or 0
    local p: number = 10^e

    if (p >= 0) then
        return math.floor((n / p) + 0.5) * p
    else
        return math.floor((n * p) + 0.5) / p
    end
end

---

--[[
    props

        LayoutOrder
        Text

    store props

        theme: StudioTheme
]]
local SectionHeader = ConnectTheme(function(props)
    local textSize = TextService:GetTextSize(
        props.Text,
        Style.Constants.StandardTextSize,
        Style.Fonts.Standard,
        Vector2.new(math.huge, math.huge)
    )

    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize + (2 * Style.Constants.PagePadding)),
        LayoutOrder = props.LayoutOrder,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        UIPadding = Roact.createElement(StandardUIPadding, {
            paddings = {Style.Constants.PagePadding, 0}
        }),
        
        HeaderText = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(0, textSize.X, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Text = props.Text,
        }),

        Line = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(1, -(textSize.X + Style.Constants.SpaciousElementPadding), 0, 1),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            BackgroundColor3 = props.theme:GetColor(Enum.StudioStyleGuideColor.MainText)
        }),
    })
end)

--[[
    store props

        theme: StudioTheme
]]

local Settings = Roact.PureComponent:extend("Settings")

Settings.init = function(self)
    local initSettings = {}

    for key in pairs(COLORPANE_SETTINGS_LIST) do
        initSettings[key] = colorPaneUserData:getValue(key)
    end

    for key in pairs(COMPANION_SETTINGS_LIST) do
        initSettings[key] = companionUserData:getValue(key)
    end

    self.listLength, self.updateListLength = Roact.createBinding(0)
    self.importSettingsWindow = Window.new(WidgetInfo.ImportSettings.Id, WidgetInfo.ImportSettings.Info)
    self.exportSettingsWindow = Window.new(WidgetInfo.ExportSettings.Id, WidgetInfo.ExportSettings.Info)
    self.confirmImportSubscription = nil
    self:setState(initSettings)
end

Settings.didMount = function(self)
    self.colorPaneValueChanged = colorPaneUserData.valueChanged:subscribe(function(setting)
        local key, newValue = setting.Key, setting.Value
        if (not COLORPANE_SETTINGS_LIST[key]) then return end
        
        self:setState({
            [key] = newValue,
        })
    end)

    self.companionValueChanged = companionUserData.valueChanged:subscribe(function(setting)
        local key, newValue = setting.Key, setting.Value
        if (not COMPANION_SETTINGS_LIST[key]) then return end
        
        self:setState({
            [key] = newValue,
        })
    end)

    self.importOpenedWithoutMounting = self.importSettingsWindow.openedWithoutMounting:subscribe(function()
        self.importSettingsWindow:close()
    end)

    self.exportOpenedWithoutMounting = self.exportSettingsWindow.openedWithoutMounting:subscribe(function()
        self.exportSettingsWindow:close()
    end)

    self.importClosedWithoutUnmounting = self.importSettingsWindow.closedWithoutUnmounting:subscribe(function()
        self.importSettingsWindow:unmount()
    end)

    self.exportClosedWithoutUnmounting = self.exportSettingsWindow.closedWithoutUnmounting:subscribe(function()
        self.exportSettingsWindow:unmount()
    end)
end

Settings.willUnmount = function(self)
    if (self.state.restorePromptSubscription) then
        self.state.restorePromptSubscription:unsubscribe()
    end

    if (self.confirmImportSubscription) then
        self.confirmImportSubscription:unsubscribe()
    end

    self.colorPaneValueChanged:unsubscribe()
    self.companionValueChanged:unsubscribe()
    self.importOpenedWithoutMounting:unsubscribe()
    self.importClosedWithoutUnmounting:unsubscribe()
    self.exportOpenedWithoutMounting:unsubscribe()
    self.exportClosedWithoutUnmounting:unsubscribe()

    self.importSettingsWindow:destroy()
    self.exportSettingsWindow:destroy()
end

Settings.render = function(self)
    local theme: StudioTheme = self.props.theme

    return Roact.createElement(StandardScrollingFrame, {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,

        CanvasSize = self.listLength:map(function(length)
            return UDim2.new(0, 0, 0, length)
        end),

        useMainBackgroundColor = true,
    }, {
        UIPadding = Roact.createElement(StandardUIPadding, {
            paddings = {Style.Constants.PagePadding}
        }),

        UIListLayout = Roact.createElement(StandardUIListLayout, {
            Padding = UDim.new(0, Style.Constants.SpaciousElementPadding),
            HorizontalAlignment = Enum.HorizontalAlignment.Left,

            [Roact.Change.AbsoluteContentSize] = function(obj)
                self.updateListLength(obj.AbsoluteContentSize.Y + (Style.Constants.PagePadding * 2))
            end,

            preset = 1,
        }),

        ColorPaneSectionHeader = Roact.createElement(SectionHeader, {
            LayoutOrder = 1,
            Text = "ColorPane",
        }),

        AskNameBeforePaletteCreationCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardInputHeight),
            LayoutOrder = 2,
            
            value = self.state[CommonEnums.ColorPaneUserDataKey.AskNameBeforePaletteCreation],
            text = UI_TRANSLATIONS["AskNameBeforePaletteCreation_SettingDescription"],

            onChecked = function(newValue)
                colorPaneUserData:setValue(CommonEnums.ColorPaneUserDataKey.AskNameBeforePaletteCreation, newValue)
            end,
        }),

        SnapValue = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardInputHeight),
            LayoutOrder = 3,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Label = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(1, -(40 + Style.Constants.SpaciousElementPadding), 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),

                Text = UI_TRANSLATIONS["SnapValue_SettingDescription"],
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,

                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
            }),

            Input = Roact.createElement(TextInput, {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 40, 1, 0),
                Position = UDim2.new(0, 0, 0.5, 0),

                Text = self.state[CommonEnums.ColorPaneUserDataKey.SnapValue] * 100,
                TextXAlignment = Enum.TextXAlignment.Center,

                isTextAValidValue = function(text)
                    local n = tonumber(text)
                    if (not n) then return false end

                    n = n / 100
                    return ((n >= CommonConstants.MIN_SNAP_VALUE) and (n <= CommonConstants.MAX_SNAP_VALUE))
                end,

                onSubmit = function(text)
                    local n = tonumber(text)
                    n = math.clamp(n / 100, CommonConstants.MIN_SNAP_VALUE, CommonConstants.MAX_SNAP_VALUE)
                    n = round(n, math.log10(CommonConstants.MIN_SNAP_VALUE))

                    colorPaneUserData:setValue(CommonEnums.ColorPaneUserDataKey.SnapValue, n)
                end,
            })
        }),

        CompanionSectionHeader = Roact.createElement(SectionHeader, {
            LayoutOrder = 4,
            Text = "Companion",
        }),

        AutoLoadColorPropertiesCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize * 2),
            LayoutOrder = 5,
            
            value = self.state[Enums.CompanionUserDataKey.AutoLoadColorPropertiesAPIData],
            text = UI_TRANSLATIONS["AutoLoadColorProperties_SettingDescription"],

            onChecked = function(newValue)
                companionUserData:setValue(Enums.CompanionUserDataKey.AutoLoadColorPropertiesAPIData, newValue)
            end,
        }),

        CacheAPIDataCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize * 2),
            LayoutOrder = 6,
            
            value = self.state[Enums.CompanionUserDataKey.CacheColorPropertiesAPIData],
            text = UI_TRANSLATIONS["CacheAPIData_SettingDescription"],

            onChecked = function(newValue)
                companionUserData:setValue(Enums.CompanionUserDataKey.CacheColorPropertiesAPIData, newValue)
            end,
        }),

        ControlsSectionHeader = Roact.createElement(SectionHeader, {
            LayoutOrder = 7,
            Text = "Controls",
        }),

        ImportSettingsButton = Roact.createElement(Button, {
            Size = UDim2.new(0, 100, 0, Style.Constants.StandardButtonHeight),
            LayoutOrder = 8,

            displayType = "text",
            text = UI_TRANSLATIONS["ImportSettings_ButtonText"],

            onActivated = function()
                if (self.importSettingsWindow:isMounted() or self.confirmImportSubscription) then return end
                
                self.importSettingsWindow:mount(
                    UI_TRANSLATIONS["ImportSettings_WindowTitle"],
                    Roact.createElement(ImportSettings, {
                        onPromptClosed = function(settings)
                            self.importSettingsWindow:unmount()
                            if (not settings) then return end

                            local confirmImport = Prompt(
                                WidgetInfo.ConfirmImportSettingsPrompt.Id,
                                WidgetInfo.ConfirmImportSettingsPrompt.Info,
                                {
                                    Title = UI_TRANSLATIONS["ConfirmSettingsImport_WindowTitle"],
                                    PromptText = UI_TRANSLATIONS["ConfirmSettingsImport_PromptText"],
                                    ConfirmText = UI_TRANSLATIONS["Import_ButtonText"],
                                },
                                Store
                            )

                            self.confirmImportSubscription = confirmImport:subscribe(function(confirm)
                                if (not confirm) then
                                    self.confirmImportSubscription = nil
                                    return
                                end

                                for key, value in pairs(settings[Constants.COLORPANE_USERDATA_KEY]) do
                                    colorPaneUserData:setValue(key, value)
                                end

                                for key, value in pairs(settings[Constants.COMPANION_USERDATA_KEY]) do
                                    companionUserData:setValue(key, value)
                                end

                                print("Settings import complete!")
                                self.confirmImportSubscription = nil
                            end)
                        end,
                    }),
                    Store
                )
            end,
        }),

        ExportSettingsButton = Roact.createElement(Button, {
            Size = UDim2.new(0, 100, 0, Style.Constants.StandardButtonHeight),
            LayoutOrder = 9,

            displayType = "text",
            text = UI_TRANSLATIONS["ExportSettings_ButtonText"],

            onActivated = function()
                if (self.exportSettingsWindow:isMounted()) then return end

                local settingsTable = {
                    [Constants.COLORPANE_USERDATA_KEY] = colorPaneUserData:getAllValues(),
                    [Constants.COMPANION_USERDATA_KEY] = companionUserData:getAllValues(),
                }

                self.exportSettingsWindow:mount(
                    UI_TRANSLATIONS["ExportSettings_WindowTitle"],
                    Roact.createElement(ExportText, {
                        promptText = UI_TRANSLATIONS["ExportSettings_CopyPrompt"],
                        text = HttpService:JSONEncode(settingsTable),
                    }),
                    Store
                )
            end,
        }),
    })
end

return ConnectTheme(Settings)
