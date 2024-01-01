local RoactRodux = require(script.Parent.Parent.includes.RoactRodux)

---

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,
    }
end)