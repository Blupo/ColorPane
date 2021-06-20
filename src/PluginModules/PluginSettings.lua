local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))

---

local SETTINGS_KEY = "ColorPane_Settings"

local DEFAULTS = {
    [PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation] = true,
    [PluginEnums.PluginSettingKey.SnapValue] = 0.1/100,
    [PluginEnums.PluginSettingKey.AutoLoadAPI] = false,
    [PluginEnums.PluginSettingKey.AutoLoadColorProperties] = false,
}

---

local plugin
local pluginSettings
local settingsModified = false

local settingChangedEvent = Instance.new("BindableEvent")

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
end

PluginSettings.Flush = function()
    if (not settingsModified) then return end

    plugin:SetSetting(SETTINGS_KEY, pluginSettings)
    settingsModified = false
end

PluginSettings.init = function(initPlugin)
    PluginSettings.init = nil

    plugin = initPlugin
    pluginSettings = initPlugin:GetSetting(SETTINGS_KEY) or {}

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
        end
    end

    initPlugin.Unloading:Connect(function()
        settingChangedEvent:Destroy()
        PluginSettings.Flush()
    end)
end

return PluginSettings