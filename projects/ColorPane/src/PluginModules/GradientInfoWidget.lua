--!strict

local root = script.Parent.Parent
local Common = root.Common

local CommonPluginModules = Common.PluginModules
local PluginProvider = require(CommonPluginModules.PluginProvider)
local Translator = require(CommonPluginModules.Translator)

local CommonIncludes = Common.Includes
local RoactRoduxModules = CommonIncludes.RoactRodux
local Roact = require(RoactRoduxModules.Roact)
local RoactRodux = require(RoactRoduxModules.RoactRodux)

local PluginModules = root.PluginModules
local PluginWidget = require(PluginModules.PluginWidget)
local Store = require(PluginModules.Store)
local Util = require(PluginModules.Util)

local Components = root.Components
local GradientInfo = require(Components.GradientInfo)

---

local plugin: Plugin? = PluginProvider()
assert(plugin, Util.makeBugMessage("Plugin object is missing"))

local tree
local widget = PluginWidget("GradientInfo")

---

local GradientInfoWidget = {}

GradientInfoWidget.IsOpen = function(): boolean
    return (tree and true or false)
end

GradientInfoWidget.Open = function()
    if (tree) then return end

    tree = Roact.mount(Roact.createElement(RoactRodux.StoreProvider, {
        store = Store,
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

---

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
    if (widget.Enabled and (not tree)) then
        widget.Enabled = false
    elseif ((not widget.Enabled) and tree) then
        GradientInfoWidget.Close()
    end
end)

return GradientInfoWidget