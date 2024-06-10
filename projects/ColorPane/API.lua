--!strict

local root = script.Parent
local Common = root.Common

local CommonModules = Common.Modules
local CommonEnums = require(CommonModules.Enums)
local Constants = require(CommonModules.Constants)
local PluginProvider = require(CommonModules.PluginProvider)
local Window = require(CommonModules.Window)

local CommonIncludes = Common.Includes
local Cryo = require(CommonIncludes.Cryo)
local Promise = require(CommonIncludes.Promise)
local Roact = require(CommonIncludes.RoactRodux.Roact)
local Signal = require(CommonIncludes.Signal)

local Includes = root.Includes
local ColorLib = require(Includes.Color)

local Modules = root.Modules
local APITypeValidators = require(Modules.APITypeValidators)
local EditorInputSignals = require(Modules.EditorInputSignals)
local ManagedUserData = require(Modules.ManagedUserData)
local Enums = require(Modules.Enums)
local Store = require(Modules.Store)
local Util = require(Modules.Util)
local WidgetInfo = require(Modules.WidgetInfo)

local Components = root.Components
local ColorEditorComponent = require(Components.ColorEditor)
local GradientEditorComponent = require(Components.GradientEditor)

local Color = ColorLib.Color
local Gradient = ColorLib.Gradient

---

type Promise = typeof(Promise.new())

type Color = ColorLib.Color
type Gradient = ColorLib.Gradient
type GradientKeypoint = ColorLib.GradientKeypoint
type MixableColorType = ColorLib.MixableColorType
type HueAdjustment = ColorLib.HueAdjustment

type ColorPromptInfoArgument = {
    PromptTitle: string?,
    InitialColor: (Color | Color3)?,
    ColorType: ("Color" | "Color3")?,
    OnColorChanged: (((Color) -> ()) | ((Color3) -> ()))?
}

type ColorPromptInfoExpectingColor = {
    PromptTitle: string,
    InitialColor: (Color | Color3),
    ColorType: "Color",
    OnColorChanged: ((Color) -> ())?
}

type ColorPromptInfoExpectingColor3 = {
    PromptTitle: string,
    InitialColor: (Color | Color3),
    ColorType: "Color3",
    OnColorChanged: ((Color3) -> ())?
}

type ColorPromptInfo = ColorPromptInfoExpectingColor | ColorPromptInfoExpectingColor3

type GradientPromptInfoArgument = {
    PromptTitle: string?,
    InitialGradient: (Gradient | ColorSequence)?,
    InitialColorSpace: MixableColorType?,
    InitialHueAdjustment: HueAdjustment?,
    InitialPrecision: number?,
    GradientType: ("Gradient" | "ColorSequence")?,
    OnGradientChanged: (((Gradient) -> ()) | ((ColorSequence) -> ()))?
}

type GradientPromptInfoExpectingGradient = {
    PromptTitle: string,
    InitialGradient: (Gradient | ColorSequence),
    InitialColorSpace: MixableColorType,
    InitialHueAdjustment: HueAdjustment,
    InitialPrecision: number,
    GradientType: "Gradient",
    OnGradientChanged: ((Gradient) -> ())?
}

type GradientPromptInfoExpectingColorSequence = {
    PromptTitle: string,
    InitialGradient: (Gradient | ColorSequence),
    InitialColorSpace: MixableColorType,
    InitialHueAdjustment: HueAdjustment,
    InitialPrecision: number,
    GradientType: "ColorSequence",
    OnGradientChanged: ((ColorSequence) -> ())?
}

type GradientPromptInfo = GradientPromptInfoExpectingGradient | GradientPromptInfoExpectingColorSequence

type ColorSequencePromptInfoArgument = {
    PromptTitle: string?,
    InitialColor: ColorSequence?,
    OnColorChanged: ((ColorSequence) -> ())?
}

---

local DEFAULT_COLOR_PROMPT_INFO: ColorPromptInfo = {
    PromptTitle = "Select a color",
    ColorType = "Color3",
    InitialColor = Color3.new(1, 1, 1),
}

local DEFAULT_GRADIENT_PROMPT_INFO: GradientPromptInfo = {
    PromptTitle = "Create a gradient",
    GradientType = "ColorSequence",
    InitialGradient = ColorSequence.new(Color3.new(1, 1, 1)),
    InitialColorSpace = "RGB",
    InitialHueAdjustment = "Shorter",
    InitialPrecision = 0,
}

