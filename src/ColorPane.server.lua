local StudioService = game:GetService("StudioService")
local RunService = game:GetService("RunService")

---

local root = script.Parent
local APIScript = root:FindFirstChild("API")

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))
local Signal = require(includes:FindFirstChild("Signal"))

local PluginModules = root:FindFirstChild("PluginModules")
local DocumentationPluginMenu = require(PluginModules:FindFirstChild("DocumentationPluginMenu"))
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
DocumentationPluginMenu.init(plugin)
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
local gradientEditorButton = toolbarComponents.ColorSequenceEditorButton
local colorPropertiesButton = toolbarComponents.ColorPropertiesButton
local settingsButton = toolbarComponents.SettingsButton

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
gradientEditorButton.ClickableWhenViewportHidden = true

ColorPane.init(plugin)

if (StudioService:FindFirstChild("ColorPane")) then
    warn("[ColorPane] " .. uiTranslations["APIInjectionConflict_Message"])
end

if (not PluginSettings.Get(PluginEnums.PluginSettingKey.FirstTimeSetup)) then
    local firstTimeSetupWidget = MakeWidget(plugin, "FirstTimeSetup")
    local firstTimeSetupWidgetEnabledChanged
    local firstTimeSetupTree
    local confirmSignal: Signal.Signal<nil>, fireConfirm: Signal.FireSignal<nil> = Signal.createSignal()

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