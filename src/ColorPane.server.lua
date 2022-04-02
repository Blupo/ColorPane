local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

---

local root = script.Parent
local APIScript = root:FindFirstChild("API")

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))
local Signal = require(includes:FindFirstChild("GoodSignal"))

local PluginModules = root:FindFirstChild("PluginModules")
local GradientInfoWidget = require(PluginModules:FindFirstChild("GradientInfoWidget"))
local GradientPaletteWidget = require(PluginModules:FindFirstChild("GradientPaletteWidget"))
local MakeStore = require(PluginModules:FindFirstChild("MakeStore"))
local MakeToolbar = require(PluginModules:FindFirstChild("MakeToolbar"))
local MakeWidget = require(PluginModules:FindFirstChild("MakeWidget"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local PluginSettings = require(PluginModules:FindFirstChild("PluginSettings"))
local RepeatingCallback = require(PluginModules:FindFirstChild("RepeatingCallback"))
local RobloxAPI = require(PluginModules:FindFirstChild("RobloxAPI"))
local SelectionManager = require(PluginModules:FindFirstChild("SelectionManager"))
local Translator = require(PluginModules:FindFirstChild("Translator"))
local UpdateChecker = require(PluginModules:FindFirstChild("UpdateChecker"))

local Components = root:FindFirstChild("Components")
local ColorProperties = require(Components:FindFirstChild("ColorProperties"))
local FirstTimeSetup = require(Components:FindFirstChild("FirstTimeSetup"))
local Settings = require(Components:FindFirstChild("Settings"))

PluginSettings.init(plugin) -- priority
GradientInfoWidget.init(plugin)
GradientPaletteWidget.init(plugin)
RepeatingCallback.init(plugin)
SelectionManager.init(plugin)

---

local ColorPane = require(PluginModules:FindFirstChild("APIBroker"))

local colorPaneStore = MakeStore(plugin)
local colorPropertiesWidget = MakeWidget(plugin, "ColorProperties")
local settingsWidget = MakeWidget(plugin, "Settings")

local toolbarComponents = MakeToolbar(plugin)
local colorEditorButton = toolbarComponents.ColorEditorButton
local csEditorButton = toolbarComponents.ColorSequenceEditorButton
local colorPropertiesButton = toolbarComponents.ColorPropertiesButton
local settingsButton = toolbarComponents.SettingsButton

local colorPropertiesTree
local settingsTree
local colorEditPromise
local csEditPromise

local uiTranslations = Translator.GenerateTranslationTable({
    "ColorProperties_WindowTitle",
    "FirstTimeSetup_WindowTitle",

    "APIInjectionConflict_Message",
    "AutoLoadColorPropertiesFailure_Message",
})

local injectAPI = function()
    local success = pcall(function()
        APIScript.Parent = CoreGui
    end)

    return success
end

local mountSettings = function()
    settingsTree = Roact.mount(Roact.createElement(RoactRodux.StoreProvider, {
        store = colorPaneStore,
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
        store = colorPaneStore,
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
csEditorButton.ClickableWhenViewportHidden = true

ColorPane.init(plugin)

if (CoreGui:FindFirstChild("ColorPane")) then
    warn("[ColorPane] " .. uiTranslations["APIInjectionConflict_Message"])
end

if (not PluginSettings.Get(PluginEnums.PluginSettingKey.FirstTimeSetup)) then
    local firstTimeSetupWidget = MakeWidget(plugin, "FirstTimeSetup")
    local firstTimeSetupWidgetEnabledChanged
    local firstTimeSetupTree
    local confirmSignal = Signal.new()

    firstTimeSetupWidgetEnabledChanged = firstTimeSetupWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
        if (not firstTimeSetupWidget.Enabled) then
            firstTimeSetupWidget.Enabled = true
        end
    end)

    firstTimeSetupTree = Roact.mount(Roact.createElement(RoactRodux.StoreProvider, {
        store = colorPaneStore,
    }, {
        App = Roact.createElement(FirstTimeSetup, {
            onConfirm = function()
                firstTimeSetupWidgetEnabledChanged:Disconnect()
                firstTimeSetupWidget.Enabled = false
                Roact.unmount(firstTimeSetupTree)

                PluginSettings.Set(PluginEnums.PluginSettingKey.FirstTimeSetup, true)
                confirmSignal:Fire()
            end,
        })
    }), firstTimeSetupWidget)

    firstTimeSetupWidget.Title = uiTranslations["FirstTimeSetup_WindowTitle"]
    firstTimeSetupWidget.Enabled = true

    confirmSignal:Wait()
end

do
    local success = injectAPI()

    if (not success) then
        warn("[ColorPane] " .. uiTranslations["APIInjectionFailure_Message"])
    end
end

if (PluginSettings.Get(PluginEnums.PluginSettingKey.AutoCheckForUpdate)) then
    UpdateChecker.Check()
end

if (PluginSettings.Get(PluginEnums.PluginSettingKey.AutoLoadColorProperties)) then
    local startupRequestFinished
    startupRequestFinished = RobloxAPI.DataRequestFinished:Connect(function(success)
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

---

colorEditorButton.Click:Connect(function()
    if (colorEditPromise) then
        colorEditPromise:cancel()
        colorEditPromise = nil

        return
    end

    colorEditPromise = ColorPane.PromptForColor()
    colorEditorButton:SetActive(true)

    colorEditPromise:finally(function()
        colorEditPromise = nil
        colorEditorButton:SetActive(false)
    end)
end)

csEditorButton.Click:Connect(function()
    if (csEditPromise) then
        csEditPromise:cancel()
        csEditPromise = nil

        return
    end

    csEditPromise = ColorPane.PromptForGradient()
    csEditorButton:SetActive(true)

    csEditPromise:finally(function()
        csEditPromise = nil
        csEditorButton:SetActive(false)
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