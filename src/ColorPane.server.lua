local StudioService: StudioService = game:GetService("StudioService")
local RunService: RunService = game:GetService("RunService")

---

local root = script.Parent
local APIScript = root.API

local includes = root.includes
local Roact = require(includes.Roact)
local RoactRodux = require(includes.RoactRodux)
local Signal = require(includes.Signal)

local PluginModules = root.PluginModules

-- provide plugin object to modules
-- IMPORTANT: this needs to come before any modules that require the plugin object
require(PluginModules.PluginProvider)(plugin)  

local PluginToolbar = require(PluginModules.PluginToolbar)
local PluginEnums = require(PluginModules.PluginEnums)
local PluginSettings = require(PluginModules.PluginSettings)
local PluginWidget = require(PluginModules.PluginWidget)
local RobloxAPI = require(PluginModules.RobloxAPI)
local Store = require(PluginModules.Store)
local Translator = require(PluginModules.Translator)
local UpdateChecker = require(PluginModules.UpdateChecker)

local Components = root.Components
local ColorProperties = require(Components.ColorProperties)
local FirstTimeSetup = require(Components.FirstTimeSetup)
local Settings = require(Components.Settings)

---

local ColorPane = require(PluginModules.APIProvider)

local colorPropertiesWidget = PluginWidget("ColorProperties")
local settingsWidget = PluginWidget("Settings")

local colorEditorButton = PluginToolbar.ColorEditorButton
local gradientEditorButton = PluginToolbar.ColorSequenceEditorButton
local colorPropertiesButton = PluginToolbar.ColorPropertiesButton
local settingsButton = PluginToolbar.SettingsButton

local colorPropertiesTree
local settingsTree
local colorEditPromise
local gradientEditPromise

local noOp = function() end

local uiTranslations = Translator.GenerateTranslationTable({
    "ColorProperties_WindowTitle",
    "FirstTimeSetup_WindowTitle",

    "APIInjectionConflict_Message",
    "AutoLoadColorPropertiesFailure_Message",
})

local injectAPI = function()
    local success = pcall(function()
        APIScript.Parent = StudioService
    end)

    return success
end

local mountSettings = function()
    settingsTree = Roact.mount(Roact.createElement(RoactRodux.StoreProvider, {
        store = Store,
    }, {
        App = Roact.createElement(Settings)
    }), settingsWidget)

    settingsWidget.Enabled = true
    settingsButton:SetActive(true)
end

local unmountSettings = function()
    Roact.unmount(settingsTree)
    settingsTree = nil

    settingsWidget.Enabled = false
    settingsButton:SetActive(false)
end

local mountColorProperties = function()
    colorPropertiesTree = Roact.mount(Roact.createElement(RoactRodux.StoreProvider, {
        store = Store,
    }, {
        App = Roact.createElement(ColorProperties)
    }), colorPropertiesWidget)

    colorPropertiesWidget.Enabled = true
    colorPropertiesButton:SetActive(true)
end

local unmountColorProperties = function()
    Roact.unmount(colorPropertiesTree)
    colorPropertiesTree = nil

    colorPropertiesWidget.Enabled = false
    colorPropertiesButton:SetActive(false)
end

---

APIScript.Archivable = false
APIScript.Name = "ColorPane"

colorEditorButton.ClickableWhenViewportHidden = true
gradientEditorButton.ClickableWhenViewportHidden = true

ColorPane.init(plugin)

if (StudioService:FindFirstChild("ColorPane")) then
    warn("[ColorPane] " .. uiTranslations["APIInjectionConflict_Message"])
end

