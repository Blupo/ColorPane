local RunService = game:GetService("RunService")

---

local root = script.Parent.Parent
local Common = root.Common

local CommonComponents = Common.Components
local Button = require(CommonComponents.Button)
local Checkbox = require(CommonComponents.Checkbox)
local ConnectTheme = require(CommonComponents.ConnectTheme)

local CommonIncludes = Common.Includes
local Roact = require(CommonIncludes.RoactRodux.Roact)

local CommonModules = Common.Modules
local Style = require(CommonModules.Style)
local Translator = require(CommonModules.Translator)

local Components = root.Components
local ColorPropertiesList = require(Components.ColorPropertiesList)

local Modules = root.Modules
local Enums = require(Modules.Enums)
local ManagedUserData = require(Modules.ManagedUserData)
local RobloxAPI = require(Modules.RobloxAPI)

local StandardComponents = CommonComponents.StandardComponents
local StandardTextLabel = require(StandardComponents.TextLabel)
local StandardUIPadding = require(StandardComponents.UIPadding)

---

local companionUserData = ManagedUserData.Companion

local uiTranslations = Translator.GenerateTranslationTable({
    "NoAPIAlert_MainText",
    "NoAPIAlert_SecondaryText_EditMode",
    "NoAPIAlert_SecondaryText_NotEditMode",
    "Loading_Message",
    "Load_ButtonText",
    "AutoLoadColorProperties_SettingDescription",
    "CacheAPIData_SettingDescription",
})

---

--[[
    store props

        theme: StudioTheme
]]

local NoAPIAlert = Roact.PureComponent:extend("NoAPIAlert")

NoAPIAlert.init = function(self)
    self.apiDataRequestStarted = RobloxAPI.DataRequestStarted:subscribe(function()
        self:setState({
            requestRunning = true,
        })
    end)

    self.apiDataRequestFinished = RobloxAPI.DataRequestFinished:subscribe(function()
        self:setState({
            requestRunning = false,
        })
    end)

    self.valueChanged = companionUserData.valueChanged:subscribe(function(value)
        local key = value.Key

        if (
            (key ~= Enums.CompanionUserDataKey.AutoLoadColorPropertiesAPIData) and
            (key ~= Enums.CompanionUserDataKey.CacheColorPropertiesAPIData)
        ) then return end

        self:setState({
            [key] = value.Value
        })
    end)
    
    self:setState({
        requestRunning = RobloxAPI.IsRequestRunning(),

        [Enums.CompanionUserDataKey.AutoLoadColorPropertiesAPIData] = companionUserData:getValue(Enums.CompanionUserDataKey.AutoLoadColorPropertiesAPIData),
        [Enums.CompanionUserDataKey.CacheColorPropertiesAPIData] = companionUserData:getValue(Enums.CompanionUserDataKey.CacheColorPropertiesAPIData)
    })
end

NoAPIAlert.willUnmount = function(self)
    self.apiDataRequestStarted:unsubscribe()
    self.apiDataRequestFinished:unsubscribe()
    self.valueChanged:unsubscribe()
end

NoAPIAlert.render = function(self)
    local theme = self.props.theme
    local requestRunning = self.state.requestRunning

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
    }, {
        UIPadding = Roact.createElement(StandardUIPadding, {
            paddings = {Style.Constants.PagePadding}
        }),

        Notice = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.new(1, 0, 0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),

            Text = uiTranslations["NoAPIAlert_MainText"] .. (RunService:IsEdit() and
                (" " .. uiTranslations["NoAPIAlert_SecondaryText_EditMode"]) or
                ("\n\n" .. uiTranslations["NoAPIAlert_SecondaryText_NotEditMode"])
            ),

            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Bottom,
            TextWrapped = true,
        }),

        LoadButton = Roact.createElement(Button, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0.5, Style.Constants.SpaciousElementPadding),
            Size = UDim2.new(0, Style.Constants.DialogButtonWidth, 0, Style.Constants.StandardButtonHeight),

            disabled = requestRunning,
            displayType = "text",
            text = uiTranslations[requestRunning and "Loading_Message" or "Load_ButtonText"],

            backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton),
            borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
            hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton, Enum.StudioStyleGuideModifier.Hover),
            displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText),

            disabledBackgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton, Enum.StudioStyleGuideModifier.Disabled),
            disabledDisplayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText, Enum.StudioStyleGuideModifier.Disabled),

            onActivated = function()
                if (requestRunning) then return end
                
                RobloxAPI.GetData()
            end
        }),

        AutoLoadRobloxAPICheckbox = Roact.createElement(Checkbox, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0.5, Style.Constants.StandardButtonHeight + (Style.Constants.SpaciousElementPadding * 2)),
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize * 2),
            
            value = self.state[Enums.CompanionUserDataKey.AutoLoadColorPropertiesAPIData],
            text = uiTranslations["AutoLoadColorProperties_SettingDescription"],

            onChecked = function(newValue)
                companionUserData:setValue(Enums.CompanionUserDataKey.AutoLoadColorPropertiesAPIData, newValue)
            end,
        }),

        CacheAPIDataCheckbox = Roact.createElement(Checkbox, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0.5, Style.Constants.StandardButtonHeight + (Style.Constants.SpaciousElementPadding * 3) + (Style.Constants.StandardTextSize * 2)),
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize * 2),
            
            value = self.state[Enums.CompanionUserDataKey.CacheColorPropertiesAPIData],
            text = uiTranslations["CacheAPIData_SettingDescription"],

            onChecked = function(newValue)
                companionUserData:setValue(Enums.CompanionUserDataKey.CacheColorPropertiesAPIData, newValue)
            end,
        })
    })
end

---

local ColorProperties = Roact.PureComponent:extend("ColorProperties")

ColorProperties.init = function(self)
    local apiLoaded = RobloxAPI.IsAvailable()

    self.apiDataLoaded = (not apiLoaded) and
        RobloxAPI.DataRequestFinished:subscribe(function(didLoad)
            if (not didLoad) then return end

            self.apiDataLoaded:unsubscribe()
            self.apiDataLoaded = nil

            self:setState({
                apiLoaded = true,
            })
        end)
    or nil

    self:setState({
        apiLoaded = apiLoaded
    })
end

ColorProperties.willUnmount = function(self)
    if (self.apiDataLoaded) then
        self.apiDataLoaded:unsubscribe()
    end
end

ColorProperties.render = function(self)
    return Roact.createElement(self.state.apiLoaded and ColorPropertiesList or NoAPIAlert)
end

---

NoAPIAlert = ConnectTheme(NoAPIAlert)
return ColorProperties