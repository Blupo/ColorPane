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
    local lastestReleaseVersionScript = latestPluginModules:FindFirstChild("ReleaseVersion")

    -- default to v0.0.0 for old versions (before v0.3)
    local lastestReleaseVersion = lastestReleaseVersionScript and require(lastestReleaseVersionScript) or {0, 0, 0}

    local releaseMajor, latestReleaseMajor = ReleaseVersion[1], lastestReleaseVersion[1]
    local releaseMinor, lastestReleaseMinor = ReleaseVersion[2], lastestReleaseVersion[2]
    local releasePatch, lastestReleasePatch = ReleaseVersion[3], lastestReleaseVersion[3]

    if ((latestReleaseMajor > releaseMajor) or (lastestReleaseMinor > releaseMinor) or (lastestReleasePatch > releasePatch)) then
        if (sessionNotificationShown) then return end

        warn(string.format(
            "A new version of ColorPane is available: v%d.%d.%d; you're currently using v%d.%d.%d",
            latestReleaseMajor, lastestReleaseMinor, lastestReleasePatch,
            releaseMajor, releaseMinor, releasePatch
        ))

        sessionNotificationShown = true
    end
end

return UpdateChecker