local plugin: Plugin = PluginProvider()

local colorEditorWindow: Window.Window = Window.new(WidgetInfo.ColorEditor.Id, WidgetInfo.ColorEditor.Info)
local gradientEditorWindow: Window.Window = Window.new(WidgetInfo.GradientEditor.Id, WidgetInfo.GradientEditor.Info)

local fireColorEditFinished: Signal.FireSignal<boolean> = function(_: boolean) end
local fireGradientEditFinished: Signal.FireSignal<boolean> = function(_: boolean) end

--[[
    This is the actual color prompting function.
]]
local __promptForColor = function(promptInfo: ColorPromptInfoArgument?): Promise
    local fullPromptInfo: ColorPromptInfo = Cryo.Dictionary.join(DEFAULT_COLOR_PROMPT_INFO, promptInfo or {})
    local finishedSignal: Signal.Signal<boolean>, fireFinished: Signal.FireSignal<boolean> = Signal.createSignal()
    local initialColor: Color
    
    -- Colors are used internally, so we need to convert the user-provided color
    do
        local unconvertedInitialColor: Color | Color3 = fullPromptInfo.InitialColor

        if (typeof(unconvertedInitialColor) == "Color3") then
            initialColor = Color.fromColor3(unconvertedInitialColor)
        else
            initialColor = unconvertedInitialColor
        end
    end

    local editPromise = Promise.new(function(resolve, reject, onCancel)
        local subscription: Signal.Subscription

        subscription = finishedSignal:subscribe(function(confirmed: boolean)
            subscription:unsubscribe()

            if (confirmed) then
                local newColor: Color = Store:getState().colorEditor.color

                -- if the user provided an initial color, we need to check if the new color is the same
                if (promptInfo and (promptInfo.InitialColor ~= nil) and (newColor == initialColor)) then
                    reject(Enums.PromptRejection.SameAsInitial)
                    return
                end

                if (fullPromptInfo.ColorType == "Color3") then
                    (resolve::(Color3) -> ())(newColor:toColor3())
                else
                    (resolve::(Color) -> ())(newColor)
                end
            else
                reject(Enums.PromptRejection.PromptCancelled)
            end
        end)

        onCancel(function()
            subscription:unsubscribe()
        end)
    end)

    local colorEditorElement = Roact.createElement(ColorEditorComponent, {
        originalColor = initialColor,
        fireFinished = fireFinished,
    })

    -- set up prompt state
    Store:dispatch({
        type = Enums.StoreActionType.ColorEditor_SetColor,
        color = initialColor,
    })

    -- check for color changes
    local storeChanged = if (fullPromptInfo.OnColorChanged) then
        Store.changed:connect(function(newState, oldState)
            local oldColor: Color? = oldState.colorEditor.color
            local newColor: Color? = newState.colorEditor.color
            if (not (oldColor and newColor)) then return end
            if (newColor == oldColor) then return end

            if (fullPromptInfo.ColorType == "Color3") then
                (fullPromptInfo.OnColorChanged::(Color3) -> ())(newColor:toColor3())
            elseif (fullPromptInfo.ColorType == "Color") then
                (fullPromptInfo.OnColorChanged::(Color) -> ())(newColor)
            end
        end)
    else nil

    -- the catch is here to suppress rejection if the user closes the editor
    editPromise:catch(function() end):finally(function()
        if (storeChanged) then
            storeChanged:disconnect()
        end

        colorEditorWindow:unmount(true)

        Store:dispatch({
            type = Enums.StoreActionType.ColorEditor_SetColor,
            color = nil,
        })
    end)

    fireColorEditFinished = fireFinished
    colorEditorWindow:mount(fullPromptInfo.PromptTitle, colorEditorElement, Store)
    return editPromise
end

---

local ColorPane = {}

--[[
    Prompt rejection enum
]]
ColorPane.PromptRejection = Enums.PromptRejection

--[[
    Promise status enum
]]
ColorPane.PromiseStatus = Promise.Status

--[[
    Returns if a request to prompt for a color will succeed
    instead of immediately rejecting.
]]
ColorPane.IsColorPromptAvailable = function(): boolean
    return (not colorEditorWindow:isMounted())
end

