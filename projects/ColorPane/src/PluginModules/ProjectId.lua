--!strict
-- Provides the project ID

local HttpService: HttpService = game:GetService("HttpService")

---

local id: string? = nil

--[[
    Provides the project ID.

    If called with an ID, it will be stored for future use.
    If an ID has already been stored, the function will throw an error.
    
    If called without an ID, it will return the stored ID.
    If an ID has not been stored, the function will set the project ID
        to a random UUID and return that.

    @param newId The ID for this project (optional)
    @return The ID for this project
]]
return function(newId: string?): string
    if (not newId) then
        if (id) then
            return id
        else
            local randomId: string = HttpService:GenerateGUID(false)

            id = randomId
            return randomId
        end
    else
        if (id) then
            error("Project ID already stored")
        end
    end

    id = newId
    return newId
end