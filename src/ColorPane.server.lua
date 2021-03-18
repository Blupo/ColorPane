local CoreGui = game:GetService("CoreGui")

---

local root = script.Parent
local APIScript = root:FindFirstChild("API")

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local PluginModules = root:FindFirstChild("PluginModules")
local MakeStore = require(PluginModules:FindFirstChild("MakeStore"))
local MakeToolbar = require(PluginModules:FindFirstChild("MakeToolbar"))
local MakeWidget = require(PluginModules:FindFirstChild("MakeWidget"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local PluginSettings = require(PluginModules:FindFirstChild("PluginSettings"))
local RobloxAPI = require(PluginModules:FindFirstChild("RobloxAPI"))
local SelectionManager = require(PluginModules:FindFirstChild("SelectionManager"))

local Components = root:FindFirstChild("Components")
local ColorProperties = require(Components:FindFirstChild("ColorProperties"))
local Settings = require(Components:FindFirstChild("Settings"))

PluginSettings.init(plugin)
RobloxAPI.init(plugin)
SelectionManager.init(plugin)

---

local ColorPane = require(PluginModules:FindFirstChild("APIBroker"))

local colorPaneStore = MakeStore(plugin)
local colorPropertiesWidget = MakeWidget(plugin, "ColorProperties")
local settingsWidget = MakeWidget(plugin, "Settings")

local toolbarComponents = MakeToolbar(plugin)
local colorEditorButton = toolbarComponents.ColorEditorButton
local colorPropertiesButton = toolbarComponents.ColorPropertiesButton
local loadAPIButton = toolbarComponents.LoadAPIButton
local settingsButton = toolbarComponents.SettingsButton

local colorPropertiesTree
local settingsTree
local colorEditPromise

local loadAPI = function()
    local success = pcall(function()
        APIScript.Parent = CoreGui
    end)

    if (success) then
        loadAPIButton.Enabled = false
    end

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

    colorPropertiesWidget.Title = "Color Properties"
    colorPropertiesWidget.Enabled = true
    colorPropertiesButton:SetActive(true)
end

local unmountColorProperties = function()
    Roact.unmount(colorPropertiesTree)
    colorPropertiesTree = nil

    colorPropertiesWidget.Enabled = false
    colorPropertiesWidget.Title = "ColorPane Color Properties"
    colorPropertiesButton:SetActive(false)
end

---

ColorPane.init(plugin)

if (CoreGui:FindFirstChild("ColorPane")) then
    warn("ColorPane is already loaded")
end

if (PluginSettings.Get(PluginEnums.PluginSettingKey.AutoLoadAPI)) then
    local success = loadAPI()

    if (not success) then
        warn("The ColorPane API could not be automatically loaded. Please make sure that you have allowed script injection and try again.")
    end
end

if (PluginSettings.Get(PluginEnums.PluginSettingKey.AutoLoadColorProperties)) then
    local startupRequestFinished
    startupRequestFinished = RobloxAPI.DataRequestFinished:Connect(function(success)
        startupRequestFinished:Disconnect()

        if (not success) then
            warn("The Color Properties window could not be automatically loaded. Please make sure that you have allowed HTTP requests for setup.rbxcdn.com and try again.")
        end
    end)

    RobloxAPI.GetData()
    mountColorProperties()
end

loadAPIButton.Click:Connect(loadAPI)

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

APIScript.Archivable = false
APIScript.Name = "ColorPane"

colorEditorButton.ClickableWhenViewportHidden = true
loadAPIButton.ClickableWhenViewportHidden = true