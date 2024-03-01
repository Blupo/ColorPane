--!strict
-- Provides a common set of signals for editor mouse input

local root = script.Parent.Parent
local Common = root.Common

local CommonIncludes = Common.Includes
local Signal = require(CommonIncludes.Signal)

---

local colorEditorInputBeganSignal: Signal.Signal<InputObject>,
    fireColorEditorInputBegan: Signal.FireSignal<InputObject> = Signal.createSignal()

local colorEditorInputEndedSignal: Signal.Signal<InputObject>,
    fireColorEditorInputEnded: Signal.FireSignal<InputObject> = Signal.createSignal()

local colorEditorMousePositionChanged: Signal.Signal<Vector2>,
    fireColorEditorMousePositionChanged: Signal.FireSignal<Vector2> = Signal.createSignal()

local gradientEditorMousePositionChanged: Signal.Signal<Vector2>,
    fireGradientEditorMousePositionChanged: Signal.FireSignal<Vector2> = Signal.createSignal()

---

local EditorInputSignals = {
    ColorEditor = {
        InputBegan = {
            Event = colorEditorInputBeganSignal,
            Fire = fireColorEditorInputBegan,
        },

        InputEnded = {
            Event = colorEditorInputEndedSignal,
            Fire = fireColorEditorInputEnded,
        },

        MousePositionChanged = {
            Event = colorEditorMousePositionChanged,
            Fire = fireColorEditorMousePositionChanged,
        },
    },

    GradientEditor = {
        MousePositionChanged = {
            Event = gradientEditorMousePositionChanged,
            Fire = fireGradientEditorMousePositionChanged,
        }
    },
}

---

return EditorInputSignals