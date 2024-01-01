--!strict

local root = script.Parent.Parent

local PluginModules = root.PluginModules
local PluginProvider = require(PluginModules.PluginProvider)
local PluginWidget = require(PluginModules.PluginWidget)
local Store = require(PluginModules.Store)
local Translator = require(PluginModules.Translator)
local Util = require(PluginModules.Util)

local includes = root.includes
local Roact = require(includes.Roact)
local RoactRodux = require(includes.RoactRodux)

local Components = root.Components
local GradientPalette = require(Components.GradientPalette)

---

local plugin: Plugin? = PluginProvider()
assert(plugin, Util.makeBugMessage("Plugin object is missing"))

---

local tree
local widget = PluginWidget("GradientPalette")

---

local GradientPaletteWidget = {}

GradientPaletteWidget.IsOpen = function()
    return (tree and true or false)
end

GradientPaletteWidget.Open = function(beforeSetGradient)
    if (tree) then return end

    tree = Roact.mount(Roact.createElement(RoactRodux.StoreProvider, {
        store = Store,
    }, {
        App = Roact.createElement(GradientPalette, {
            beforeSetGradient = beforeSetGradient,
        })
    }), widget)

    widget.Title = Translator.FormatByKey("GradientPalette_WindowTitle")
    widget.Enabled = true
end

GradientPaletteWidget.Close = function()
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
        GradientPaletteWidget.Close()
    end
end)


return GradientPaletteWidget