local root = script.Parent.Parent
local includes = root:FindFirstChild("includes")

local Signal = require(includes:FindFirstChild("GoodSignal"))

---

return {
    InputBegan = Signal.new(),
    InputChanged = Signal.new(),
    InputEnded = Signal.new(),
}