--[[
    This ModuleScript exposes the ColorPane API.

    Please do not delete or modify this script, it is required
    for developers to be able to use ColorPane.

    Learn more about ColorPane:
        https://github.com/Blupo/ColorPane
]]

---

local root = script.Parent

local PluginModules = root.PluginModules
local EditorInputSignals = require(PluginModules.EditorInputSignals)
local Constants = require(PluginModules.Constants)
local PluginEnums = require(PluginModules.PluginEnums)
local PluginSettings = require(PluginModules.PluginSettings)
local PluginWidget = require(PluginModules.PluginWidget)
local ReleaseVersion = require(PluginModules.ReleaseVersion)
local Store = require(PluginModules.Store)
local Translator = require(PluginModules.Translator)
local Util = require(PluginModules.Util)

local includes = root.includes
local ColorLib = require(includes.Color)
local Cryo = require(includes.Cryo)
local Promise = require(includes.Promise)
local Roact = require(includes.Roact)
local RoactRodux = require(includes.RoactRodux)
local Signal = require(includes.Signal)
local t = require(includes.t)

local Components = root.Components
local ColorEditor = require(Components.ColorEditor)
local GradientEditor = require(Components.GradientEditor)

local Color, Gradient = ColorLib.Color, ColorLib.Gradient

---

type Color = ColorLib.Color
type Gradient = ColorLib.Gradient

type ColorPromptOptions = {
    PromptTitle: string?,
    ColorType: ("Color" | "Color3")?,
    InitialColor: (Color | Color3)?,
    OnColorChanged: ((Color | Color3) -> any)?
}

type GradientPromptOptions = {
    PromptTitle: string?,
    GradientType: ("Gradient" | "ColorSequence")?,
    InitialGradient: (Gradient | ColorSequence)?,
    InitialColorSpace: string?,
    InitialHueAdjustment: string?,
    InitialPrecision: number?,
    OnGradientChanged: ((Gradient | ColorSequence) -> any)?
}

type ColorSequencePromptOptions = {
    PromptTitle: string?,
    InitialColor: ColorSequence?,
    OnColorChanged: ((ColorSequence) -> any)?
}

local DEFAULT_COLOR: Color = Color.new(1, 1, 1)
local DEFAULT_GRADIENT: Gradient = Gradient.fromColors(DEFAULT_COLOR)

local plugin: Plugin?
local persistentSettingsChanged: typeof(Store.changed:connect())?

local colorEditorTree: typeof(Roact.mount())?
local colorEditorWidget: DockWidgetPluginGui?
local colorEditorWidgetEnabledChanged: RBXScriptConnection?

local gradientEditorTree: typeof(Roact.mount())?
local gradientEditorWidget: DockWidgetPluginGui?
local gradientEditorWidgetEnabledChanged: RBXScriptConnection?

local unloadingBindable: BindableEvent = Instance.new("BindableEvent")
local fireColorEditorClosed: Signal.FireSignal<boolean>?
local fireGradientEditorClosed: Signal.FireSignal<boolean>?

local uiTranslations = Translator.GenerateTranslationTable({
    "ColorEditor_DefaultWindowTitle",
    "GradientEditor_DefaultWindowTitle",

    "APIScriptReparent_Message",
    "APIScriptModification_Message",
})

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

local onUnloading = function()
    if (persistentSettingsChanged) then
        persistentSettingsChanged.disconnect()
    end

    if (colorEditorWidgetEnabledChanged) then
        colorEditorWidgetEnabledChanged:Disconnect()
    end

    if (gradientEditorWidgetEnabledChanged) then
        gradientEditorWidgetEnabledChanged:Disconnect()
    end

    if (fireColorEditorClosed) then
        fireColorEditorClosed(false)
    end

    if (fireGradientEditorClosed) then
        fireGradientEditorClosed(false)
    end

    unloadingBindable:Fire()
    script:Destroy()
end

