local RunService = game:GetService("RunService")

---

local root = script.Parent.Parent
local includes = root:FindFirstChild("includes")

local Signal = require(includes:FindFirstChild("GoodSignal"))

---

local EditorInputSignals = {
    ColorEditor = {},
    GradientEditor = {},
}

EditorInputSignals.ColorEditor.InputBegan = Signal.new()
EditorInputSignals.ColorEditor.InputEnded = Signal.new()
EditorInputSignals.ColorEditor.CursorPositionChanged = Signal.new()
EditorInputSignals.GradientEditor.CursorPositionChanged = Signal.new()

EditorInputSignals.initEditorCursorPositionChanged = function(plugin: Plugin, pluginWidget: DockWidgetPluginGui, editor: string)
    local lastPosition = Vector2.new()
    local cursorPositionChangedEvent = EditorInputSignals[editor].CursorPositionChanged

    local heartbeat = RunService.Heartbeat:Connect(function()
        local position = pluginWidget:GetRelativeMousePosition()
        if (position == lastPosition) then return end

        lastPosition = position
        cursorPositionChangedEvent:Fire(position)
    end)

    plugin.Unloading:Connect(function()
        heartbeat:Disconnect()
    end)
end

---

return EditorInputSignals