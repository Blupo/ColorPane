local RunService = game:GetService("RunService")

---

local PluginModules = script.Parent
local ReleaseVersion = require(PluginModules:FindFirstChild("ReleaseVersion"))

---

local ASSET_ID = 6474565567

local sessionNotificationShown = false

---

local UpdateChecker = {}

UpdateChecker.Check = function()
    if (not RunService:IsEdit()) then return end
    if (sessionNotificationShown) then return end

    local fetchSuccess, data = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(ASSET_ID))
    end)

    if (not fetchSuccess) then
        warn("[ColorPane] Could not check for updates, got an error: " .. data)
        return
    end

    local latestPlugin = data[1]
    if (not latestPlugin) then return end

    local latestPluginModules = latestPlugin:FindFirstChild("PluginModules")
    local latestReleaseVersionScript = latestPluginModules:FindFirstChild("ReleaseVersion")

    -- default to v0.0.0 for versions before v0.3
    local latestReleaseVersion = latestReleaseVersionScript and require(latestReleaseVersionScript) or {0, 0, 0}

    local releaseMajor, latestReleaseMajor = ReleaseVersion[1], latestReleaseVersion[1]
    local releaseMinor, latestReleaseMinor = ReleaseVersion[2], latestReleaseVersion[2]
    local releasePatch, latestReleasePatch = ReleaseVersion[3], latestReleaseVersion[3]

    if ((latestReleaseMajor > releaseMajor) or (latestReleaseMinor > releaseMinor) or (latestReleasePatch > releasePatch)) then
        warn("[ColorPane] A new version of ColorPane is available, please update at your earliest convenience.")
        sessionNotificationShown = true
    end
end

return UpdateChecker