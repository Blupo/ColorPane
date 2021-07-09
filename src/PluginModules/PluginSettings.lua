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
local API_CACHE_LAST_REFRESH_KEY = "ColorPane_RobloxAPICacheLastRefresh"
local API_CACHE_KEY = "ColorPane_RobloxAPICache"
local API_CACHE_REFRESH_TIME = 8 * 3600

local DEFAULTS = {
    [PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation] = true,
    [PluginEnums.PluginSettingKey.SnapValue] = 0.1/100,
    [PluginEnums.PluginSettingKey.AutoLoadAPI] = false,
    [PluginEnums.PluginSettingKey.AutoLoadColorProperties] = false,
    [PluginEnums.PluginSettingKey.AutoCheckForUpdate] = true,
    [PluginEnums.PluginSettingKey.UserPalettes] = {},
    [PluginEnums.PluginSettingKey.AutoSave] = true,
    [PluginEnums.PluginSettingKey.AutoSaveInterval] = 5,
    [PluginEnums.PluginSettingKey.CacheAPIData] = false,
    [PluginEnums.PluginSettingKey.UserColorSequences] = {},
    [PluginEnums.PluginSettingKey.ColorPropertiesLivePreview] = true,
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

PluginSettings.AcquireSessionLock = function(): boolean
    if (not RunService:IsEdit()) then return false end

    local sessionLockId = plugin:GetSetting(SESSION_LOCK_KEY)
    
    if (sessionLockId == nil) then
        plugin:SetSetting(SESSION_LOCK_KEY, sessionId)
        return true
    else
        return (sessionLockId == sessionId)
    end
end

PluginSettings.ReleaseSessionLock = function()
    if (not RunService:IsEdit()) then return false end

    plugin:SetSetting(SESSION_LOCK_KEY, nil)
end

PluginSettings.Get = function(key)
    return pluginSettings[key]
end

PluginSettings.Set = function(key, newValue)
    local hasLock = PluginSettings.AcquireSessionLock()
    if (not hasLock) then return end
    if (pluginSettings[key] == newValue) then return end

    pluginSettings[key] = newValue
    settingsModified = true

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

    settingChangedEvent:Fire(key, newValue)
end

PluginSettings.Flush = function()
    local hasLock = PluginSettings.AcquireSessionLock()
    if (not hasLock) then return end
    if (not settingsModified) then return end

    plugin:SetSetting(SETTINGS_KEY, pluginSettings)
    settingsModified = false
end

PluginSettings.GetCachedRobloxAPIData = function()
    if (not pluginSettings[PluginEnums.PluginSettingKey.CacheAPIData]) then return end

    local cachedAPIData = plugin:GetSetting(API_CACHE_KEY)
    if (not cachedAPIData) then return end

    return cachedAPIData
end

PluginSettings.CacheRobloxAPIData = function(api)
    if (not pluginSettings[PluginEnums.PluginSettingKey.CacheAPIData]) then return end

    plugin:SetSetting(API_CACHE_LAST_REFRESH_KEY, os.time())
    plugin:SetSetting(API_CACHE_KEY, api)
end

PluginSettings.ClearCachedRobloxAPIData = function()
    plugin:SetSetting(API_CACHE_LAST_REFRESH_KEY, nil)
    plugin:SetSetting(API_CACHE_KEY, nil)
end

PluginSettings.init = function(initPlugin)
    PluginSettings.init = nil

    plugin = initPlugin
    pluginSettings = plugin:GetSetting(SETTINGS_KEY) or {}

    if (RunService:IsEdit()) then
        local hasLock = PluginSettings.AcquireSessionLock()
        
        if (not hasLock) then
            warn(
                "[ColorPane] Data saving is locked to another session. You will need to close the other session(s) to modify settings and save palettes. " ..
                "If you don't have any other sessions open, you may need to reset the session lock (please consult the User Guide on how to do this)."
            )
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

    do
        local canCache = pluginSettings[PluginEnums.PluginSettingKey.CacheAPIData]
        local cachedAPIData = plugin:GetSetting(API_CACHE_KEY)
        local cachedAPIDataLastRefresh = plugin:GetSetting(API_CACHE_LAST_REFRESH_KEY) or 0

        if (cachedAPIData) then
            if ((not canCache) or (os.time() - cachedAPIDataLastRefresh) >= API_CACHE_REFRESH_TIME) then
                PluginSettings.ClearCachedRobloxAPIData()
            end
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