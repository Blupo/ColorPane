local root = script.Parent.Parent
local includes = root:FindFirstChild("includes")

local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

---

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,
    }
end)