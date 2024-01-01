--!strict

local HttpService: HttpService = game:GetService("HttpService")
local RunService: RunService = game:GetService("RunService")

---

local root = script.Parent.Parent

local includes = root.includes
local Promise = require(includes.Promise)
local Signal = require(includes.Signal)

local PluginModules = root.PluginModules
local PluginEnums = require(PluginModules.PluginEnums)
local PluginProvider = require(PluginModules.PluginProvider)
local Translator = require(PluginModules.Translator)
local Util = require(PluginModules.Util)

---

local SETTINGS_KEY: string = "ColorPane_Settings"
local SESSION_LOCK_KEY: string = "ColorPane_SessionLock"
local API_CACHE_LAST_REFRESH_KEY: string = "ColorPane_RobloxAPICacheLastRefresh"
local API_CACHE_KEY: string = "ColorPane_RobloxAPICache"
local API_CACHE_REFRESH_TIME: number = 8 * 3600

local DEFAULTS: {[string]: any} = {
    [PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation] = true,
    [PluginEnums.PluginSettingKey.SnapValue] = 0.1/100,
    [PluginEnums.PluginSettingKey.AutoLoadColorProperties] = false,
    [PluginEnums.PluginSettingKey.AutoCheckForUpdate] = true,
    [PluginEnums.PluginSettingKey.UserPalettes] = {},
    [PluginEnums.PluginSettingKey.AutoSave] = true,
    [PluginEnums.PluginSettingKey.AutoSaveInterval] = 5,
    [PluginEnums.PluginSettingKey.CacheAPIData] = false,
    [PluginEnums.PluginSettingKey.UserGradients] = {},
}


---

local plugin: Plugin? = PluginProvider()
assert(plugin, Util.makeBugMessage("Plugin object missing"))

local pluginSettings: {[string]: any} = plugin:GetSetting(SETTINGS_KEY) or {}

local autoSavePromise: typeof(Promise.new())?
local lastScheduleTime: number = 0

local canSave: boolean = false
local settingsModified: boolean = false

local sessionId: string = HttpService:GenerateGUID(false)
local scheduleAutoSave: () -> nil

local settingChangedSignal: Signal.Signal<any>, fireSettingChanged: Signal.FireSignal<any> = Signal.createSignal()
local savingAbilityChangedSignal: Signal.Signal<boolean>, fireSavingAbilityChanged: Signal.FireSignal<boolean> = Signal.createSignal()

---

local PluginSettings = {}
PluginSettings.SettingChanged = settingChangedSignal
PluginSettings.SavingAbilityChanged = savingAbilityChangedSignal

PluginSettings.GetSavingAbility = function(): boolean
    return canSave
end

PluginSettings.UpdateSavingAbility = function(force: boolean?)
    local newCanSave

    if (not RunService:IsEdit()) then
        newCanSave = false
    else
        local sessionLockId = plugin:GetSetting(SESSION_LOCK_KEY)

        if ((sessionLockId == nil) or force) then
            plugin:SetSetting(SESSION_LOCK_KEY, sessionId)
            newCanSave = true
        else
            newCanSave = (sessionLockId == sessionId)
        end
    end

    if (newCanSave == canSave) then return end

    canSave = newCanSave
    fireSavingAbilityChanged(newCanSave)
end

PluginSettings.Flush = function()
    PluginSettings.UpdateSavingAbility()

    if (not canSave) then return end
    if (not settingsModified) then return end

    plugin:SetSetting(SETTINGS_KEY, pluginSettings)
    settingsModified = false
end

PluginSettings.Get = function(key)
    return pluginSettings[key]
end

PluginSettings.Set = function(key, newValue)
    PluginSettings.UpdateSavingAbility()

    if (not canSave) then return end
    if (pluginSettings[key] == newValue) then return end

    pluginSettings[key] = newValue
    settingsModified = true

    if (key == PluginEnums.PluginSettingKey.AutoSave) then
        if (newValue) then
            scheduleAutoSave()
        elseif (autoSavePromise) then
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

    fireSettingChanged({
        Key = key,
        Value = newValue,
    })
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
    assert(plugin, Util.makeBugMessage("Plugin object is missing"))
    
    plugin:SetSetting(API_CACHE_LAST_REFRESH_KEY, nil)
    plugin:SetSetting(API_CACHE_KEY, nil)
end

---

scheduleAutoSave = function()
    if (not pluginSettings[PluginEnums.PluginSettingKey.AutoSave]) then return end

    local newPromise = Promise.delay(pluginSettings[PluginEnums.PluginSettingKey.AutoSaveInterval] * 60)

    newPromise:andThen(function()
        PluginSettings.Flush()
        scheduleAutoSave()
    end)

    lastScheduleTime = os.clock()
    autoSavePromise = newPromise
end

if (RunService:IsEdit()) then
    -- claim session lock
    local sessionLockId = plugin:GetSetting(SESSION_LOCK_KEY)

    if (sessionLockId == nil) then
        plugin:SetSetting(SESSION_LOCK_KEY, sessionId)
        canSave = true
    else
        canSave = (sessionLockId == sessionId)
    end
    
    if (not canSave) then
        warn("[ColorPane] " .. Translator.FormatByKey("DataSavingLocked_Message"))
    end
else
    -- don't edit settings while testing
    canSave = false
end

do
    -- Migrate old settings (before v0.2)
    -- TODO: Remove for v1.0

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

do
    -- Migrate old gradient palette (before v0.4)
    -- TODO: Remove for v1.0

    local oldGradientPalette = PluginSettings.Get(PluginEnums.PluginSettingKey.UserColorSequences)

    if (oldGradientPalette) then
        for i = 1, #oldGradientPalette do
            local gradient = oldGradientPalette[i]
            local keypoints = gradient.color

            for j = 1, #keypoints do
                local keypoint = keypoints[j]
                
                keypoints[j] = {
                    Time = keypoint[1],
                    Color = keypoint[2]
                }
            end

            gradient.keypoints = keypoints
            gradient.color = nil
        end

        PluginSettings.Set(PluginEnums.PluginSettingKey.UserGradients, oldGradientPalette)
        PluginSettings.Set(PluginEnums.PluginSettingKey.UserColorSequences, nil)
        PluginSettings.Flush()
    end
end

-- populate missing settings
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
        if ((not canCache) or ((os.time() - cachedAPIDataLastRefresh) >= API_CACHE_REFRESH_TIME)) then
            PluginSettings.ClearCachedRobloxAPIData()
        end
    end
end

-- init auto-saving
if (pluginSettings[PluginEnums.PluginSettingKey.AutoSave]) then
    scheduleAutoSave()
end

plugin.Unloading:Connect(function()
    local sessionLockId = plugin:GetSetting(SESSION_LOCK_KEY)

    if (autoSavePromise) then
        autoSavePromise:cancel()
    end

    PluginSettings.Flush()

    if (sessionLockId == sessionId) then
        plugin:SetSetting(SESSION_LOCK_KEY, nil)
        canSave = false
    end
end)

return PluginSettings