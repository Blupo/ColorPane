local RunService = game:GetService("RunService")

---

local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local PluginSettings = require(PluginModules:FindFirstChild("PluginSettings"))
local RobloxAPI = require(PluginModules:FindFirstChild("RobloxAPI"))
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local Checkbox = require(Components:FindFirstChild("Checkbox"))
local ConnectTheme = require(Components:FindFirstChild("ConnectTheme"))
local Padding = require(Components:FindFirstChild("Padding"))
local PropertiesList = require(Components:FindFirstChild("PropertiesList"))

---

local NoAPIAlert = Roact.PureComponent:extend("NoAPIAlert")

NoAPIAlert.init = function(self)
    self.apiDataRequestStarted = RobloxAPI.DataRequestStarted:Connect(function()
        self:setState({
            requestRunning = true,
        })
    end)

    self.apiDataRequestFinished = RobloxAPI.DataRequestFinished:Connect(function()
        self:setState({
            requestRunning = false,
        })
    end)

    self.settingsChanged = PluginSettings.SettingChanged:Connect(function(key, newValue)
        if (key ~= PluginEnums.PluginSettingKey.AutoLoadColorProperties) then return end

        self:setState({
            autoLoad = newValue
        })
    end)
    
    self:setState({
        requestRunning = RobloxAPI.IsRequestRunning(),
        autoLoad = PluginSettings.Get(PluginEnums.PluginSettingKey.AutoLoadColorProperties)
    })
end

NoAPIAlert.willUnmount = function(self)
    self.apiDataRequestStarted:Disconnect()
    self.apiDataRequestFinished:Disconnect()
    self.settingsChanged:Disconnect()

    PluginSettings.Flush()
end

NoAPIAlert.render = function(self)
    local theme = self.props.theme
    local requestRunning = self.state.requestRunning

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
    }, {
        UIPadding = Roact.createElement(Padding, {Style.PagePadding}),

        Notice = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.new(1, 0, 0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Font = Style.StandardFont,
            TextSize = Style.StandardTextSize,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Bottom,
            TextWrapped = true,
            Text = "The Roblox API data has not been loaded. Please use the Load button to load the data. This screen will disappear once the data has been loaded.",
            
            TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
        }),

        LoadButton = Roact.createElement(Button, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0.5, Style.SpaciousElementPadding),
            Size = UDim2.new(0, Style.DialogButtonWidth, 0, Style.StandardButtonSize),

            disabled = self.state.requestRunning,
            displayType = "text",
            text = requestRunning and "Loading..." or "Load",

            backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton),
            borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
            hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton, Enum.StudioStyleGuideModifier.Hover),
            displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText),

            disabledBackgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton, Enum.StudioStyleGuideModifier.Disabled),
            disabledDisplayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText, Enum.StudioStyleGuideModifier.Disabled),

            onActivated = function()
                if (requestRunning) then return end
                
                RobloxAPI.GetData()
            end
        }),

        AutoLoadRobloxAPICheckbox = Roact.createElement(Checkbox, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0.5, Style.StandardButtonSize + (Style.SpaciousElementPadding * 2)),
            Size = UDim2.new(1, 0, 0, 30),
            
            value = self.state.autoLoad,
            text = "Automatically load the Color Properties window on startup",

            onChecked = function(newValue)
                PluginSettings.Set(PluginEnums.PluginSettingKey.AutoLoadColorProperties, newValue)
            end,
        })
    })
end

---

local ColorProperties = Roact.PureComponent:extend("ColorProperties")

ColorProperties.init = function(self)
    local apiLoaded = RobloxAPI.IsAvailable()

    self.apiDataLoaded = (not apiLoaded) and
        RobloxAPI.DataRequestFinished:Connect(function(didLoad)
            if (not didLoad) then return end

            self.apiDataLoaded:Disconnect()
            self.apiDataLoaded = nil

            self:setState({
                apiLoaded = true,
            })
        end)
    or nil

    self:setState({
        apiLoaded = apiLoaded
    })
end

ColorProperties.willUnmount = function(self)
    if (self.apiDataLoaded) then
        self.apiDataLoaded:Disconnect()
        self.apiDataLoaded = nil
    end
end

ColorProperties.render = function(self)
    local theme = self.props.theme
    local element 

    if (not RunService:IsEdit()) then
        element = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
        }, {
            UIPadding = Roact.createElement(Padding, {Style.PagePadding}),

            Notice = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Font = Style.StandardFont,
                TextSize = Style.StandardTextSize,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextWrapped = true,
                Text = "Color Properties is disabled in testing modes",
                
                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
            }),
        })
    else
        element = Roact.createElement(self.state.apiLoaded and PropertiesList or NoAPIAlert)
    end

    return element
end

---

NoAPIAlert = ConnectTheme(NoAPIAlert)
return ConnectTheme(ColorProperties)