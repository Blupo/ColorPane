--!strict
-- Creates windows for prompts

local Common = script.Parent.Parent

local Includes = Common.Includes
local Roact = require(Includes.RoactRodux.Roact)
local Signal = require(Includes.Signal)

local PluginModules = script.Parent
local Window = require(PluginModules.Window)

local CommonComponents = Common.Components
local PromptComponent = require(CommonComponents.Prompt)

---

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

    local promptElement = Roact.createElement(PromptComponent, {
        promptText = promptInfo.PromptText,
        cancelText = promptInfo.CancelText or "Cancel",
        confirmText = promptInfo.ConfirmText or "Confirm",

        onDone = function(confirm)
            firePromptClosed(confirm)
            window:destroy()
        end,
    })

    openedWithoutMounting = window.openedWithoutMounting:subscribe(function()
        -- window shouldn't exist without tree
        openedWithoutMounting:unsubscribe()
        window:destroy()
    end)

    closedWithoutUnmounting = window.closedWithoutUnmounting:subscribe(function()
        -- this is the same as cancelling
        closedWithoutUnmounting:unsubscribe()
        firePromptClosed(false)
        window:destroy()
    end)

    window:mount(promptInfo.Title, promptElement, store)
    return promptClosed
end