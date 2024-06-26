--!strict

local RunService: RunService = game:GetService("RunService")

---

local root = script.Parent
local Common = root.Common

local CommonModules = Common.Modules
require(CommonModules.PluginProvider)(plugin)
local Translator = require(CommonModules.Translator)
local Window = require(CommonModules.Window)

local CommonIncludes = Common.Includes
local Roact = require(CommonIncludes.RoactRodux.Roact)

local Components = root.Components
local Settings = require(Components.Settings)
local ColorProperties = require(Components.ColorProperties)

local Modules = root.Modules
require(Modules.ColorPaneUserDataInterface)
local Enums = require(Modules.Enums)
local ManagedUserData = require(Modules.ManagedUserData)
local ColorPane = require(Modules.ColorPane)
local RobloxAPI = require(Modules.RobloxAPI)
local Store = require(Modules.Store)
local Toolbar = require(Modules.Toolbar)
local WidgetInfo = require(Modules.WidgetInfo)

---

local colorEditPromise: typeof(ColorPane.PromptForColor())?
local gradientEditPromise: typeof(ColorPane.PromptForGradient())?

local colorPropertiesWindow: Window.Window = Window.new(WidgetInfo.ColorProperties.Id, WidgetInfo.ColorProperties.Info)
local settingsWindow: Window.Window = Window.new(WidgetInfo.Settings.Id, WidgetInfo.Settings.Info)

---

Toolbar.ColorEditButton.ClickableWhenViewportHidden = true
Toolbar.GradientEditButton.ClickableWhenViewportHidden = true

if (ManagedUserData.Companion:getValue(Enums.CompanionUserDataKey.AutoLoadColorPropertiesAPIData)) then
    local startupRequestFinished
    startupRequestFinished = RobloxAPI.DataRequestFinished:subscribe(function(success: boolean)
        startupRequestFinished:unsubscribe()

        if ((not success) and RunService:IsEdit()) then
            warn(Translator.FormatByKey("AutoLoadColorPropertiesFailure_Message"))
        end
    end)

    RobloxAPI.GetData()
end

if (colorPropertiesWindow:isOpen()) then
    colorPropertiesWindow:mount(Translator.FormatByKey("ColorProperties_WindowTitle"), Roact.createElement(ColorProperties), Store)
    Toolbar.ColorPropertiesButton:SetActive(true)
end

Toolbar.ColorEditButton.Click:Connect(function()
    if (colorEditPromise) then
        colorEditPromise:cancel()
        colorEditPromise = nil
        return
    end

    if (ColorPane.IsColorPromptAvailable()) then
        local editPromise = ColorPane.PromptForColor()

        editPromise:catch(function() end):finally(function()
            colorEditPromise = nil
            Toolbar.ColorEditButton:SetActive(false)
        end)
    
        colorEditPromise = editPromise
        Toolbar.ColorEditButton:SetActive(true)
    else
        Toolbar.ColorEditButton:SetActive(false)
    end
end)

Toolbar.GradientEditButton.Click:Connect(function()
    if (gradientEditPromise) then
        gradientEditPromise:cancel()
        gradientEditPromise = nil
        return
    end

    if (ColorPane.IsGradientPromptAvailable()) then
        local editPromise = ColorPane.PromptForGradient()

        editPromise:catch(function() end):finally(function()
            gradientEditPromise = nil
            Toolbar.GradientEditButton:SetActive(false)
        end)

        gradientEditPromise = editPromise
        Toolbar.GradientEditButton:SetActive(true)
    else
        Toolbar.GradientEditButton:SetActive(false)
    end
end)

Toolbar.ColorPropertiesButton.Click:Connect(function()
    if (colorPropertiesWindow:isMounted()) then
        colorPropertiesWindow:unmount()
        Toolbar.ColorPropertiesButton:SetActive(false)
    else
        colorPropertiesWindow:mount(Translator.FormatByKey("ColorProperties_WindowTitle"), Roact.createElement(ColorProperties), Store)
        Toolbar.ColorPropertiesButton:SetActive(true)
    end
end)

Toolbar.SettingsButton.Click:Connect(function()
    if (settingsWindow:isMounted()) then
        settingsWindow:unmount()
        Toolbar.SettingsButton:SetActive(false)
    else
        settingsWindow:mount(Translator.FormatByKey("Settings_WindowTitle"), Roact.createElement(Settings), Store)
        Toolbar.SettingsButton:SetActive(true)
    end
end)

colorPropertiesWindow.openedWithoutMounting:subscribe(function()
    colorPropertiesWindow:close()
end)

colorPropertiesWindow.closedWithoutUnmounting:subscribe(function()
    colorPropertiesWindow:unmount()
    Toolbar.ColorPropertiesButton:SetActive(false)
end)

settingsWindow.openedWithoutMounting:subscribe(function()
    settingsWindow:close()
end)

settingsWindow.closedWithoutUnmounting:subscribe(function()
    settingsWindow:unmount()
    Toolbar.SettingsButton:SetActive(false)
end)

plugin.Unloading:Connect(function()
    colorPropertiesWindow:destroy()
    settingsWindow:destroy()

    if (colorEditPromise) then
        colorEditPromise:cancel()
        colorEditPromise = nil
    end

    if (gradientEditPromise) then
        gradientEditPromise:cancel()
        gradientEditPromise = nil
    end
end)