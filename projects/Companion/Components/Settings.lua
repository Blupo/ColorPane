--[[
    Component for managing ColorPane settings.
]]

local TextService = game:GetService("TextService")

local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local Constants = require(CommonModules.Constants)
local CommonEnums = require(CommonModules.Enums)
local Style = require(CommonModules.Style)
local Translator = require(CommonModules.Translator)

local CommonIncludes = Common.Includes
local Roact = require(CommonIncludes.RoactRodux.Roact)

local CommonComponents = Common.Components
local Checkbox = require(CommonComponents.Checkbox)
local ConnectTheme = require(CommonComponents.ConnectTheme)
local TextInput = require(CommonComponents.TextInput)

local StandardComponents = CommonComponents.StandardComponents
local StandardScrollingFrame = require(StandardComponents.ScrollingFrame)
local StandardTextLabel = require(StandardComponents.TextLabel)
local StandardUIListLayout = require(StandardComponents.UIListLayout)
local StandardUIPadding = require(StandardComponents.UIPadding)

local Modules = root.Modules
local Enums = require(Modules.Enums)
local ManagedUserData = require(Modules.ManagedUserData)

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
end

Settings.willUnmount = function(self)
    if (self.state.restorePromptSubscription) then
        self.state.restorePromptSubscription:unsubscribe()
    end

    self.colorPaneValueChanged:unsubscribe()
    self.companionValueChanged:unsubscribe()
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

                Text = "Gradient keypoint snap %",
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
                    return ((n >= Constants.MIN_SNAP_VALUE) and (n <= Constants.MAX_SNAP_VALUE))
                end,

                onSubmit = function(text)
                    local n = tonumber(text)
                    n = math.clamp(n / 100, Constants.MIN_SNAP_VALUE, Constants.MAX_SNAP_VALUE)
                    n = round(n, math.log10(Constants.MIN_SNAP_VALUE))

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
    })
end

return ConnectTheme(Settings)