local mountColorEditor = function(promptOptions: ColorPromptOptions, fireFinished: Signal.FireSignal<boolean>)
    assert(promptOptions.PromptTitle, Util.makeBugMessage("PromptTitle is missing"))
    assert(promptOptions.InitialColor, Util.makeBugMessage("InitialColor is missing"))
    assert(colorEditorWidget, Util.makeBugMessage("Color editor widget is missing"))

    local originalColor: Color = promptOptions.InitialColor

    Store:dispatch({
        type = PluginEnums.StoreActionType.ColorEditor_SetColor,
        color = originalColor,
    })

    colorEditorTree = Roact.mount(Roact.createElement(RoactRodux.StoreProvider, {
        store = Store,
    }, {
        App = Roact.createElement(ColorEditor, {
            originalColor = originalColor,
            fireFinished = fireFinished
        })
    }), colorEditorWidget)

    colorEditorWidget.Title = promptOptions.PromptTitle
    colorEditorWidget.Enabled = true
end

local mountGradientEditor = function(promptOptions: GradientPromptOptions, promptForColorEdit: (ColorPromptOptions) -> any, fireFinished: Signal.FireSignal<boolean>)
    assert(promptOptions.PromptTitle, Util.makeBugMessage("PromptTitle is missing"))
    assert(promptOptions.InitialGradient, Util.makeBugMessage("InitialGradient is missing"))
    assert(gradientEditorWidget, Util.makeBugMessage("Gradient editor widget is missing"))

    local gradient = promptOptions.InitialGradient
    local keypoints = Util.table.deepCopy(gradient.Keypoints)

    Store:dispatch({
        type = PluginEnums.StoreActionType.GradientEditor_SetGradient,

        keypoints = keypoints,
        colorSpace = promptOptions.InitialColorSpace,
        hueAdjustment = promptOptions.InitialHueAdjustment,
        precision = promptOptions.InitialPrecision,
    })

    gradientEditorTree = Roact.mount(Roact.createElement(RoactRodux.StoreProvider, {
        store = Store,
    }, {
        App = Roact.createElement(GradientEditor, {
            originalKeypoints = keypoints,
            originalColorSpace = promptOptions.InitialColorSpace,
            originalHueAdjustment = promptOptions.InitialHueAdjustment,
            originalPrecision = promptOptions.InitialPrecision,
            fireFinished = fireFinished,

            promptForColorEdit = promptForColorEdit,
        })
    }), gradientEditorWidget)

    gradientEditorWidget.Title = promptOptions.PromptTitle
    gradientEditorWidget.Enabled = true
end

---

local ColorPane = {}
ColorPane.PromiseStatus = Promise.Status
ColorPane.PromptError = PluginEnums.PromptError
ColorPane.Unloading = unloadingBindable.Event

ColorPane.GetVersion = function(): (number, number, number)
    return table.unpack(ReleaseVersion)
end

ColorPane.IsColorEditorOpen = function(): boolean
    return (colorEditorTree and true or false)
end

ColorPane.IsGradientEditorOpen = function(): boolean
    return (gradientEditorTree and true or false)
end

local __promptForColor = function(config: ColorPromptOptions)
    assert(colorEditorWidget, Util.makeBugMessage("Color editor widget is missing"))

    local editorClosedEvent: Signal.Signal<boolean>, fireEditorClosed: Signal.FireSignal<boolean> = Signal.createSignal()

    local editPromise = Promise.new(function(resolve, reject, onCancel)
        local subscription: Signal.Subscription
        subscription = editorClosedEvent:subscribe(function(confirmed)
            subscription:unsubscribe()

            if (not confirmed) then
                -- user cancelled prompt
                reject(PluginEnums.PromptError.PromptCancelled)
            else
                local newColor = Store:getState().colorEditor.color

                if (config.ColorType == "Color3") then
                    newColor = newColor:toColor3()
                end
                
                if (newColor == config.InitialColor) then
                    -- old color is the same as the new color
                    reject(PluginEnums.PromptError.PromptCancelled)
                else
                    resolve(newColor)
                end
            end
        end)

        onCancel(function()
            subscription:unsubscribe()
        end)
    end)

    -- hook into color changes
    local storeChanged = if config.OnColorChanged then
        Store.changed:connect(function(newState, oldState)
            local color = newState.colorEditor.color
            local oldColor = oldState.colorEditor.color

            if (not (color and oldColor)) then return end
            if (color == oldColor) then return end

            if (config.ColorType == "Color3") then
                color = color:toColor3()
            end

            Util.noYield(config.OnColorChanged, color)
        end)
    else nil

    -- cleanup callback
    -- the catch is here to supress rejection via cancellation
    editPromise:catch(function() end):finally(function()
        fireColorEditorClosed = nil

        if (storeChanged) then
            storeChanged.disconnect()
        end

        Roact.unmount(colorEditorTree)
        colorEditorTree = nil
        colorEditorWidget.Enabled = false
        colorEditorWidget.Title = ""

        Store:dispatch({
            type = PluginEnums.StoreActionType.ColorEditor_SetColor,
        })
    end)

    fireColorEditorClosed = fireEditorClosed
    mountColorEditor(config, fireEditorClosed)
    return editPromise
