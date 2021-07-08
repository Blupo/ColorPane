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
local MakeWidget = require(PluginModules:FindFirstChild("MakeWidget"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local PluginSettings = require(PluginModules:FindFirstChild("PluginSettings"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local Promise = require(includes:FindFirstChild("Promise"))
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local ColorEditor = require(Components:FindFirstChild("ColorEditor"))
local ColorSequenceEditor = require(Components:FindFirstChild("ColorSequenceEditor"))

---

local DEFAULT_COLOR = Color3.new(1, 1, 1)
local DEFAULT_COLORSEQUENCE = ColorSequence.new(DEFAULT_COLOR)

local plugin
local pluginUnloadingEvent
local scriptReparentedEvent

local colorPaneStore
local persistentSettingsChanged

local colorEditorTree
local colorEditorWidget
local colorEditorWidgetEnabledChanged

local colorSequenceEditorTree
local colorSequenceEditorWidget
local colorSequenceEditorWidgetEnabledChanged

local unloadingEvent = Instance.new("BindableEvent")
local colorEditingFinishedEvent = Instance.new("BindableEvent")
local colorSequenceEditingFinishedEvent = Instance.new("BindableEvent")

local copy = Util.copy
local noYield = Util.noYield

local isOptionalType = function(value, typeName)
    return ((typeof(value) == typeName) or (typeof(value) == "nil"))
end

local onUnloading = function(waitToDestroy)
    if (scriptReparentedEvent) then
        scriptReparentedEvent:Disconnect()
        scriptReparentedEvent = nil
    end

    if (pluginUnloadingEvent) then
        pluginUnloadingEvent:Disconnect()
        pluginUnloadingEvent = nil
    end

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
        App = Roact.createElement(ColorEditor, {
            originalColor = color,
            finishedEvent = finishedEvent
        })
    }), colorEditorWidget)

    colorEditorWidget.Title = title
    colorEditorWidget.Enabled = true
end

local mountColorSequenceEditor = function(title, colorSequence, promptForColorEdit, finishedEvent, onValueChanged)
    colorSequenceEditorTree = Roact.mount(Roact.createElement(RoactRodux.StoreProvider, {
        store = colorPaneStore,
    }, {
        App = Roact.createElement(ColorSequenceEditor, {
            originalColor = colorSequence,
            promptForColorEdit = promptForColorEdit,
            onValueChanged = onValueChanged,
            finishedEvent = finishedEvent
        })
    }), colorSequenceEditorWidget)

    colorSequenceEditorWidget.Title = title
    colorSequenceEditorWidget.Enabled = true
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
        if (not (oldState.colorEditor.color and newState.colorEditor.color)) then return end
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
        colorEditorWidget.Title = "ColorPane Color Editor"

        colorPaneStore:dispatch({
            type = PluginEnums.StoreActionType.ColorEditor_SetColor,
        })
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

    promptOptions.PromptTitle = promptOptions.PromptTitle or "Create a gradient"
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
        colorSequenceEditorWidget.Title = "ColorPane ColorSequence Editor"
    end)

    mountColorSequenceEditor(promptOptions.PromptTitle, promptOptions.InitialColor, internalPromptForColor, colorSequenceEditingFinishedEvent, promptOptions.OnColorChanged)
    return editPromise
end

ColorPane.init = function(pluginObj)
    if (plugin) then return end

    ColorPane.__init = nil
    plugin = pluginObj

    colorPaneStore = MakeStore(plugin)
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

            PluginSettings.Set(PluginEnums.PluginSettingKey.UserPalettes, newPalettes)
        end

        if (newState.colorSequenceEditor.lastPaletteModification ~= oldState.colorSequenceEditor.lastPaletteModification) then
            local newPalette = copy(newState.colorSequenceEditor.palette)

            for i = 1, #newPalette do
                local color = newPalette[i]
                local colorSequence = color.color
                local keypoints = {}

                for j = 1, #colorSequence.Keypoints do
                    local keypoint = colorSequence.Keypoints[j]
                    local keypointValue = keypoint.Value

                    keypoints[j] = {keypoint.Time, {keypointValue.R, keypointValue.G, keypointValue.B}}
                end

                color.color = keypoints
            end
            
            PluginSettings.Set(PluginEnums.PluginSettingKey.UserColorSequences, newPalette)
        end

        if (newState.colorSequenceEditor.snap ~= oldState.colorSequenceEditor.snap) then
            PluginSettings.Set(PluginEnums.PluginSettingKey.SnapValue, newState.colorSequenceEditor.snap)
        end
    end)

    pluginUnloadingEvent = plugin.Unloading:Connect(onUnloading)
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