--[[
    This ModuleScript exposes the ColorPane API.

    Please do not delete or modify this script, it is required
    for developers to be able to use ColorPane.

    Learn more about ColorPane:
        https://github.com/Blupo/ColorPane
]]

local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

---

local root = script.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local MakeStore = require(PluginModules:FindFirstChild("MakeStore"))
local MakeToolbar = require(PluginModules:FindFirstChild("MakeToolbar"))
local MakeWidget = require(PluginModules:FindFirstChild("MakeWidget"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local util = require(PluginModules:FindFirstChild("util"))

local includes = root:FindFirstChild("includes")
local Promise = require(includes:FindFirstChild("Promise"))
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local ColorEditor = require(Components:FindFirstChild("ColorEditor"))
local ColorSequenceEditor = require(Components:FindFirstChild("ColorSequenceEditor"))

---

local MAX_QP_COLORS = 99
local SETTINGS_KEY = "ColorPane_Settings"
local DEFAULT_COLOR = Color3.new(1, 1, 1)
local DEFAULT_COLORSEQUENCE = ColorSequence.new(DEFAULT_COLOR)

local plugin
local pluginUnloadingEvent
local scriptReparentedEvent

local colorPaneStore
local persistentSettingsChanged

local toolbarComponents
local colorEditorToolbarButton

local colorEditorTree
local colorEditorWidget
local colorEditorWidgetEnabledChanged

local colorSequenceEditorTree
local colorSequenceEditorWidget
local colorSequenceEditorWidgetEnabledChanged

local unloadingEvent = Instance.new("BindableEvent")
local colorEditingFinishedEvent = Instance.new("BindableEvent")
local colorSequenceEditingFinishedEvent = Instance.new("BindableEvent")

local copy = util.copy
local mergeTable = util.mergeTable
local noYield = util.noYield
local noOp = function() end

local isOptionalType = function(value, typeName)
    return ((typeof(value) == typeName) or (typeof(value) == "nil"))
end

local onUnloading = function(waitToDestroy)
    scriptReparentedEvent:Disconnect()
    pluginUnloadingEvent:Disconnect()

    if (unloadingEvent) then
        unloadingEvent:Fire()
        unloadingEvent:Destroy()
        unloadingEvent = nil
    end

    if (plugin) then
        persistentSettingsChanged.disconnect()
        colorEditorWidgetEnabledChanged:Disconnect()
        colorSequenceEditorWidgetEnabledChanged:Disconnect()

        if (colorEditorTree) then
            colorEditingFinishedEvent:Fire(false)
            colorEditingFinishedEvent:Destroy()
        end

        if (colorSequenceEditorTree) then
            colorSequenceEditingFinishedEvent:Fire(false)
            colorSequenceEditingFinishedEvent:Destroy()
        end
    end
    
    if (waitToDestroy) then
        RunService.Heartbeat:Wait()
    end

    script:Destroy()
end

local mountColorEditor = function(title, color, finishedEvent)
    colorEditorWidget.Title = title

    colorPaneStore:dispatch({
        type = PluginEnums.StoreActionType.ColorEditor_SetColor,
        color = color,
    })

    colorEditorTree = Roact.mount(Roact.createElement(RoactRodux.StoreProvider, {
        store = colorPaneStore,
    }, {
        Editor = Roact.createElement(ColorEditor, {
            originalColor = color,
            finishedEvent = finishedEvent
        })
    }), colorEditorWidget)

    if (not colorEditorWidget.Enabled) then
        colorEditorWidget.Enabled = true
    end

    colorEditorToolbarButton:SetActive(true)
end

local mountColorSequenceEditor = function(title, colorSequence, promptForColorEdit, finishedEvent, onValueChanged)
    colorSequenceEditorWidget.Title = title

    colorSequenceEditorTree = Roact.mount(Roact.createElement(RoactRodux.StoreProvider, {
        store = colorPaneStore,
    }, {
        Editor = Roact.createElement(ColorSequenceEditor, {
            originalColor = colorSequence,
            promptForColorEdit = promptForColorEdit,
            onValueChanged = onValueChanged,
            finishedEvent = finishedEvent
        })
    }), colorSequenceEditorWidget)

    if (not colorSequenceEditorWidget.Enabled) then
        colorSequenceEditorWidget.Enabled = true
    end
end

---

local ColorPane = {}
ColorPane.PromiseStatus = Promise.Status
ColorPane.Unloading = unloadingEvent.Event

ColorPane.IsColorEditorOpen = function(): boolean
    if (colorSequenceEditorTree) then return true end

    return (colorEditorTree and true or false)
end

ColorPane.IsColorSequenceEditorOpen = function(): boolean
    return (colorSequenceEditorTree and true or false)
end

local internalPromptForColor = function(promptOptions)
    if (not isOptionalType(promptOptions, "table")) then return Promise.reject("Invalid prompt options") end
    promptOptions = promptOptions or {}

    if (not
        (
            isOptionalType(promptOptions.PromptTitle, "string") and
            isOptionalType(promptOptions.InitialColor, "Color3") and
            isOptionalType(promptOptions.OnColorChanged, "function")
        )
    ) then return Promise.reject("Invalid prompt options") end

    promptOptions.PromptTitle = promptOptions.PromptTitle or "Select a color"
    promptOptions.InitialColor = promptOptions.InitialColor or DEFAULT_COLOR

    local resolveEvent = Instance.new("BindableEvent")

    local editPromise = Promise.new(function(resolve)
        resolve(resolveEvent.Event:Wait())
    end)

    local storeChanged = colorPaneStore.changed:connect(function(newState, oldState)
        if (not colorEditorTree) then return end
        if (newState.colorEditor.color == oldState.colorEditor.color) then return end

        if (promptOptions.OnColorChanged) then
            noYield(promptOptions.OnColorChanged, newState.colorEditor.color)
        end
    end)

    local editingFinished
    editingFinished = colorEditingFinishedEvent.Event:Connect(function(didConfirm)
        editingFinished:Disconnect()

        if (not didConfirm) then
            editPromise:cancel()
            return
        end

        local newColor = colorPaneStore:getState().colorEditor.color
        
        if (newColor == promptOptions.InitialColor) then
            editPromise:cancel()
        else
            resolveEvent:Fire(newColor)
        end
    end)

    editPromise:finally(function()
        resolveEvent:Destroy()

        storeChanged.disconnect()
        Roact.unmount(colorEditorTree)
        colorEditorTree = nil
        colorEditorWidget.Enabled = false
        colorEditorToolbarButton:SetActive(false)
    end)

    mountColorEditor(promptOptions.PromptTitle, promptOptions.InitialColor, colorEditingFinishedEvent)
    return editPromise
end

ColorPane.PromptForColor = function(promptOptions)
    if (ColorPane.IsColorEditorOpen()) then return Promise.reject("Editor is already open") end
    if (ColorPane.IsColorSequenceEditorOpen()) then return Promise.reject("Editor is reserved") end

    return internalPromptForColor(promptOptions)
end

ColorPane.PromptForColorSequence = function(promptOptions)
    if (ColorPane.IsColorSequenceEditorOpen()) then return Promise.reject("Editor is already open") end
    if (ColorPane.IsColorEditorOpen()) then return Promise.reject("Cannot reserve color editor") end

    if (not isOptionalType(promptOptions, "table")) then return Promise.reject("Invalid prompt options") end
    promptOptions = promptOptions or {}

    if (not
        (
            isOptionalType(promptOptions.PromptTitle, "string") and
            isOptionalType(promptOptions.InitialColor, "ColorSequence") and
            isOptionalType(promptOptions.OnColorChanged, "function")
        )
    ) then return Promise.reject("Invalid prompt options") end

    promptOptions.PromptTitle = promptOptions.PromptTitle or "Create a ColorSequence"
    promptOptions.InitialColor = promptOptions.InitialColor or DEFAULT_COLORSEQUENCE

    local resolveEvent = Instance.new("BindableEvent")

    local editPromise = Promise.new(function(resolve)
        resolve(resolveEvent.Event:Wait())
    end)

    local editingFinished
    editingFinished = colorSequenceEditingFinishedEvent.Event:Connect(function(didConfirm, newColor)
        editingFinished:Disconnect()

        if (not didConfirm) then
            editPromise:cancel()
            return
        end
        
        if (newColor == promptOptions.InitialColor) then
            editPromise:cancel()
        else
            resolveEvent:Fire(newColor)
        end
    end)

    editPromise:finally(function()
        resolveEvent:Destroy()

        Roact.unmount(colorSequenceEditorTree)
        colorSequenceEditorTree = nil
        colorSequenceEditorWidget.Enabled = false
    end)

    mountColorSequenceEditor(promptOptions.PromptTitle, promptOptions.InitialColor, internalPromptForColor, colorSequenceEditingFinishedEvent, promptOptions.OnColorChanged)
    return editPromise
end

ColorPane.OpenColorEditor = function()
    ColorPane.PromptForColor({
        PromptTitle = "Select a color",
        InitialColor = DEFAULT_COLOR
    }):andThen(noOp, noOp)
end

ColorPane.init = function(pluginObj)
    if (plugin) then return end

    ColorPane.__init = nil
    plugin = pluginObj

    colorPaneStore = MakeStore(plugin, MAX_QP_COLORS, plugin:GetSetting(SETTINGS_KEY) or {})
    toolbarComponents = MakeToolbar()
    colorEditorToolbarButton = toolbarComponents.ColorEditorButton

    colorEditorWidget = MakeWidget(plugin, "ColorEditor")
    colorSequenceEditorWidget = MakeWidget(plugin, "ColorSequenceEditor")

    colorEditorWidgetEnabledChanged = colorEditorWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
        if (colorEditorWidget.Enabled and (not colorEditorTree)) then
            colorEditorWidget.Enabled = false
        elseif ((not colorEditorWidget.Enabled) and colorEditorTree) then
            colorEditingFinishedEvent:Fire(false)
        end
    end)

    colorSequenceEditorWidgetEnabledChanged = colorSequenceEditorWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
        if (colorSequenceEditorWidget.Enabled and (not colorSequenceEditorTree)) then
            colorSequenceEditorWidget.Enabled = false
        elseif ((not colorSequenceEditorWidget.Enabled) and colorSequenceEditorTree) then
            colorSequenceEditingFinishedEvent:Fire(false)
        end
    end)

    persistentSettingsChanged = colorPaneStore.changed:connect(function(newState, oldState)
        local newSettingsSlice = {}
        local modifySettings = false

        if (newState.colorEditor.lastPaletteModification ~= oldState.colorEditor.lastPaletteModification) then
            local newPalettes = copy(newState.colorEditor.palettes)

            for i = 1, #newPalettes do
                local palette = newPalettes[i]

                for j = 1, #palette.colors do
                    local color = palette.colors[j]
                    local colorValue = color.color

                    color.color = {colorValue.R, colorValue.G, colorValue.B}
                end
            end

            newSettingsSlice.palettes = newPalettes
            modifySettings = true
        end

        if (newState.colorSequenceEditor.snap ~= oldState.colorSequenceEditor.snap) then
            newSettingsSlice.snap = newState.colorSequenceEditor.snap
            modifySettings = true
        end

        if (modifySettings) then
            local pluginSettings = plugin:GetSetting(SETTINGS_KEY) or {}
            mergeTable(pluginSettings, newSettingsSlice)

            plugin:SetSetting(SETTINGS_KEY, pluginSettings)
        end
    end)

    colorEditorToolbarButton.Click:Connect(function()
        if (colorEditorTree) then
            colorEditingFinishedEvent:Fire(false)
        else
            ColorPane.OpenColorEditor()
        end
    end)

    pluginUnloadingEvent = plugin.Unloading:Connect(onUnloading)
    colorEditorToolbarButton.ClickableWhenViewportHidden = true
end

---

ColorPane = setmetatable({}, {
    __index = ColorPane,
    __newindex = function() end,
    __metatable = true,
})

scriptReparentedEvent = script:GetPropertyChangedSignal("Parent"):Connect(function()
    if (script.Parent == CoreGui) then return end

    warn("The ColorPane API script was unexpectedly reparented")
    onUnloading(true)
end)

script:GetPropertyChangedSignal("Source"):Connect(function()
    warn("The ColorPane API script was unexpectedly modified")
    onUnloading()
end)

script:GetPropertyChangedSignal("Archivable"):Connect(function()
    if (not script.Archivable) then return end

    script.Archivable = false
end)

script:GetPropertyChangedSignal("Name"):Connect(function()
    if (script.Name == "ColorPane") then return end

    script.Name = "ColorPane"
end)

return ColorPane