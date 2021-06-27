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

    local objects = game:GetObjects("rbxassetid://" .. tostring(ASSET_ID))
    local latestPlugin = objects[1]
    if (not latestPlugin) then return end

    local latestPluginModules = latestPlugin:FindFirstChild("PluginModules")
    local latestReleaseVersionScript = latestPluginModules:FindFirstChild("ReleaseVersion")

    -- default to v0.0.0 for versions before v0.3
    local latestReleaseVersion = latestReleaseVersionScript and require(latestReleaseVersionScript) or {0, 0, 0}

    local releaseMajor, latestReleaseMajor = ReleaseVersion[1], latestReleaseVersion[1]
    local releaseMinor, latestReleaseMinor = ReleaseVersion[2], latestReleaseVersion[2]
    local releasePatch, latestReleasePatch = ReleaseVersion[3], latestReleaseVersion[3]

    if ((latestReleaseMajor > releaseMajor) or (latestReleaseMinor > releaseMinor) or (latestReleasePatch > releasePatch)) then
        if (sessionNotificationShown) then return end

        warn(string.format(
            "A new version of ColorPane is available: v%d.%d.%d; you're currently using v%d.%d.%d",
            latestReleaseMajor, latestReleaseMinor, latestReleasePatch,
            releaseMajor, releaseMinor, releasePatch
        ))

        sessionNotificationShown = true
    end
end

return UpdateChecker