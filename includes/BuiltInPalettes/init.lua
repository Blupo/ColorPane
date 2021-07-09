local BuiltInPalettes = {}

---

local children = script:GetChildren()

for i = 1, #children do
    local child = children[i]

    BuiltInPalettes[child.Name] = require(child)
end

---

return BuiltInPalettes