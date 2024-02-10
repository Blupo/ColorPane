--!strict
-- Provides the project ID

local HttpService: HttpService = game:GetService("HttpService")

---

local id: string = HttpService:GenerateGUID(false)

return function(newId: string?): string
    if (newId) then
        id = newId
    end

    return id
end