local RunService = game:GetService("RunService")

---

local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local PluginSettings = require(PluginModules:FindFirstChild("PluginSettings"))
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local Checkbox = require(Components:FindFirstChild("Checkbox"))
local TextInput = require(Components:FindFirstChild("TextInput"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardScrollingFrame = StandardComponents.ScrollingFrame
local StandardTextLabel = StandardComponents.TextLabel
local StandardUIListLayout = StandardComponents.UIListLayout
local StandardUIPadding = StandardComponents.UIPadding

---

local SETTINGS = {
    [PluginEnums.PluginSettingKey.AutoLoadAPI] = true,
    [PluginEnums.PluginSettingKey.AutoLoadColorProperties] = true,
    [PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation] = true,
    [PluginEnums.PluginSettingKey.AutoCheckForUpdate] = true,
    [PluginEnums.PluginSettingKey.AutoSave] = true,
    [PluginEnums.PluginSettingKey.AutoSaveInterval] = true,
    [PluginEnums.PluginSettingKey.CacheAPIData] = true,
    [PluginEnums.PluginSettingKey.ColorPropertiesLivePreview] = true,
}

---

local Settings = Roact.PureComponent:extend("Settings")

Settings.init = function(self)
    local initSettings = {}

    for key in pairs(SETTINGS) do
        initSettings[key] = PluginSettings.Get(key)
    end

    self.listLength, self.updateListLength = Roact.createBinding(0)
    self:setState(initSettings)
end

Settings.didMount = function(self)
    self.settingsChanged = PluginSettings.SettingChanged:Connect(function(key, newValue)
        if (not SETTINGS[key]) then return end
        
        self:setState({
            [key] = newValue,
        })
    end)
end

Settings.willUnmount = function(self)
    self.settingsChanged:Disconnect()
    PluginSettings.Flush()
end

Settings.render = function(self)
    local isEdit = RunService:IsEdit()

    return Roact.createElement(StandardScrollingFrame, {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,

        CanvasSize = self.listLength:map(function(length)
            return UDim2.new(0, 0, 0, length)
        end),

        useMainBackgroundColor = true,
    }, {
        UIPadding = Roact.createElement(StandardUIPadding, {Style.PagePadding}),

        UIListLayout = Roact.createElement(StandardUIListLayout, {
            Padding = UDim.new(0, Style.SpaciousElementPadding),
            HorizontalAlignment = Enum.HorizontalAlignment.Left,

            [Roact.Change.AbsoluteContentSize] = function(obj)
                self.updateListLength(obj.AbsoluteContentSize.Y + (Style.PagePadding * 2))
            end,

            preset = 1,
        }),

        AutoLoadAPICheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, Style.StandardTextSize * 2),
            LayoutOrder = 1,
            
            disabled = (not isEdit),
            value = self.state[PluginEnums.PluginSettingKey.AutoLoadAPI],
            text = "Automatically inject the ColorPane API script on startup",

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AutoLoadAPI, newValue)
            end,
        }),

        AutoLoadColorPropertiesCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, Style.StandardTextSize * 2),
            LayoutOrder = 2,
            
            disabled = (not isEdit),
            value = self.state[PluginEnums.PluginSettingKey.AutoLoadColorProperties],
            text = "Automatically load the Roblox API data for Color Properties on startup",

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AutoLoadColorProperties, newValue)
            end,
        }),

        AutoSaveCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, Style.StandardInputHeight),
            LayoutOrder = 3,
            
            disabled = (not isEdit),
            value = self.state[PluginEnums.PluginSettingKey.AutoSave],
            text = "Auto-save settings and palettes",

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AutoSave, newValue)
            end,
        }),

        AutoSaveInterval = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, Style.StandardInputHeight),
            LayoutOrder = 4,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Label = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(1, -(30 + Style.SpaciousElementPadding), 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),

                Text = "Auto-save interval (in minutes)",
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
            }),

            Input = Roact.createElement(TextInput, {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 30, 1, 0),
                Position = UDim2.new(0, 0, 0.5, 0),
                Text = self.state[PluginEnums.PluginSettingKey.AutoSaveInterval],
                TextXAlignment = Enum.TextXAlignment.Center,

                canClear = false,
                disabled = (not isEdit) or (not self.state[PluginEnums.PluginSettingKey.AutoSave]),

                isTextAValidValue = function(text)
                    local interval = tonumber(text)
                    if (not interval) then return false end

                    return ((math.floor(interval) == interval) and (interval > 0))
                end,

                onSubmit = function(newText)
                    local interval = tonumber(newText)
                    if (not interval) then return false end
                    if ((math.floor(interval) ~= interval) or (interval < 1)) then return end

                    PluginSettings.Set(PluginEnums.PluginSettingKey.AutoSaveInterval, interval)
                end,
            })
        }),

        CacheAPIDataCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, Style.StandardTextSize * 2),
            LayoutOrder = 5,
            
            disabled = (not isEdit),
            value = self.state[PluginEnums.PluginSettingKey.CacheAPIData],
            text = "Cache Roblox API data for use during testing sessions",

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.CacheAPIData, newValue)
            end,
        }),

        AutoCheckForUpdateCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, Style.StandardInputHeight),
            LayoutOrder = 6,
            
            disabled = (not isEdit),
            value = self.state[PluginEnums.PluginSettingKey.AutoCheckForUpdate],
            text = "Check for updates on startup",

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AutoCheckForUpdate, newValue)
            end,
        }),

        AskNameBeforePaletteCreationCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, Style.StandardInputHeight),
            LayoutOrder = 7,
            
            disabled = (not isEdit),
            value = self.state[PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation],
            text = "Name palettes before creating them",

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation, newValue)
            end,
        }),
        
        ResetSessionDataButton = Roact.createElement(Button, {
            Size = UDim2.new(0, 110, 0, Style.StandardInputHeight),
            LayoutOrder = 8,

            disabled = (not isEdit),
            displayType = "text",
            text = "Release Session Lock",

            onActivated = function()
                PluginSettings.ReleaseSessionLock()
                warn("[ColorPane] Session lock has been released")
            end,
        }),
    })
end

return Settings