--[[
    Returns if a request to prompt for a gradient will succeed
    instead of immediately rejecting.
]]
ColorPane.IsGradientPromptAvailable = function(): boolean
    return (not (colorEditorWindow:isMounted() or gradientEditorWindow:isMounted()))
end

--[[
    Prompts the user for a color. The prompt info table is as follows:

    ```
    {
        PromptTitle: string?,
        InitialColor: (Color | Color3)?,
        ColorType: ("Color" | "Color3"),
        OnColorChanged: (((Color) -> ()) | ((Color3) -> ()))?
    }
    ```

    `OnColorChanged` must not yield.

    The specified `ColorType` and the type parameter to `OnColorChanged` should match, i.e.
    - `ColorType` is `"Color3"`, and `OnColorChanged` accepts a `Color3`, or
    - `ColorType` is `"Color"`, and `OnColorChanged` accepts a `Color`

    but not
    - `ColorType` is `"Color3"`, and `OnColorChanged` accepts a `Color`, nor
    - `ColorType` is `"Color"`, and `OnColorChanged` accepts a `Color3`

    @param promptInfo The prompt info, see above
    @return A Promise that will resolve with a user-generated color, or reject with a rejection reason
]]
ColorPane.PromptForColor = function(promptInfo: ColorPromptInfoArgument?): Promise
    if (gradientEditorWindow:isMounted()) then
        -- can't open the prompt because the gradient prompt might need it
        return Promise.reject(Enums.PromptRejection.ReservationProblem)
    elseif (colorEditorWindow:isMounted()) then
        -- can't open the prompt if it's already open
        return Promise.reject(Enums.PromptRejection.PromptAlreadyOpen)
    end

    local isPromptInfoValid: boolean = APITypeValidators.ColorPromptInfoArgument(promptInfo)

    if (not isPromptInfoValid) then
        return Promise.reject(Enums.PromptRejection.InvalidPromptOptions)
    end

    return __promptForColor(promptInfo)
end

