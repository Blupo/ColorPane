local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local MakeStore = require(PluginModules:FindFirstChild("MakeStore"))
local MakeWidget = require(PluginModules:FindFirstChild("MakeWidget"))
local Translator = require(PluginModules:FindFirstChild("Translator"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local GradientInfo = require(Components:FindFirstChild("GradientInfo"))

---

local colorPaneStore

local tree
local widget
local widgetEnabledChanged

---

local GradientInfoWidget = {}

GradientInfoWidget.IsOpen = function()
    return (tree and true or false)
end

GradientInfoWidget.Open = function()
    if (tree) then return end

    tree = Roact.mount(Roact.createElement(RoactRodux.StoreProvider, {
        store = colorPaneStore,
    }, {
        App = Roact.createElement(GradientInfo)
    }), widget)

    widget.Title = Translator.FormatByKey("GradientInfo_WindowTitle")
    widget.Enabled = true
end

GradientInfoWidget.Close = function()
    if (not tree) then return end

    Roact.unmount(tree)
    tree = nil
    widget.Enabled = false
    widget.Title = ""
end

GradientInfoWidget.init = function(plugin)
    GradientInfoWidget.init = nil

    colorPaneStore = MakeStore(plugin)
    widget = MakeWidget(plugin, "GradientInfo")

    widgetEnabledChanged = widget:GetPropertyChangedSignal("Enabled"):Connect(function()
        if (widget.Enabled and (not tree)) then
            widget.Enabled = false
        elseif ((not widget.Enabled) and tree) then
            GradientInfoWidget.Close()
        end
    end)

    plugin.Unloading:Connect(function()
        widgetEnabledChanged:Disconnect()
    end)
end

return GradientInfoWidget