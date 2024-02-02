local StandardComponents = {}

---

local children = script:GetChildren()

for i = 1, #children do
    local child = children[i]

    StandardComponents[child.Name] = require(child)
end

---

return StandardComponents