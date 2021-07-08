local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local MakeStore = require(PluginModules:FindFirstChild("MakeStore"))
local MakeWidget = require(PluginModules:FindFirstChild("MakeWidget"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local ColorSequencePalette = require(Components:FindFirstChild("ColorSequencePalette"))

---

local colorPaneStore

local tree
local widget
local widgetEnabledChanged

---

local ColorSequencePaletteWidget = {}

ColorSequencePaletteWidget.IsOpen = function()
    return (tree and true or false)
end

ColorSequencePaletteWidget.Open = function(getCurrentColorSequence, setCurrentColorSequence)
    if (tree) then return end

    tree = Roact.mount(Roact.createElement(RoactRodux.StoreProvider, {
        store = colorPaneStore,
    }, {
        App = Roact.createElement(ColorSequencePalette, {
            getCurrentColorSequence = getCurrentColorSequence,
            setCurrentColorSequence = setCurrentColorSequence,
        })
    }), widget)

    widget.Title = "Gradients"
    widget.Enabled = true
end

ColorSequencePaletteWidget.Close = function()
    if (not tree) then return end

    Roact.unmount(tree)
    tree = nil
    widget.Enabled = false
    widget.Title = "ColorPane ColorSequence Palette"
end

ColorSequencePaletteWidget.init = function(plugin)
    ColorSequencePaletteWidget.init = nil

    colorPaneStore = MakeStore(plugin)
    widget = MakeWidget(plugin, "ColorSequencePalette")

    widgetEnabledChanged = widget:GetPropertyChangedSignal("Enabled"):Connect(function()
        if (widget.Enabled and (not tree)) then
            widget.Enabled = false
        elseif ((not widget.Enabled) and tree) then
            ColorSequencePaletteWidget.Close()
        end
    end)

    plugin.Unloading:Connect(function()
        widgetEnabledChanged:Disconnect()
    end)
end

return ColorSequencePaletteWidget