--[[
    Prompts the user for a gradient. The prompt info table is as follows:

    ```
    {
        PromptTitle: string?,
        InitialGradient: (Gradient | ColorSequence)?,
        InitialColorSpace: MixableColorType?,
        InitialHueAdjustment: HueAdjustment?,
        InitialPrecision: number?,
        GradientType: ("Gradient" | "ColorSequence")?,
        OnGradientChanged: (((Gradient) -> ()) | ((ColorSequence) -> ()))?
    }
    ```

    `OnGradientChanged` must not yield.

    The specified `GradientType` and the type parameter to `OnGradientChanged` should match, i.e.
    - `GradientType` is `"ColorSequence"`, and `OnGradientChanged` accepts a `ColorSequence`, or
    - `GradientType` is `"Gradient"`, and `OnGradientChanged` accepts a `Gradient`

    but not
    - `GradientType` is `"ColorSequence"`, and `OnGradientChanged` accepts a `Gradient`, nor
    - `GradientType` is `"Gradient"`, and `OnGradientChanged` accepts a `ColorSequence`.

    @param promptInfo The prompt info, see above
    @return A Promise that will resolve with a user-generated gradient, or reject with a rejection reason
]]
ColorPane.PromptForGradient = function(promptInfo: GradientPromptInfoArgument?): Promise
    if (colorEditorWindow:isMounted()) then
        -- can't open the prompt because it might need the color prompt
        return Promise.reject(Enums.PromptRejection.ReservationProblem)
    elseif (gradientEditorWindow:isMounted()) then
        -- can't open the prompt if it's already open
        return Promise.reject(Enums.PromptRejection.PromptAlreadyOpen)
    end

    local isPromptInfoValid: boolean = APITypeValidators.GradientPromptInfoArgument(promptInfo)

    if (not isPromptInfoValid) then
        return Promise.reject(Enums.PromptRejection.InvalidPromptOptions)
    end

    local fullPromptInfo: GradientPromptInfo = Cryo.Dictionary.join(DEFAULT_GRADIENT_PROMPT_INFO, promptInfo or {})
    local finishedSignal: Signal.Signal<boolean>, fireFinished: Signal.FireSignal<boolean> = Signal.createSignal()

    local initialGradient: Gradient
    local initialKeypoints: {GradientKeypoint}

    -- Gradients are used internally, so we need to convert the user-provided gradient
    do
        local unconvertedInitialGradient: Gradient | ColorSequence = fullPromptInfo.InitialGradient

        if (typeof(unconvertedInitialGradient) == "ColorSequence") then
            initialGradient = Gradient.fromColorSequence(unconvertedInitialGradient)
        else
            initialGradient = unconvertedInitialGradient
        end

        initialKeypoints = initialGradient.Keypoints
    end

    local isKeypointPrecisionCombinationValid: boolean =
        Util.getUtilisedKeypoints(#initialKeypoints, fullPromptInfo.InitialPrecision)
            <=
        Constants.MAX_COLORSEQUENCE_KEYPOINTS

    if (not isKeypointPrecisionCombinationValid) then
        return Promise.reject(Enums.PromptRejection.InvalidPromptOptions)
    end

    local editPromise = Promise.new(function(resolve, reject, onCancel)
        local subscription: Signal.Subscription

        subscription = finishedSignal:subscribe(function(confirmed: boolean)
            subscription:unsubscribe()

            if (confirmed) then
                local newKeypoints: {GradientKeypoint} = Store:getState().gradientEditor.keypoints
                local newGradient: Gradient = Gradient.new(newKeypoints)

                -- if the user provided an initial gradient, we need to check if the new gradient is the same
                if (promptInfo and (promptInfo.InitialGradient ~= nil) and (newGradient == initialGradient)) then
                    reject(Enums.PromptRejection.SameAsInitial)
                    return
                end

                if (fullPromptInfo.GradientType == "ColorSequence") then
                    (resolve::(ColorSequence) -> ())(newGradient:toColorSequence())
                else
                    (resolve::(Gradient) -> ())(newGradient)
                end
            else
                reject(Enums.PromptRejection.PromptCancelled)
            end
        end)

        onCancel(function()
            subscription:unsubscribe()
        end)
    end)

    local gradientEditorElement = Roact.createElement(GradientEditorComponent, {
        originalKeypoints = initialKeypoints,
        originalColorSpace = fullPromptInfo.InitialColorSpace,
        originalHueAdjustment = fullPromptInfo.InitialHueAdjustment,
        originalPrecision = fullPromptInfo.InitialPrecision,
        fireFinished = fireFinished,

        promptForColorEdit = __promptForColor,
    })

    -- set up prompt state
    Store:dispatch({
        type = Enums.StoreActionType.GradientEditor_SetGradient,

        keypoints = initialKeypoints,
        colorSpace = fullPromptInfo.InitialColorSpace,
        hueAdjustment = fullPromptInfo.InitialHueAdjustment,
        precision = fullPromptInfo.InitialPrecision,
    })

    -- check for color changes
    local storeChanged = if (fullPromptInfo.OnGradientChanged) then
        Store.changed:connect(function(newState, oldState)
            local oldKeypoints: {GradientKeypoint}? = oldState.gradientEditor.displayKeypoints
            local newKeypoints: {GradientKeypoint}? = newState.gradientEditor.displayKeypoints
            if (not (oldKeypoints and newKeypoints)) then return end
            
            local oldGradient: Gradient = Gradient.new(oldKeypoints)
            local newGradient: Gradient = Gradient.new(newKeypoints)
            if (oldGradient == newGradient) then return end

            if (fullPromptInfo.GradientType == "ColorSequence") then
                (fullPromptInfo.OnGradientChanged::(ColorSequence) -> ())(newGradient:toColorSequence())
            elseif (fullPromptInfo.GradientType == "Gradient") then
                (fullPromptInfo.OnGradientChanged::(Gradient) -> ())(newGradient)
            end
        end)
    else nil

    -- the catch is here to suppress rejection if the user closes the editor
    editPromise:catch(function() end):finally(function()
        if (storeChanged) then
            storeChanged:disconnect()
        end

        gradientEditorWindow:unmount(true)

        Store:dispatch({
            type = Enums.StoreActionType.GradientEditor_ResetState,
        })
    end)

    fireGradientEditFinished = fireFinished
    gradientEditorWindow:mount(fullPromptInfo.PromptTitle, gradientEditorElement, Store)
    return editPromise
end

--[[
    **DEPRECATED**: You should subscribe to your project's `Plugin.Unloading` event instead.

    Fires when the API is about to unload
]]
ColorPane.Unloading = Instance.new("BindableEvent").Event

--[[
    **DEPRECATED**: Use `ColorPane.PromptRejection` instead

    Prompt rejection enum
]]
ColorPane.PromptError = Enums.PromptRejection

--[[
    **DEPRECATED**: Use `ColorPane.PromptForGradient` instead.
    
    Prompts the user for a ColorSequence. The prompt info table is as follows:

    ```
    {
        PromptTitle: string?,
        InitialColor: ColorSequence?,
        OnColorChanged: ((ColorSequence) -> ())?
    }
    ```

    @param promptInfo The prompt info, see above
    @return A Promise that will resolve with a user-generated ColorSequence, or reject with a rejection reason
]]
ColorPane.PromptForColorSequence = function(promptInfo: ColorSequencePromptInfoArgument?): Promise
    return ColorPane.PromptForGradient({
        PromptTitle = promptInfo and promptInfo.PromptTitle,
        InitialGradient = promptInfo and promptInfo.InitialColor,
        GradientType = "ColorSequence",
        OnGradientChanged = promptInfo and promptInfo.OnColorChanged,
    })
end

--[[
    **DEPRECATED**: Use `ColorPane.IsColorPromptAvailable` instead.
]]
ColorPane.IsColorEditorOpen = function(): boolean
    return colorEditorWindow:isMounted()
end

--[[
    **DEPRECATED**: Use `ColorPane.IsGradientPromptAvailable` instead.
]]
ColorPane.IsGradientEditorOpen = function(): boolean
    return gradientEditorWindow:isMounted()
end

--[[
    **DEPRECATED**: Use `ColorPane.IsGradientPromptAvailable` instead.
]]
ColorPane.IsColorSequenceEditorOpen = function(): boolean
    return gradientEditorWindow:isMounted()
end

---

-- make sure the user doesn't accidentally modify these
table.freeze(Enums.PromptRejection)
table.freeze(ColorPane)

-- hook editor input signals
colorEditorWindow:enableMouseTracking()
gradientEditorWindow:enableMouseTracking()

colorEditorWindow.mousePositionChanged:subscribe(EditorInputSignals.ColorEditor.MousePositionChanged.Fire)
gradientEditorWindow.mousePositionChanged:subscribe(EditorInputSignals.GradientEditor.MousePositionChanged.Fire)

Store.changed:connect(function(newState, oldState)
    -- update non-palette user data
    if (newState.userData ~= oldState.userData) then
        for key: string, value: any in pairs(newState.userData) do
            ManagedUserData:setValue(key, value)
        end
    end

    -- update color palettes
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

        ManagedUserData:setValue(CommonEnums.UserDataKey.UserColorPalettes, newPalettes)
    end

    -- update gradient palettes
    if (newState.gradientEditor.palettes ~= oldState.gradientEditor.palettes) then
        local newPalettes = Util.table.deepCopy(newState.gradientEditor.palettes)

        for i = 1, #newPalettes do
            local palette = newPalettes[i]
            local gradients = palette.gradients

            for j = 1, #gradients do
                local gradient = gradients[j]
                local keypoints = gradient.keypoints

                for k = 1, #keypoints do
                    local keypoint = keypoints[k]

                    keypoints[k] = {
                        time = keypoint.Time, 
                        color = {keypoint.Color:components()}
                    }
                end
            end
        end

        ManagedUserData:setValue(CommonEnums.UserDataKey.UserGradientPalettes, newPalettes)
    end
end)

-- color editor must stay closed when unmounted
colorEditorWindow.openedWithoutMounting:subscribe(function()
    colorEditorWindow:close()
end)

-- gradient editor must stay closed when unmounted
gradientEditorWindow.openedWithoutMounting:subscribe(function()
    gradientEditorWindow:close()
end)

-- user closing the color editor is the same as cancelling the prompt
colorEditorWindow.closedWithoutUnmounting:subscribe(function()
    fireColorEditFinished(false)
end)

-- user closing the gradient editor is the same as cancelling the prompt
gradientEditorWindow.closedWithoutUnmounting:subscribe(function()
    fireGradientEditFinished(false)
end)

plugin.Unloading:Connect(function()
    fireColorEditFinished(false)
    fireGradientEditFinished(false)

    colorEditorWindow:destroy()
    gradientEditorWindow:destroy()
end)

return ColorPane