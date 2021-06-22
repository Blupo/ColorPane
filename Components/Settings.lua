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

---

local Settings = Roact.PureComponent:extend("Settings")

Settings.init = function(self)
    self:setState({
        [PluginEnums.PluginSettingKey.AutoLoadAPI] = PluginSettings.Get(PluginEnums.PluginSettingKey.AutoLoadAPI),
        [PluginEnums.PluginSettingKey.AutoLoadColorProperties] = PluginSettings.Get(PluginEnums.PluginSettingKey.AutoLoadColorProperties),
        [PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation] = PluginSettings.Get(PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation),
        [PluginEnums.PluginSettingKey.AutoCheckForUpdate] = PluginSettings.Get(PluginEnums.PluginSettingKey.AutoCheckForUpdate),
    })
end

Settings.didMount = function(self)
    self.settingsChanged = PluginSettings.SettingChanged:Connect(function(key, newValue)
        if (
            (key == PluginEnums.PluginSettingKey.AutoLoadAPI) or
            (key == PluginEnums.PluginSettingKey.AutoLoadColorProperties) or
            (key == PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation) or
            (key == PluginEnums.PluginSettingKey.AutoCheckForUpdate)
        ) then
            self:setState({
                [key] = newValue,
            })
        end
    end)
end

Settings.willUnmount = function(self)
    self.settingsChanged:Disconnect()
    PluginSettings.Flush()
end

Settings.render = function(self)
    local theme = self.props.theme

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame),
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
            LayoutOrder = 0,
            
            value = self.state[PluginEnums.PluginSettingKey.AutoLoadAPI],
            text = "Automatically load the API on startup",

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AutoLoadAPI, newValue)
            end,
        }),

        AutoLoadColorPropertiesCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, 30),
            LayoutOrder = 1,
            
            value = self.state[PluginEnums.PluginSettingKey.AutoLoadColorProperties],
            text = "Automatically load the Color Properties window on startup",

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AutoLoadColorProperties, newValue)
            end,
        }),

        AutoCheckForUpdate = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, 22),
            LayoutOrder = 2,
            
            value = self.state[PluginEnums.PluginSettingKey.AutoCheckForUpdate],
            text = "Check for updates on startup",

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AutoCheckForUpdate, newValue)
            end,
        }),

        AskNameBeforePaletteCreationCheckbox = Roact.createElement(Checkbox, {
            Size = UDim2.new(1, 0, 0, 22),
            LayoutOrder = 3,
            
            value = self.state[PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation],
            text = "Name palettes before creating them",

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation, newValue)
            end,
        }),
    })
end

return ConnectTheme(Settings)
