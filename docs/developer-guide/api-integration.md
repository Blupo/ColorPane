The ColorPane API allows plugin developers to use ColorPane in their projects in place of creating their own pickers.

## Acquiring the API

To use the API, you need to acquire the API script. If the user has the plugin installed (and has allowed script injection), the API script will be a ModuleScript present in CoreGui, named `ColorPane`.

```lua
local ColorPane = require(game:GetService("CoreGui"):FindFirstChild("ColorPane"))
```

You can also decide to wait for the API, although you should probably notify the user that the API isn't available and give them a button to look again instead.

```lua
local CoreGui = game:GetService("CoreGui")
local ColorPane

local locateButton = ...

local locateAPI = function()
    if (ColorPane) then return end

    local apiScript = CoreGui:FindFirstChild("ColorPane")
    
    if (not (apiScript and apiScript:IsA("ModuleScript"))) then
        warn("The ColorPane API was not found, please make sure you have the plugin installed and try again.")
    else
        ColorPane = require(apiScript)
    end
end

locateButton.Activated:Connect(function()
    if (ColorPane) then return end

    locateAPI()
end)
```

## Using the API

You can view the [API reference](../../technical/api-reference/) for more information on the API examples in this page.

### Getting Colors

You can obtain colors with the [PromptForColor](../../technical/api-reference/#colorpanepromptforcolor) and [PromptForGradient](../../technical/api-reference/#colorpanepromptforgradient) functions.

!!! warning
    You must use the dot operator (`.`) when calling API functions (e.g. `ColorPane.PromptForColor` instead of `ColorPane:PromptForColor`). The API is not a class-like object.

```lua
local editPromise = ColorPane.PromptForColor({
    PromptTitle = "Hello, Roblox!",

    -- start the prompt with a random color
    InitialColor = Color3.new(math.random(), math.random(), math.random()),

    OnColorChanged = function(intermediateColor)
        -- some cool stuff
    end,
})
```

```lua
local editPromise = ColorPane.PromptForGradient({
    PromptTitle = "Hello, Roblox!",

    -- black to white gradient
    InitialGradient = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(1, 1, 1)),

    OnGradientChanged = function(intermediateGradient)
        -- some cool stuff
    end,
})
```

The prompt functions return [Promises](https://eryn.io/roblox-lua-promise/), which are used to encapsulate values that will exist in the future, but do not currently exist.

```lua
editPromise:andThen(function(newColor)
    print("Got a new color: " .. tostring(newColor))
end, function(error)
    warn(tostring(error))
end):finally(function()
    editPromise = nil
end)

-- the color is no longer relevant
editPromise:cancel()
```

If you're not familiar with the Promise workflow, you can use [`Promise.await`](https://eryn.io/roblox-lua-promise/api/Promise#await) (or [`Promise.awaitStatus`](https://eryn.io/roblox-lua-promise/api/Promise#awaitStatus)), which will yield until a value is returned, similar to the various `Async` functions in the engine.

```lua
local status, data = editPromise:awaitStatus()

if (status == ColorPane.PromiseStatus.Resolved) then
    print("Got a new color: " .. tostring(data))
elseif (status == ColorPane.PromiseStatus.Rejected) then
    warn(tostring(data))
end

editPromise = nil
```

### Unloading

You should use the [Unloading](../../technical/api-reference/#colorpaneunloading) event to clean up anything that uses ColorPane. Any Promises created with the API will automatically be cancelled.

```lua
ColorPane.Unloading:Connect(function()
    ColorPane = nil
end)
```

### Advanced Prompts

For more refined controls over how colors are handled, you can specify prompt options. For `PromptForColor`, you can refer to [`ColorPromptOptions`](../../technical/api-reference/#colorpromptoptions), but the only advanced option is specifying the type of color you receive (either a Color3 or a [Color](https://blupo.github.io/Color/api/color/)).

For `PromptForGradient`, refer to [`GradientPromptOptions`](../../technical/api-reference/#gradientpromptoptions). You can specify the details of how the gradient is constructed, and the type of gradient you receive (either a ColorSequence or a [Gradient](https://blupo.github.io/Color/api/gradient/)).

```lua
ColorPane.PromptForGradient({
    PromptTitle = "Hello, Roblox!",

    InitialGradient = ColorSequence.new(
        Color3.new(math.random(), math.random(), math.random()),
        Color3.new(math.random(), math.random(), math.random())
    ),

    InitialColorSpace = "XYZ",
    InitialPrecision = 2,
})
```