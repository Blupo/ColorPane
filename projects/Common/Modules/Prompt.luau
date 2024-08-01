--!strict
-- Creates windows for prompts

local Common = script.Parent.Parent

local Includes = Common.Includes
local Roact = require(Includes.RoactRodux.Roact)
local Signal = require(Includes.Signal)

local Modules = script.Parent
local PluginProvider = require(Modules.PluginProvider)
local Translator = require(Modules.Translator)
local Window = require(Modules.Window)

local CommonComponents = Common.Components
local PromptComponent = require(CommonComponents.Prompt)

---

local plugin: Plugin = PluginProvider()

local UI_TRANSLATIONS = Translator.GenerateTranslationTable({
    "Cancel_ButtonText",
    "Confirm_ButtonText",
})

--[[
    @param Title The title for the prompt window
    @param PromptText The text for the body of the prompt
    @param CancelText (Optional) The text for the cancel button
    @param ConfirmText (Optional) The text for the confirm button
]]
type PromptInfo = {
    Title: string,
    PromptText: string,
    CancelText: string?,
    ConfirmText: string?,
}

--[[
    Creates a one-time prompt to take or avoid an action.

    @param id The prompt window ID
    @param widgetInfo The prompt window info
    @param promptInfo The prompt information
    @return A signal that will fire when the prompt is closed
]]
return function(id: string, widgetInfo: DockWidgetPluginGuiInfo, promptInfo: PromptInfo, store)
    local window: Window.Window = Window.new(id, widgetInfo)
    local promptClosed: Signal.Signal<boolean>, firePromptClosed: Signal.FireSignal<boolean> = Signal.createSignal()

    local openedWithoutMounting: Signal.Subscription
    local closedWithoutUnmounting: Signal.Subscription
    local promptClosedCleanup: Signal.Subscription

    local cleanup = function()
        promptClosedCleanup:unsubscribe()
        openedWithoutMounting:unsubscribe()
        closedWithoutUnmounting:unsubscribe()
        window:destroy()
    end

    promptClosedCleanup = promptClosed:subscribe(cleanup)
    openedWithoutMounting = window.openedWithoutMounting:subscribe(cleanup)

    closedWithoutUnmounting = window.closedWithoutUnmounting:subscribe(function()
        firePromptClosed(false)
    end)

    plugin.Unloading:Connect(function()
        if (window:isMounted()) then
            firePromptClosed(false)
        else
            cleanup()
        end
    end)

    window:mount(
        promptInfo.Title,
        Roact.createElement(PromptComponent, {
            promptText = promptInfo.PromptText,
            cancelText = promptInfo.CancelText or UI_TRANSLATIONS["Cancel_ButtonText"],
            confirmText = promptInfo.ConfirmText or UI_TRANSLATIONS["Confirm_ButtonText"],
            onDone = firePromptClosed,
        }),
        store
    )

    return promptClosed
end