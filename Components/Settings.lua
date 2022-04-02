local RunService = game:GetService("RunService")

---

local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local PluginSettings = require(PluginModules:FindFirstChild("PluginSettings"))
local Style = require(PluginModules:FindFirstChild("Style"))
local Translator = require(PluginModules:FindFirstChild("Translator"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local Checkbox = require(Components:FindFirstChild("Checkbox"))
local ConnectTheme = require(Components:FindFirstChild("ConnectTheme"))
local TextInput = require(Components:FindFirstChild("TextInput"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardScrollingFrame = StandardComponents.ScrollingFrame
local StandardTextLabel = StandardComponents.TextLabel
local StandardUIListLayout = StandardComponents.UIListLayout
local StandardUIPadding = StandardComponents.UIPadding

---

local SETTINGS = {
    [PluginEnums.PluginSettingKey.AutoLoadColorProperties] = true,
    [PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation] = true,
    [PluginEnums.PluginSettingKey.AutoCheckForUpdate] = true,
    [PluginEnums.PluginSettingKey.AutoSave] = true,
    [PluginEnums.PluginSettingKey.AutoSaveInterval] = true,
    [PluginEnums.PluginSettingKey.CacheAPIData] = true,
    [PluginEnums.PluginSettingKey.ColorPropertiesLivePreview] = true,
}

local uiTranslations = Translator.GenerateTranslationTable({
    "AutoLoadColorProperties_SettingDescription",
    "AutoSave_SettingDescription",
    "AutoSaveInterval_SettingDescription",
    "CacheAPIData_SettingDescription",
    "AutoCheckForUpdate_SettingDescription",
    "AskNameBeforePaletteCreation_SettingDescription",
    "ColorPropertiesLivePreview_SettingDescription",

    "ClaimSessionLock_ButtonText",
    "SessionLockClaimed_Message",
})

---

--[[
    store props

        theme: StudioTheme
]]

local Settings = Roact.PureComponent:extend("Settings")

Settings.init = function(self)
    local initSettings = {}

    for key in pairs(SETTINGS) do
        initSettings[key] = PluginSettings.Get(key)
    end

    self.listLength, self.updateListLength = Roact.createBinding(0)
    self:setState(initSettings)

    self:setState({
        canSave = PluginSettings.GetSavingAbility()
    })
end

Settings.didMount = function(self)
    self.settingsChanged = PluginSettings.SettingChanged:Connect(function(key, newValue)
        if (not SETTINGS[key]) then return end
        
        self:setState({
            [key] = newValue,
        })
    end)

    self.savingAbilityChanged = PluginSettings.SavingAbilityChanged:Connect(function(canSave)
        self:setState({
            canSave = canSave
        })
    end)
end

Settings.willUnmount = function(self)
    self.settingsChanged:Disconnect()
    self.savingAbilityChanged:Disconnect()
    PluginSettings.Flush()
end

Settings.render = function(self)
    local theme = self.props.theme
    local canSave = self.state.canSave
    local isEdit = RunService:IsEdit()

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
        UIPadding = Roact.createElement(StandardUIPadding, {Style.Constants.PagePadding}),

        UIListLayout = Roact.createElement(StandardUIListLayout, {
            Padding = UDim.new(0, Style.Constants.SpaciousElementPadding),
            HorizontalAlignment = Enum.HorizontalAlignment.Left,

            [Roact.Change.AbsoluteContentSize] = function(obj)
                self.updateListLength(obj.AbsoluteContentSize.Y + (Style.Constants.PagePadding * 2))
            end,

            preset = 1,
        }),

        AutoLoadColorPropertiesCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize * 2),
            LayoutOrder = 2,
            
            disabled = (not canSave),
            value = self.state[PluginEnums.PluginSettingKey.AutoLoadColorProperties],
            text = uiTranslations["AutoLoadColorProperties_SettingDescription"],

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AutoLoadColorProperties, newValue)
            end,
        }),

        AutoSaveCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardInputHeight),
            LayoutOrder = 3,
            
            disabled = (not canSave),
            value = self.state[PluginEnums.PluginSettingKey.AutoSave],
            text = uiTranslations["AutoSave_SettingDescription"],

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AutoSave, newValue)
            end,
        }),

        AutoSaveInterval = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardInputHeight),
            LayoutOrder = 4,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Label = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(1, -(30 + Style.Constants.SpaciousElementPadding), 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),

                Text = uiTranslations["AutoSaveInterval_SettingDescription"],
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,

                TextColor3 = theme:GetColor(
                    Enum.StudioStyleGuideColor.MainText,
                    (not canSave) and Enum.StudioStyleGuideModifier.Disabled or nil
                )
            }),

            Input = Roact.createElement(TextInput, {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 30, 1, 0),
                Position = UDim2.new(0, 0, 0.5, 0),
                Text = self.state[PluginEnums.PluginSettingKey.AutoSaveInterval],
                TextXAlignment = Enum.TextXAlignment.Center,

                isTextAValidValue = function(text)
                    local interval = tonumber(text)
                    if (not interval) then return false end

                    return ((math.floor(interval) == interval) and (interval > 0))
                end,

                onSubmit = function(newText)
                    local interval = tonumber(newText)
                    if (not interval) then return false end
                    if ((math.floor(interval) ~= interval) or (interval < 1)) then return end

                    PluginSettings.Set(PluginEnums.PluginSettingKey.AutoSaveInterval, interval)
                end,
                
                disabled = (not canSave) or (not self.state[PluginEnums.PluginSettingKey.AutoSave]),
            })
        }),

        CacheAPIDataCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize * 2),
            LayoutOrder = 5,
            
            disabled = (not canSave),
            value = self.state[PluginEnums.PluginSettingKey.CacheAPIData],
            text = uiTranslations["CacheAPIData_SettingDescription"],

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.CacheAPIData, newValue)
            end,
        }),

        AutoCheckForUpdateCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardInputHeight),
            LayoutOrder = 6,
            
            disabled = (not canSave),
            value = self.state[PluginEnums.PluginSettingKey.AutoCheckForUpdate],
            text = uiTranslations["AutoCheckForUpdate_SettingDescription"],

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AutoCheckForUpdate, newValue)
            end,
        }),

        AskNameBeforePaletteCreationCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardInputHeight),
            LayoutOrder = 7,
            
            disabled = (not canSave),
            value = self.state[PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation],
            text = uiTranslations["AskNameBeforePaletteCreation_SettingDescription"],

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation, newValue)
            end,
        }),

        ColorPropertiesLivePreviewCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize * 2),
            LayoutOrder = 8,
            
            disabled = (not canSave),
            value = self.state[PluginEnums.PluginSettingKey.ColorPropertiesLivePreview],
            text = uiTranslations["ColorPropertiesLivePreview_SettingDescription"],

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.ColorPropertiesLivePreview, newValue)
            end,
        }),
        
        ClaimSessionLockButton = Roact.createElement(Button, {
            Size = UDim2.new(0, 120, 0, Style.Constants.StandardInputHeight),
            LayoutOrder = 9,

            disabled = (not isEdit),
            displayType = "text",
            text = uiTranslations["ClaimSessionLock_ButtonText"],

            onActivated = function()
                PluginSettings.UpdateSavingAbility(true)
                warn("[ColorPane] " .. uiTranslations["SessionLockClaimed_Message"])
            end,
        }),
    })
end

return ConnectTheme(Settings)
