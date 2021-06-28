local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

---

local root = script.Parent.Parent

local includes = root:FindFirstChild("includes")
local Promise = require(includes:FindFirstChild("Promise"))

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))

---

local SETTINGS_KEY = "ColorPane_Settings"
local SESSION_LOCK_KEY = "ColorPane_SessionLock"

local DEFAULTS = {
    [PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation] = true,
    [PluginEnums.PluginSettingKey.SnapValue] = 0.1/100,
    [PluginEnums.PluginSettingKey.AutoLoadAPI] = false,
    [PluginEnums.PluginSettingKey.AutoLoadColorProperties] = false,
    [PluginEnums.PluginSettingKey.AutoCheckForUpdate] = true,
    [PluginEnums.PluginSettingKey.UserPalettes] = {},
    [PluginEnums.PluginSettingKey.AutoSave] = true,
    [PluginEnums.PluginSettingKey.AutoSaveInterval] = 5,
}

---

local plugin
local pluginSettings
local autoSavePromise
local lastScheduleTime = 0
local settingsModified = false

local sessionId = HttpService:GenerateGUID(false)
local settingChangedEvent = Instance.new("BindableEvent")

local scheduleAutoSave

---

local PluginSettings = {}
PluginSettings.SettingChanged = settingChangedEvent.Event

PluginSettings.Get = function(key)
    return pluginSettings[key]
end

PluginSettings.Set = function(key, newValue)
    if (pluginSettings[key] == newValue) then return end

    pluginSettings[key] = newValue
    settingsModified = true
    settingChangedEvent:Fire(key, newValue)

    if (key == PluginEnums.PluginSettingKey.AutoSave) then
        if (newValue) then
            scheduleAutoSave()
        else
            autoSavePromise:cancel()
            autoSavePromise = nil
        end
    elseif (key == PluginEnums.PluginSettingKey.AutoSaveInterval) then
        if (autoSavePromise) then
            autoSavePromise:cancel()

            if ((os.clock() - lastScheduleTime) >= newValue) then
                PluginSettings.Flush()
            end
            
            scheduleAutoSave()
        end
    end
end

PluginSettings.Flush = function()
    if (not settingsModified) then return end
    if (not RunService:IsEdit()) then return end

    local sessionLockId = plugin:GetSetting(SESSION_LOCK_KEY)
    
    if (sessionLockId == nil) then
        plugin:SetSetting(SESSION_LOCK_KEY, sessionId)
    elseif (sessionLockId ~= sessionId) then
        return
    end

    plugin:SetSetting(SETTINGS_KEY, pluginSettings)
    settingsModified = false
end

PluginSettings.init = function(initPlugin)
    PluginSettings.init = nil

    plugin = initPlugin
    pluginSettings = plugin:GetSetting(SETTINGS_KEY) or {}

    if (RunService:IsEdit()) then
        local sessionLockId = plugin:GetSetting(SESSION_LOCK_KEY)

        if (sessionLockId == nil) then
            plugin:SetSetting(SESSION_LOCK_KEY, sessionId)
        else
            warn("The ColorPane save data is locked by another session. You will need to close the other session(s) to save settings and palettes.")
        end
    end

    do
        -- Migrate old settings (before v0.2)
        local oldPalettes, oldSnap = PluginSettings.Get("palettes"), PluginSettings.Get("snap")
    
        if (oldPalettes) then
            PluginSettings.Set(PluginEnums.PluginSettingKey.UserPalettes, oldPalettes)
            PluginSettings.Set("palettes", nil)
        end
    
        if (oldSnap) then
            PluginSettings.Set(PluginEnums.PluginSettingKey.SnapValue, oldSnap)
            PluginSettings.Set("snap", nil)
        end
    
        if (oldPalettes or oldSnap) then
            PluginSettings.Flush()
        end
    end

    for key, defaultValue in pairs(DEFAULTS) do
        if (pluginSettings[key] == nil) then
            pluginSettings[key] = defaultValue
            settingsModified = true
        end
    end

    if (pluginSettings[PluginEnums.PluginSettingKey.AutoSave]) then
        scheduleAutoSave()
    end

    plugin.Unloading:Connect(function()
        local sessionLockId = plugin:GetSetting(SESSION_LOCK_KEY)

        autoSavePromise:cancel()
        settingChangedEvent:Destroy()
        PluginSettings.Flush()

        if (sessionLockId == sessionId) then
            plugin:SetSetting(SESSION_LOCK_KEY, nil)
        end
    end)
end

---

scheduleAutoSave = function()
    if (not pluginSettings) then return end
    if (not pluginSettings[PluginEnums.PluginSettingKey.AutoSave]) then return end

    lastScheduleTime = os.clock()
    autoSavePromise = Promise.delay(pluginSettings[PluginEnums.PluginSettingKey.AutoSaveInterval] * 60)

    autoSavePromise:andThen(function()
        PluginSettings.Flush()
        scheduleAutoSave()
    end)
end

return PluginSettings