local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local PluginSettings = require(PluginModules:FindFirstChild("PluginSettings"))
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local Checkbox = require(Components:FindFirstChild("Checkbox"))
local ConnectTheme = require(Components:FindFirstChild("ConnectTheme"))
local Padding = require(Components:FindFirstChild("Padding"))
local TextInput = require(Components:FindFirstChild("TextInput"))

---

local SETTINGS = {
    [PluginEnums.PluginSettingKey.AutoLoadAPI] = true,
    [PluginEnums.PluginSettingKey.AutoLoadColorProperties] = true,
    [PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation] = true,
    [PluginEnums.PluginSettingKey.AutoCheckForUpdate] = true,
    [PluginEnums.PluginSettingKey.AutoSave] = true,
    [PluginEnums.PluginSettingKey.AutoSaveInterval] = true,
}

---

local Settings = Roact.PureComponent:extend("Settings")

Settings.init = function(self)
    local initSettings = {}

    for key in pairs(SETTINGS) do
        initSettings[key] = PluginSettings.Get(key)
    end

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
    local theme = self.props.theme

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
    }, {
        UIPadding = Roact.createElement(Padding, {Style.PagePadding}),

        UIListLayout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, Style.MinorElementPadding),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        }),

        AutoLoadAPICheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, 22),
            LayoutOrder = 1,
            
            value = self.state[PluginEnums.PluginSettingKey.AutoLoadAPI],
            text = "Automatically load the API on startup",

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AutoLoadAPI, newValue)
            end,
        }),

        AutoLoadColorPropertiesCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, 30),
            LayoutOrder = 2,
            
            value = self.state[PluginEnums.PluginSettingKey.AutoLoadColorProperties],
            text = "Automatically load the Color Properties window on startup",

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AutoLoadColorProperties, newValue)
            end,
        }),

        AutoCheckForUpdate = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, 22),
            LayoutOrder = 5,
            
            value = self.state[PluginEnums.PluginSettingKey.AutoCheckForUpdate],
            text = "Check for updates on startup",

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AutoCheckForUpdate, newValue)
            end,
        }),

        AskNameBeforePaletteCreationCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, 22),
            LayoutOrder = 6,
            
            value = self.state[PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation],
            text = "Name palettes before creating them",

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation, newValue)
            end,
        }),

        AutoSaveCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, 22),
            LayoutOrder = 3,
            
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
            Label = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(1, -(30 + Style.SpaciousElementPadding), 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = "Auto-save interval (in minutes)",
                Font = Style.StandardFont,
                TextSize = Style.StandardTextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,

                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
            }),

            Input = Roact.createElement(TextInput, {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 30, 1, 0),
                Position = UDim2.new(0, 0, 0.5, 0),
                Text = self.state[PluginEnums.PluginSettingKey.AutoSaveInterval],
                TextXAlignment = Enum.TextXAlignment.Center,

                canClear = false,
                disabled = (not self.state[PluginEnums.PluginSettingKey.AutoSave]),

                isTextAValidValue = function(text)
                    local interval = tonumber(text)
                    if (not interval) then return false end

                    return ((math.floor(interval) == interval) and (interval > 0))
                end,

                onTextChanged = function(newText)
                    local interval = tonumber(newText)
                    if (not interval) then return false end
                    if ((math.floor(interval) ~= interval) or (interval < 1)) then return end

                    PluginSettings.Set(PluginEnums.PluginSettingKey.AutoSaveInterval, interval)
                end,
            })
        })
    })
end

return ConnectTheme(Settings)
