--!strict

local HttpService: HttpService = game:GetService("HttpService")

---

return {
    Id = HttpService:GenerateGUID(),
    Version = {0, 5, 0},
}