--!strict

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

local Includes = root.Includes
local InitColorPane = require(Includes.ColorPane)

local Modules = root.Modules
require(Modules.ManagedUserData)
local Store = require(Modules.Store)
local Toolbar = require(Modules.Toolbar)
require(Modules.UserDataInterface)
local WidgetInfo = require(Modules.WidgetInfo)

---

local ColorPane = InitColorPane(plugin, "ColorPane_Companion")

local colorEditPromise: typeof(ColorPane.PromptForColor())?
local gradientEditPromise: typeof(ColorPane.PromptForGradient())?

local settingsWindow: Window.Window = Window.new(WidgetInfo.Settings.Id, WidgetInfo.Settings.Info)

---

Toolbar.ColorEditButton.Click:Connect(function()
    if (colorEditPromise) then
        colorEditPromise:cancel()
        colorEditPromise = nil
        return
    end

    local editPromise = ColorPane.PromptForColor()
    local suppressedRejectionPromise = editPromise:catch(function() end)

    -- check that the promise doesn't immediately complete
    if (editPromise:getStatus() == ColorPane.PromiseStatus.Started) then
        suppressedRejectionPromise:finally(function()
            colorEditPromise = nil
            Toolbar.ColorEditButton:SetActive(false)
        end)
    
        colorEditPromise = editPromise
        Toolbar.ColorEditButton:SetActive(true)
    end
end)

Toolbar.GradientEditButton.Click:Connect(function()
    if (gradientEditPromise) then
        gradientEditPromise:cancel()
        gradientEditPromise = nil
        return
    end

    local editPromise = ColorPane.PromptForGradient()
    local suppressedRejectionPromise = editPromise:catch(function() end)

    -- check that the promise doesn't immediately complete
    if (editPromise:getStatus() == ColorPane.PromiseStatus.Started) then
        suppressedRejectionPromise:finally(function()
            gradientEditPromise = nil
            Toolbar.GradientEditButton:SetActive(false)
        end)

        gradientEditPromise = editPromise
        Toolbar.GradientEditButton:SetActive(true)
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

settingsWindow.openedWithoutMounting:subscribe(function()
    settingsWindow:close()
end)

settingsWindow.closedWithoutUnmounting:subscribe(function()
    settingsWindow:unmount()
    Toolbar.SettingsButton:SetActive(false)
end)

plugin.Unloading:Connect(function()
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