end

ColorPane.PromptForColor = function(optionalPromptOptions: ColorPromptOptions?)
    if (ColorPane.IsColorEditorOpen()) then return Promise.reject(PluginEnums.PromptError.PromptAlreadyOpen) end
    if (ColorPane.IsGradientEditorOpen()) then return Promise.reject(PluginEnums.PromptError.ReservationProblem) end

    -- compose configuration
    local promptOptions: ColorPromptOptions = {
        PromptTitle = "Select a color",
        ColorType = "Color3",
        InitialColor = DEFAULT_COLOR,
    }

    if (type(optionalPromptOptions) == "table") then
        promptOptions = Cryo.Dictionary.join(promptOptions, optionalPromptOptions)
    elseif (type(optionalPromptOptions) ~= "nil") then
        return Promise.reject(PluginEnums.PromptError.InvalidPromptOptions)
    end

    -- validate
    local validConfig = checkColorPromptOptions(promptOptions)
    if (not validConfig) then return Promise.reject(PluginEnums.PromptError.InvalidPromptOptions) end

    -- convert InitialColor if necessary
    if (typeof(promptOptions.InitialColor) == "Color3") then
        promptOptions.InitialColor = Color.fromColor3(promptOptions.InitialColor)
    end

    return __promptForColor(promptOptions)
end

