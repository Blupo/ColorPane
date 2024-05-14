-- Allows components to use theme coloring
-- This is a (higher-order) component, so it should stay in the Components folder

local RoactRodux = require(script.Parent.Parent.Includes.RoactRodux.RoactRodux)

---

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,
    }
end)