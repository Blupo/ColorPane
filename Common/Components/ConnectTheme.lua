local RoactRodux = require(script.Parent.Parent.Includes.RoactRodux.RoactRodux)

---

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,
    }
end)