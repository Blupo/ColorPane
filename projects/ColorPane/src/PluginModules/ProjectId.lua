--!strict
-- Provides the project ID

local HttpService: HttpService = game:GetService("HttpService")

---

local id: string = HttpService:GenerateGUID(false)

--[[
    Provides the project ID.

    @param newId The ID for this project
    @return The ID for this project
]]
return function(newId: string?): string
    if (newId) then
        id = newId
    end

    return id
end