if (not PluginSettings.Get(PluginEnums.PluginSettingKey.FirstTimeSetup)) then
    local firstTimeSetupWidget = PluginWidget("FirstTimeSetup")
    local firstTimeSetupWidgetEnabledChanged
    local firstTimeSetupTree
    local confirmSignal: Signal.Signal<nil>, fireConfirm: Signal.FireSignal<nil> = Signal.createSignal()

    firstTimeSetupWidgetEnabledChanged = firstTimeSetupWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
        if (not firstTimeSetupWidget.Enabled) then
            firstTimeSetupWidget.Enabled = true
        end
    end)

    firstTimeSetupTree = Roact.mount(Roact.createElement(RoactRodux.StoreProvider, {
        store = Store,
    }, {
        App = Roact.createElement(FirstTimeSetup, {
            onConfirm = function()
                firstTimeSetupWidgetEnabledChanged:Disconnect()
                firstTimeSetupWidget.Enabled = false
                Roact.unmount(firstTimeSetupTree)

                PluginSettings.Set(PluginEnums.PluginSettingKey.FirstTimeSetup, true)
                fireConfirm()
            end,
        })
    }), firstTimeSetupWidget)

    firstTimeSetupWidget.Title = uiTranslations["FirstTimeSetup_WindowTitle"]
    firstTimeSetupWidget.Enabled = true

    local confirmed: boolean = false
    local subscription: Signal.Subscription
    subscription = confirmSignal:subscribe(function()
        subscription:unsubscribe()
        confirmed = true
    end)

    repeat
        RunService.Heartbeat:Wait()
    until (confirmed)
end

do
    local success = injectAPI()

    if (not success) then
        warn("[ColorPane] " .. uiTranslations["APIInjectionFailure_Message"])
    end
end

if (PluginSettings.Get(PluginEnums.PluginSettingKey.AutoCheckForUpdate)) then
    UpdateChecker.SetupAutoCheck()
end

if (PluginSettings.Get(PluginEnums.PluginSettingKey.AutoLoadColorProperties)) then
    local startupRequestFinished
    startupRequestFinished = RobloxAPI.DataRequestFinished:subscribe(function(success: boolean)
        startupRequestFinished:Disconnect()
        startupRequestFinished = nil

        if ((not success) and RunService:IsEdit()) then
            warn("[ColorPane] " .. uiTranslations["AutoLoadColorPropertiesFailure_Message"])
        end
    end)

    RobloxAPI.GetData()
end

if (colorPropertiesWidget.Enabled) then
    mountColorProperties()
end

UpdateChecker.Check()

---

colorEditorButton.Click:Connect(function()
    if (colorEditPromise) then
        colorEditPromise:cancel()
        colorEditPromise = nil
        return
    end

    colorEditorButton:SetActive(true)
    colorEditPromise = ColorPane.PromptForColor()

    colorEditPromise:catch(noOp):finally(function()
        colorEditPromise = nil
        colorEditorButton:SetActive(false)
    end)
end)

gradientEditorButton.Click:Connect(function()
    if (gradientEditPromise) then
        gradientEditPromise:cancel()
        gradientEditPromise = nil
        return
    end

    gradientEditorButton:SetActive(true)
    gradientEditPromise = ColorPane.PromptForGradient()

    gradientEditPromise:catch(noOp):finally(function()
        gradientEditPromise = nil
        gradientEditorButton:SetActive(false)
    end)
end)

colorPropertiesButton.Click:Connect(function()
    if (colorPropertiesTree) then
        unmountColorProperties()
    else
        mountColorProperties()
    end
end)

settingsButton.Click:Connect(function()
    if (settingsTree) then
        unmountSettings()
    else
        mountSettings()
    end
end)

colorPropertiesWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
    if ((not colorPropertiesWidget.Enabled) and colorPropertiesTree) then
        unmountColorProperties()
    elseif (colorPropertiesWidget.Enabled and (not colorPropertiesTree)) then
        mountColorProperties()
    end
end)

settingsWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
    if ((not settingsWidget.Enabled) and settingsTree) then
        unmountSettings()
    elseif (settingsWidget.Enabled and (not settingsTree)) then
        mountSettings()
    end
end)

plugin.Unloading:Connect(function()
    if (settingsTree) then
        unmountSettings()
    end

    if (colorPropertiesTree) then
        unmountColorProperties()
    end
end)