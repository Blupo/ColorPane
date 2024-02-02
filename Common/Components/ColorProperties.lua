local RunService = game:GetService("RunService")

---

local root = script.Parent.Parent

local PluginModules = root.PluginModules
local PluginEnums = require(PluginModules.PluginEnums)
local PluginSettings = require(PluginModules.PluginSettings)
local RobloxAPI = require(PluginModules.RobloxAPI)
local Style = require(PluginModules.Style)
local Translator = require(PluginModules.Translator)

local includes = root.includes
local Roact = require(includes.Roact)

local Components = root.Components
local Button = require(Components.Button)
local Checkbox = require(Components.Checkbox)
local ColorPropertiesList = require(Components.ColorPropertiesList)
local ConnectTheme = require(Components.ConnectTheme)

local StandardComponents = require(Components.StandardComponents)
local StandardTextLabel = StandardComponents.TextLabel
local StandardUIPadding = StandardComponents.UIPadding

---

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

    self.settingsChanged = PluginSettings.SettingChanged:subscribe(function(setting)
        local key, newValue = setting.Key, setting.Value
        if ((key ~= PluginEnums.PluginSettingKey.AutoLoadColorProperties) and (key ~= PluginEnums.PluginSettingKey.CacheAPIData)) then return end

        self:setState({
            [key] = newValue
        })
    end)

    self.savingAbilityChanged = PluginSettings.SavingAbilityChanged:subscribe(function(canSave: boolean)
        self:setState({
            canSave = canSave
        })
    end)
    
    self:setState({
        requestRunning = RobloxAPI.IsRequestRunning(),
        canSave = PluginSettings.GetSavingAbility(),

        [PluginEnums.PluginSettingKey.AutoLoadColorProperties] = PluginSettings.Get(PluginEnums.PluginSettingKey.AutoLoadColorProperties),
        [PluginEnums.PluginSettingKey.CacheAPIData] = PluginSettings.Get(PluginEnums.PluginSettingKey.CacheAPIData)
    })
end

NoAPIAlert.willUnmount = function(self)
    self.apiDataRequestStarted:unsubscribe()
    self.apiDataRequestFinished:unsubscribe()
    self.settingsChanged:unsubscribe()
    self.savingAbilityChanged:unsubscribe()

    PluginSettings.Flush()
end

NoAPIAlert.render = function(self)
    local theme = self.props.theme

    local requestRunning = self.state.requestRunning
    local canSave = self.state.canSave

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
    }, {
        UIPadding = Roact.createElement(StandardUIPadding, {Style.Constants.PagePadding}),

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
            
            disabled = (not canSave),
            value = self.state[PluginEnums.PluginSettingKey.AutoLoadColorProperties],
            text = uiTranslations["AutoLoadColorProperties_SettingDescription"],

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AutoLoadColorProperties, newValue)
            end,
        }),

        CacheAPIDataCheckbox = Roact.createElement(Checkbox, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0.5, Style.Constants.StandardButtonHeight + (Style.Constants.SpaciousElementPadding * 3) + (Style.Constants.StandardTextSize * 2)),
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize * 2),
            
            disabled = (not canSave),
            value = self.state[PluginEnums.PluginSettingKey.CacheAPIData],
            text = uiTranslations["CacheAPIData_SettingDescription"],

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.CacheAPIData, newValue)
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
        self.apiDataLoaded = nil
    end
end

ColorProperties.render = function(self)
    return Roact.createElement(self.state.apiLoaded and ColorPropertiesList or NoAPIAlert)
end

---

NoAPIAlert = ConnectTheme(NoAPIAlert)
return ColorProperties