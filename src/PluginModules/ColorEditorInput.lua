local colorEditorInputBeganEvent = Instance.new("BindableEvent")
local colorEditorInputChangedEvent = Instance.new("BindableEvent")
local colorEditorInputEndedEvent = Instance.new("BindableEvent")

---

local ColorEditorInput = {}

ColorEditorInput.GetInputBindableEvents = function()
    return {
        InputBegan = colorEditorInputBeganEvent,
        InputChanged = colorEditorInputChangedEvent,
        InputEnded = colorEditorInputEndedEvent,
    }
end

ColorEditorInput.GetInputEventSignals = function()
    return {
        InputBegan = colorEditorInputBeganEvent.Event,
        InputChanged = colorEditorInputChangedEvent.Event,
        InputEnded = colorEditorInputEndedEvent.Event,
    }
end

ColorEditorInput.init = function(plugin)
    ColorEditorInput.init = nil

    plugin.Unloading:Connect(function()
        colorEditorInputBeganEvent:Destroy()
        colorEditorInputChangedEvent:Destroy()
        colorEditorInputEndedEvent:Destroy()
    end)
end

return ColorEditorInput