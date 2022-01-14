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
local Constants = require(PluginModules:FindFirstChild("Constants"))
local MakeStore = require(PluginModules:FindFirstChild("MakeStore"))
local MakeWidget = require(PluginModules:FindFirstChild("MakeWidget"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local PluginSettings = require(PluginModules:FindFirstChild("PluginSettings"))
local ReleaseVersion = require(PluginModules:FindFirstChild("ReleaseVersion"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local ColorLib = require(includes:FindFirstChild("Color"))
local Promise = require(includes:FindFirstChild("Promise"))
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))
local Signal = require(includes:FindFirstChild("GoodSignal"))
local t = require(includes:FindFirstChild("t"))

local Components = root:FindFirstChild("Components")
local ColorEditor = require(Components:FindFirstChild("ColorEditor"))
local GradientEditor = require(Components:FindFirstChild("GradientEditor"))

local Color, Gradient = ColorLib.Color, ColorLib.Gradient

---

type Color = ColorLib.Color
type Gradient = ColorLib.Gradient

type ColorPromptOptions = {
    PromptTitle: string?,
    ColorType: string?,
    InitialColor: (Color | Color3)?,
    OnColorChanged: ((Color | Color3) -> nil)?
}

type GradientPromptOptions = {
    PromptTitle: string?,
    GradientType: string?,
    InitialGradient: (Gradient | ColorSequence)?,
    InitialColorSpace: string?,
    InitialHueAdjustment: string?,
    InitialPrecision: number?,
    OnGradientChanged: ((Gradient | ColorSequence) -> nil)?
}

type ColorSequencePromptOptions = {
    PromptTitle: string?,
    InitialColor: ColorSequence?,
    OnColorChanged: ((ColorSequence) -> nil)?
}

local DEFAULT_COLOR3 = Color3.new(1, 1, 1)
local DEFAULT_COLORSEQUENCE = ColorSequence.new(DEFAULT_COLOR3)

local DEFAULT_COLOR = Color.fromColor3(DEFAULT_COLOR3)
local DEFAULT_GRADIENT = Gradient.fromColorSequence(DEFAULT_COLORSEQUENCE)

local plugin
local pluginUnloadingEvent
local scriptReparentedEvent

local colorPaneStore
local persistentSettingsChanged

local colorEditorTree
local colorEditorWidget
local colorEditorWidgetEnabledChanged

local gradientEditorTree
local gradientEditorWidget
local gradientEditorWidgetEnabledChanged

local unloadingEvent = Signal.new()
local colorEditingFinishedEvent = Signal.new()
local gradientEditingFinishedEvent = Signal.new()

local oneIn = function(items)
    local checks = {}

    for i = 1, #items do
        local item = items[i]
        table.insert(checks, t.literal(item))
    end

    return t.union(table.unpack(checks))
end

local checkGradient = t.interface({
    Keypoints = t.array(t.interface({
        Time = t.number,
        Color = Color.isAColor,
    }))
})

local checkColorPromptOptions = t.interface({
    PromptTitle = t.optional(t.string),
    ColorType = t.optional(oneIn({ "Color", "Color3" })),
    InitialColor = t.union(t.Color3, Color.isAColor),
    OnColorChanged = t.optional(t.callback),
})

local checkGradientPromptOptions = t.interface({
    PromptTitle = t.optional(t.string),
    GradientType = t.optional(oneIn({ "Gradient", "ColorSequence" })),
    InitialGradient = t.union(t.ColorSequence, checkGradient),
    InitialColorSpace = t.optional(oneIn(Constants.VALID_GRADIENT_COLOR_SPACES)),
    InitialHueAdjustment = t.optional(oneIn(Constants.VALID_HUE_ADJUSTMENTS)),
    InitialPrecision = t.optional(t.number),
    OnGradientChanged = t.optional(t.callback),
})

---

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
    end

    if (plugin) then
        persistentSettingsChanged.disconnect()
        colorEditorWidgetEnabledChanged:Disconnect()
        gradientEditorWidgetEnabledChanged:Disconnect()

        if (colorEditorTree) then
            colorEditingFinishedEvent:Fire(false)
        end

        if (gradientEditorTree) then
            gradientEditingFinishedEvent:Fire(false)
        end
    end
    
    if (waitToDestroy) then
        RunService.Heartbeat:Wait()
    end

    script:Destroy()
end

local mountColorEditor = function(promptOptions, finishedEvent)
    local originalColor = promptOptions.InitialColor

    if (promptOptions.ColorType == "Color3") then
        originalColor = Color.fromColor3(originalColor)
    end

    colorPaneStore:dispatch({
        type = PluginEnums.StoreActionType.ColorEditor_SetColor,
        color = originalColor,
    })

    colorEditorTree = Roact.mount(Roact.createElement(RoactRodux.StoreProvider, {
        store = colorPaneStore,
    }, {
        App = Roact.createElement(ColorEditor, {
            originalColor = originalColor,
            finishedEvent = finishedEvent
        })
    }), colorEditorWidget)

    colorEditorWidget.Title = promptOptions.PromptTitle
    colorEditorWidget.Enabled = true
end

local mountGradientEditor = function(promptOptions, promptForColorEdit, finishedEvent)
    local gradient
    local keypoints

    if (promptOptions.GradientType == "ColorSequence") then
        gradient = Gradient.fromColorSequence(promptOptions.InitialGradient)
    elseif (promptOptions.GradientType == "Gradient") then
        gradient = promptOptions.InitialGradient
    end

    keypoints = Util.table.deepCopyPreserveColors(gradient.Keypoints)

    colorPaneStore:dispatch({
        type = PluginEnums.StoreActionType.GradientEditor_SetGradient,

        keypoints = keypoints,
        colorSpace = promptOptions.InitialColorSpace,
        hueAdjustment = promptOptions.InitialHueAdjustment,
        precision = promptOptions.InitialPrecision,
    })

    gradientEditorTree = Roact.mount(Roact.createElement(RoactRodux.StoreProvider, {
        store = colorPaneStore,
    }, {
        App = Roact.createElement(GradientEditor, {
            originalKeypoints = keypoints,
            originalColorSpace = promptOptions.InitialColorSpace,
            originalHueAdjustment = promptOptions.InitialHueAdjustment,
            originalPrecision = promptOptions.InitialPrecision,
            finishedEvent = finishedEvent,

            promptForColorEdit = promptForColorEdit,
        })
    }), gradientEditorWidget)

    gradientEditorWidget.Title = promptOptions.PromptTitle
    gradientEditorWidget.Enabled = true
end

---

local ColorPane = {}
ColorPane.PromiseStatus = Promise.Status
ColorPane.Unloading = unloadingEvent

ColorPane.GetVersion = function(): (number, number, number)
    return table.unpack(ReleaseVersion)
end

ColorPane.IsColorEditorOpen = function(): boolean
    if (gradientEditorTree) then return true end

    return (colorEditorTree and true or false)
end

ColorPane.IsGradientEditorOpen = function(): boolean
    return (gradientEditorTree and true or false)
end

local internalPromptForColor = function(optionalPromptOptions: ColorPromptOptions)
    local promptOptions = {
        PromptTitle = "Select a color"
    }

    if (type(optionalPromptOptions) == "table") then
        promptOptions = Util.table.merge(promptOptions, optionalPromptOptions)

        local colorType = optionalPromptOptions.ColorType
        local initialColor = optionalPromptOptions.InitialColor

        if (colorType and (not initialColor)) then
            promptOptions.ColorType = colorType
            promptOptions.InitialColor = (colorType == "Color3") and DEFAULT_COLOR3 or DEFAULT_COLOR
        elseif ((not colorType) and initialColor) then
            promptOptions.InitialColor = initialColor
            promptOptions.ColorType = (typeof(initialColor) == "Color3") and "Color3" or "Color"
        elseif ((not colorType) and (not initialColor)) then
            promptOptions.ColorType = "Color3"
            promptOptions.InitialColor = DEFAULT_COLOR3
        else
            if (
                ((colorType == "Color3") and (typeof(initialColor) ~= "Color3")) or
                ((colorType == "Color") and (not Color.isAColor(initialColor)))
            ) then
                return Promise.reject("Invalid prompt options")
            end
        end
    elseif (type(optionalPromptOptions) == "nil") then
        promptOptions.ColorType = "Color3"
        promptOptions.InitialColor = DEFAULT_COLOR3
    else
        return Promise.reject("Invalid prompt options")
    end

    local result = checkColorPromptOptions(promptOptions)
    if (not result) then return Promise.reject("Invalid prompt options") end 

    local resolveEvent = Signal.new()

    local editPromise = Promise.new(function(resolve)
        resolve(resolveEvent:Wait())
    end)

    local storeChanged = colorPaneStore.changed:connect(function(newState, oldState)
        if (not promptOptions.OnColorChanged) then return end

        local color = newState.colorEditor.color
        local oldColor = oldState.colorEditor.color

        if (not (color and oldColor)) then return end
        if (color == oldColor) then return end

        if (promptOptions.ColorType == "Color3") then
            color = color:toColor3()
        end

        Util.noYield(promptOptions.OnColorChanged, color)
    end)

    local editingFinished
    editingFinished = colorEditingFinishedEvent:Connect(function(didConfirm)
        editingFinished:Disconnect()

        if (not didConfirm) then
            editPromise:cancel()
            return
        end

        local newColor = colorPaneStore:getState().colorEditor.color

        if (promptOptions.ColorType == "Color3") then
            newColor = newColor:toColor3()
        end
        
        if (newColor == promptOptions.InitialColor) then
            editPromise:cancel()
        else
            resolveEvent:Fire(newColor)
        end
    end)

    editPromise:finally(function()
        storeChanged.disconnect()
        Roact.unmount(colorEditorTree)
        colorEditorTree = nil
        colorEditorWidget.Enabled = false
        colorEditorWidget.Title = "ColorPane Color Editor"

        colorPaneStore:dispatch({
            type = PluginEnums.StoreActionType.ColorEditor_SetColor,
        })
    end)

    mountColorEditor(promptOptions, colorEditingFinishedEvent)
    return editPromise
end

ColorPane.PromptForColor = function(promptOptions: ColorPromptOptions?)
    if (ColorPane.IsColorEditorOpen()) then return Promise.reject("Editor is already open") end
    if (ColorPane.IsGradientEditorOpen()) then return Promise.reject("Editor is reserved") end

    return internalPromptForColor(promptOptions)
end

ColorPane.PromptForGradient = function(optionalPromptOptions: GradientPromptOptions?)
    if (ColorPane.IsGradientEditorOpen()) then return Promise.reject("Editor is already open") end
    if (ColorPane.IsColorEditorOpen()) then return Promise.reject("Cannot reserve color editor") end

    local promptOptions = {
        PromptTitle = "Create a gradient",
        InitialColorSpace = "RGB",
        InitialHueAdjustment = "Shorter",
        InitialPrecision = 0,
    }

    if (type(optionalPromptOptions) == "table") then
        promptOptions = Util.table.merge(promptOptions, optionalPromptOptions)

        local gradientType = optionalPromptOptions.GradientType
        local initialGradient = optionalPromptOptions.InitialGradient

        if (gradientType and (not initialGradient)) then
            promptOptions.GradientType = gradientType
            promptOptions.InitialGradient = (gradientType == "ColorSequence") and DEFAULT_COLORSEQUENCE or DEFAULT_GRADIENT
        elseif ((not gradientType) and initialGradient) then
            promptOptions.InitialGradient = initialGradient
            promptOptions.GradientType = (typeof(initialGradient) == "ColorSequence") and "ColorSequence" or "Gradient"
        elseif ((not gradientType) and (not initialGradient)) then
            promptOptions.GradientType = "ColorSequence"
            promptOptions.InitialGradient = DEFAULT_COLORSEQUENCE
        else
            if (
                ((gradientType == "ColorSequence") and (typeof(initialGradient) ~= "ColorSequence")) or
                ((gradientType == "Gradient") and (not checkGradient(initialGradient)))
            ) then
                return Promise.reject("Invalid prompt options")
            end
        end
    elseif (type(optionalPromptOptions) == "nil") then
        promptOptions.GradientType = "ColorSequence"
        promptOptions.InitialGradient = DEFAULT_COLORSEQUENCE
    else
        return Promise.reject("Invalid prompt options")
    end

    local result = checkGradientPromptOptions(promptOptions)
    if (not result) then return Promise.reject("Invalid prompt options") end

    local resolveEvent = Signal.new()

    local editPromise = Promise.new(function(resolve)
        resolve(resolveEvent:Wait())
    end)

    local storeChanged = colorPaneStore.changed:connect(function(newState, oldState)
        if (not promptOptions.OnGradientChanged) then return end

        local keypoints = newState.gradientEditor.displayKeypoints
        local oldKeypoints = oldState.gradientEditor.displayKeypoints
        if (not (keypoints and oldKeypoints)) then return end

        local gradient = Gradient.new(keypoints)
        local oldGradient = Gradient.new(oldKeypoints)
        if (gradient == oldGradient) then return end

        Util.noYield(promptOptions.OnGradientChanged, (promptOptions.GradientType == "Gradient") and gradient or gradient:colorSequence())
    end)

    local editingFinished
    editingFinished = gradientEditingFinishedEvent:Connect(function(didConfirm)
        editingFinished:Disconnect()

        if (not didConfirm) then
            editPromise:cancel()
            return
        end
        
        local gradient = promptOptions.InitialGradient
        local newGradient = Gradient.new(colorPaneStore:getState().gradientEditor.displayKeypoints)

        if (promptOptions.GradientType == "ColorSequence") then
            newGradient = newGradient:colorSequence()
        end
        
        if (newGradient == gradient) then
            editPromise:cancel()
        else
            resolveEvent:Fire(newGradient)
        end
    end)

    editPromise:finally(function()
        storeChanged.disconnect()
        Roact.unmount(gradientEditorTree)
        gradientEditorTree = nil
        gradientEditorWidget.Enabled = false
        gradientEditorWidget.Title = "ColorPane Gradient Editor"

        colorPaneStore:dispatch({
            type = PluginEnums.StoreActionType.GradientEditor_ResetState,
        })
    end)

    mountGradientEditor(promptOptions, internalPromptForColor, gradientEditingFinishedEvent)
    return editPromise
end

ColorPane.init = function(pluginObj)
    if (plugin) then return end
    plugin = pluginObj

    colorPaneStore = MakeStore(plugin)
    colorEditorWidget = MakeWidget(plugin, "ColorEditor")
    gradientEditorWidget = MakeWidget(plugin, "GradientEditor")

    colorEditorWidgetEnabledChanged = colorEditorWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
        if (colorEditorWidget.Enabled and (not colorEditorTree)) then
            colorEditorWidget.Enabled = false
        elseif ((not colorEditorWidget.Enabled) and colorEditorTree) then
            colorEditingFinishedEvent:Fire(false)
        end
    end)

    gradientEditorWidgetEnabledChanged = gradientEditorWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
        if (gradientEditorWidget.Enabled and (not gradientEditorTree)) then
            gradientEditorWidget.Enabled = false
        elseif ((not gradientEditorWidget.Enabled) and gradientEditorTree) then
            gradientEditingFinishedEvent:Fire(false)
        end
    end)

    persistentSettingsChanged = colorPaneStore.changed:connect(function(newState, oldState)
        if (newState.colorEditor.lastPaletteModification ~= oldState.colorEditor.lastPaletteModification) then
            local newPalettes = Util.table.deepCopy(newState.colorEditor.palettes)

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

        if (newState.gradientEditor.lastPaletteModification ~= oldState.gradientEditor.lastPaletteModification) then
            local newPalette = Util.table.deepCopyPreserveColors(newState.gradientEditor.palette)

            for i = 1, #newPalette do
                local gradient = newPalette[i]
                local keypoints = gradient.keypoints

                for j = 1, #keypoints do
                    local keypoint = keypoints[j]

                    keypoints[j] = {
                        Time = keypoint.Time,
                        Color = { keypoint.Color:components(true) }
                    }
                end
            end
            
            PluginSettings.Set(PluginEnums.PluginSettingKey.UserGradients, newPalette)
        end

        if (newState.gradientEditor.snap ~= oldState.gradientEditor.snap) then
            PluginSettings.Set(PluginEnums.PluginSettingKey.SnapValue, newState.gradientEditor.snap)
        end
    end)

    pluginUnloadingEvent = plugin.Unloading:Connect(onUnloading)
end

--- DEPRECATED

ColorPane.IsColorSequenceEditorOpen = ColorPane.IsGradientEditorOpen

ColorPane.PromptForColorSequence = function(optionalPromptOptions: ColorSequencePromptOptions?)
    local promptOptions: ColorSequencePromptOptions = optionalPromptOptions or {}

    ColorPane.PromptForGradient({
        PromptTitle = promptOptions.PromptTitle,
        GradientType = "ColorSequence",
        InitialGradient = promptOptions.InitialColor,
        OnGradientChanged = promptOptions.OnColorChanged,
    })
end

---

table.freeze(ColorPane)

scriptReparentedEvent = script:GetPropertyChangedSignal("Parent"):Connect(function()
    if (script.Parent == CoreGui) then return end

    warn("[ColorPane] The API script was unexpectedly reparented")
    onUnloading(true)
end)

script:GetPropertyChangedSignal("Source"):Connect(function()
    warn("[ColorPane] The API script was unexpectedly modified")
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