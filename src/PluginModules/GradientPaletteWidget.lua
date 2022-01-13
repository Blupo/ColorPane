local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local MakeStore = require(PluginModules:FindFirstChild("MakeStore"))
local MakeWidget = require(PluginModules:FindFirstChild("MakeWidget"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local GradientPalette = require(Components:FindFirstChild("GradientPalette"))

---

local colorPaneStore

local tree
local widget
local widgetEnabledChanged

---

local GradientPaletteWidget = {}

GradientPaletteWidget.IsOpen = function()
    return (tree and true or false)
end

GradientPaletteWidget.Open = function(beforeSetGradient)
    if (tree) then return end

    tree = Roact.mount(Roact.createElement(RoactRodux.StoreProvider, {
        store = colorPaneStore,
    }, {
        App = Roact.createElement(GradientPalette, {
            beforeSetGradient = beforeSetGradient,
        })
    }), widget)

    widget.Title = "Gradients"
    widget.Enabled = true
end

GradientPaletteWidget.Close = function()
    if (not tree) then return end

    Roact.unmount(tree)
    tree = nil
    widget.Enabled = false
    widget.Title = "ColorPane Gradient Palette"
end

GradientPaletteWidget.init = function(plugin)
    GradientPaletteWidget.init = nil

    colorPaneStore = MakeStore(plugin)
    widget = MakeWidget(plugin, "GradientPalette")

    widgetEnabledChanged = widget:GetPropertyChangedSignal("Enabled"):Connect(function()
        if (widget.Enabled and (not tree)) then
            widget.Enabled = false
        elseif ((not widget.Enabled) and tree) then
            GradientPaletteWidget.Close()
        end
    end)

    plugin.Unloading:Connect(function()
        widgetEnabledChanged:Disconnect()
    end)
end

return GradientPaletteWidget