local RunService: RunService = game:GetService("RunService")

---

local root = script.Parent.Parent

local includes = root.includes
local Promise = require(includes.Promise)

local PluginModules = root.PluginModules
local PluginEnums = require(PluginModules.PluginEnums)
local PluginSettings = require(PluginModules.PluginSettings)
local ReleaseVersion = require(PluginModules.ReleaseVersion)
local Translator = require(PluginModules.Translator)

---

local ASSET_ID: number = 6474565567
local AUTO_CHECK_INTERVAL: number = 5 * 60 -- in seconds

local sessionNotificationShown: boolean = false
local autoCheckPromise

---

local UpdateChecker = {}

UpdateChecker.Check = function()
    if (not RunService:IsEdit()) then return end
    if (sessionNotificationShown) then return end

    local fetchSuccess, data = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(ASSET_ID))
    end)

    if (not fetchSuccess) then
        warn("[ColorPane] " .. Translator.FormatByKey("UpdateCheckFailure_Message", { data }))
        return
    end

    local latestPlugin = data[1]
    if (not latestPlugin) then return end

    local latestPluginModules = latestPlugin.PluginModules
    local latestReleaseVersionScript = latestPluginModules.ReleaseVersion

    -- default to v0.0.0 for versions before v0.3
    local latestReleaseVersion = latestReleaseVersionScript and require(latestReleaseVersionScript) or {0, 0, 0}

    local releaseMajor, latestReleaseMajor = ReleaseVersion[1], latestReleaseVersion[1]
    local releaseMinor, latestReleaseMinor = ReleaseVersion[2], latestReleaseVersion[2]
    local releasePatch, latestReleasePatch = ReleaseVersion[3], latestReleaseVersion[3]

    if ((latestReleaseMajor > releaseMajor) or (latestReleaseMinor > releaseMinor) or (latestReleasePatch > releasePatch)) then
        warn("[ColorPane] " .. Translator.FormatByKey("NewVersionAvailable_Message"))
        sessionNotificationShown = true
    end
end

UpdateChecker.SetupAutoCheck = function()
    if ((not RunService:IsEdit()) or autoCheckPromise) then return end

    autoCheckPromise = Promise.delay(AUTO_CHECK_INTERVAL):andThen(function()
        autoCheckPromise = nil

        UpdateChecker.Check()
        UpdateChecker.SetupAutoCheck()
    end)
end

---

PluginSettings.SettingChanged:subscribe(function(setting)
    local key, newValue = setting.Key, setting.Value
    if (key ~= PluginEnums.PluginSettingKey.AutoCheckForUpdate) then return end

    if (newValue) then
        UpdateChecker.SetupAutoCheck()
    else
        if (autoCheckPromise) then
            autoCheckPromise:cancel()
            autoCheckPromise = nil
        end
    end
end)

return UpdateChecker