ColorPane.PromptForGradient = function(optionalPromptOptions: GradientPromptOptions?)
    assert(gradientEditorWidget, Util.makeBugMessage("Gradient editor widget is missing"))

    if (ColorPane.IsGradientEditorOpen()) then return Promise.reject(PluginEnums.PromptError.PromptAlreadyOpen) end
    if (ColorPane.IsColorEditorOpen()) then return Promise.reject(PluginEnums.PromptError.ReservationProblem) end

    -- compose configuration
    local promptOptions: GradientPromptOptions = {
        PromptTitle = uiTranslations["GradientEditor_DefaultWindowTitle"],
        GradientType = "ColorSequence",
        InitialGradient = DEFAULT_GRADIENT,
        InitialColorSpace = "RGB",
        InitialHueAdjustment = "Shorter",
        InitialPrecision = 0,
    }

    if (type(optionalPromptOptions) == "table") then
        promptOptions = Cryo.Dictionary.join(promptOptions, optionalPromptOptions)
    elseif (type(optionalPromptOptions) ~= "nil") then
        return Promise.reject(PluginEnums.PromptError.InvalidPromptOptions)
    end

    -- check if the given precision is possible
    if (promptOptions.InitialGradient and promptOptions.InitialPrecision) then
        if (Util.getUtilisedKeypoints(#promptOptions.InitialGradient.Keypoints, promptOptions.InitialPrecision) > Constants.MAX_COLORSEQUENCE_KEYPOINTS) then
            return Promise.reject(PluginEnums.PromptError.InvalidPromptOptions)
        end
    end

    -- validate
    local validConfig = checkGradientPromptOptions(promptOptions)
    if (not validConfig) then return Promise.reject(PluginEnums.PromptError.InvalidPromptOptions) end

    -- convert InitialGradient if necessary
    if (typeof(promptOptions.InitialGradient) == "ColorSequence") then
        promptOptions.InitialGradient = Gradient.fromColorSequence(promptOptions.InitialGradient)
    end

    -- prompt stuff
    local editorClosedEvent: Signal.Signal<boolean>, fireEditorClosed: Signal.FireSignal<boolean> = Signal.createSignal()

    local editPromise = Promise.new(function(resolve, reject, onCancel)
        local subscription: Signal.Subscription
        subscription = editorClosedEvent:subscribe(function(confirmed: boolean)
            subscription:unsubscribe()

            if (not confirmed) then
                -- user cancelled the prompt
                reject(PluginEnums.PromptError.PromptCancelled)
            else
                local gradient = promptOptions.InitialGradient
                local newGradient = Gradient.new(Store:getState().gradientEditor.displayKeypoints)
    
                if (promptOptions.GradientType == "ColorSequence") then
                    newGradient = newGradient:colorSequence()
                end
                
                if (newGradient == gradient) then
                    -- new gradient is the same as the old one
                    reject(PluginEnums.PromptError.PromptCancelled)
                else
                    resolve(newGradient)
                end
            end
        end)

        onCancel(function()
            subscription:unsubscribe()
        end)
    end)

    -- hook store changes
    local storeChanged = if promptOptions.OnGradientChanged then
        Store.changed:connect(function(newState, oldState)
            if (not promptOptions.OnGradientChanged) then return end

            local keypoints = newState.gradientEditor.displayKeypoints
            local oldKeypoints = oldState.gradientEditor.displayKeypoints
            if (not (keypoints and oldKeypoints)) then return end

            local gradient = Gradient.new(keypoints)
            local oldGradient = Gradient.new(oldKeypoints)
            if (gradient == oldGradient) then return end

            Util.noYield(promptOptions.OnGradientChanged, (promptOptions.GradientType == "Gradient") and gradient or gradient:colorSequence())
        end)
    else nil

    -- cleanup callback
    -- the catch is here to supress rejection via cancellation
    editPromise:catch(function() end):finally(function()
        fireGradientEditorClosed = nil

        if (storeChanged) then
            storeChanged.disconnect()
        end

        Roact.unmount(gradientEditorTree)
        gradientEditorTree = nil
        gradientEditorWidget.Enabled = false
        gradientEditorWidget.Title = ""

        Store:dispatch({
            type = PluginEnums.StoreActionType.GradientEditor_ResetState,
        })
    end)

    fireGradientEditorClosed = fireEditorClosed
    mountGradientEditor(promptOptions, __promptForColor, fireEditorClosed)
    return editPromise
end

ColorPane.init = function(pluginObj: Plugin)
    if (plugin) then return end
    plugin = pluginObj

    local newColorEditorWidget = PluginWidget("ColorEditor")
    local newGradientEditorWidget = PluginWidget("GradientEditor")

    colorEditorWidget = newColorEditorWidget
    gradientEditorWidget = newGradientEditorWidget

    EditorInputSignals.initEditorCursorPositionChanged(pluginObj, newColorEditorWidget, "ColorEditor")
    EditorInputSignals.initEditorCursorPositionChanged(pluginObj, newGradientEditorWidget, "GradientEditor")

    colorEditorWidgetEnabledChanged = newColorEditorWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
        if (newColorEditorWidget.Enabled and (not colorEditorTree)) then
            newColorEditorWidget.Enabled = false
        elseif ((not newColorEditorWidget.Enabled) and fireColorEditorClosed) then
            fireColorEditorClosed(false)
        end
    end)

    gradientEditorWidgetEnabledChanged = newGradientEditorWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
        if (newGradientEditorWidget.Enabled and (not gradientEditorTree)) then
            newGradientEditorWidget.Enabled = false
        elseif ((not newGradientEditorWidget.Enabled) and fireGradientEditorClosed) then
            fireGradientEditorClosed(false)
        end
    end)

    persistentSettingsChanged = Store.changed:connect(function(newState, oldState)
        if (newState.colorEditor.palettes ~= oldState.colorEditor.palettes) then
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

        if (newState.gradientEditor.palette ~= oldState.gradientEditor.palette) then
            local newPalette = Util.table.deepCopy(newState.gradientEditor.palette)

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

    pluginObj.Unloading:Connect(onUnloading)
end

-- DEPRECATED since v0.4
ColorPane.IsColorSequenceEditorOpen = ColorPane.IsGradientEditorOpen

-- DEPRECATED since v0.4
ColorPane.PromptForColorSequence = function(optionalPromptOptions: ColorSequencePromptOptions?)
    local promptOptions: ColorSequencePromptOptions = optionalPromptOptions or {}

    return ColorPane.PromptForGradient({
        PromptTitle = promptOptions.PromptTitle,
        GradientType = "ColorSequence",
        InitialGradient = promptOptions.InitialColor,
        OnGradientChanged = promptOptions.OnColorChanged,
    }::GradientPromptOptions)
end

---

return table.freeze(ColorPane)