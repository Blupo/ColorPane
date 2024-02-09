--!strict

local RunService: RunService = game:GetService("RunService")

---

local root = script.Parent.Parent
local Common = root.Common

local CommonPluginModules = Common.PluginModules
local PluginProvider = require(CommonPluginModules.PluginProvider)

local CommonIncludes = Common.Includes
local Signal = require(CommonIncludes.Signal)

local PluginModules = root.PluginModules
local Util = require(PluginModules.Util)

---

type SignalTable<T> = {
    Event: Signal.Signal<T>,
    Fire: Signal.FireSignal<T>
}

local plugin: Plugin? = PluginProvider()
assert(plugin, Util.makeBugMessage("Plugin object is missing"))

-- set up signals
local colorEditorInputBeganSignal: Signal.Signal<InputObject>, fireColorEditorInputBegan: Signal.FireSignal<InputObject> = Signal.createSignal()
local colorEditorInputEndedSignal: Signal.Signal<InputObject>, fireColorEditorInputEnded: Signal.FireSignal<InputObject> = Signal.createSignal()
local colorEditorCursorPositionChangedSignal: Signal.Signal<Vector2>, fireColorEditorCursorPositionChanged: Signal.FireSignal<Vector2> = Signal.createSignal()
local gradientEditorCursorPositionChangedSignal: Signal.Signal<Vector2>, fireGradientEditorCursorPositionChanged: Signal.FireSignal<Vector2> = Signal.createSignal()

local EditorInputSignals = {
    ColorEditor = {},
    GradientEditor = {},
}

EditorInputSignals.ColorEditor.CursorPositionChanged = colorEditorCursorPositionChangedSignal
EditorInputSignals.GradientEditor.CursorPositionChanged = gradientEditorCursorPositionChangedSignal

EditorInputSignals.ColorEditor.InputBegan = {
    Event = colorEditorInputBeganSignal,
    Fire = fireColorEditorInputBegan,
}

EditorInputSignals.ColorEditor.InputEnded = {
    Event = colorEditorInputEndedSignal,
    Fire = fireColorEditorInputEnded,
}

-- let plugin widgets send mouse position through signals
EditorInputSignals.initEditorCursorPositionChanged = function(pluginWidget: DockWidgetPluginGui, editor: "ColorEditor" | "GradientEditor")
    local lastPosition: Vector2 = Vector2.new()
    local fireCursorPositionChanged: Signal.FireSignal<Vector2>

    if (editor == "ColorEditor") then
        fireCursorPositionChanged = fireColorEditorCursorPositionChanged
    elseif (editor == "GradientEditor") then
        fireCursorPositionChanged = fireGradientEditorCursorPositionChanged
    end

    local heartbeat: RBXScriptConnection = RunService.Heartbeat:Connect(function()
        local position: Vector2 = pluginWidget:GetRelativeMousePosition()
        if (position == lastPosition) then return end

        lastPosition = position
        fireCursorPositionChanged(position)
    end)

    plugin.Unloading:Connect(function()
        heartbeat:Disconnect()
    end)
end

---

return EditorInputSignals