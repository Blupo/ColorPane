# Integration

--8<-- "docs/developer-guide/dev-guide-note.md"

First, you'll need to grab the module from the [Creator Store](https://create.roblox.com/store/asset/17844182825). If you use [Rojo](https://rojo.space), you can alternatively add the [GitHub repo](https://github.com/Blupo/ColorPane) as a submodule.

## Initialisation

Before we can start getting colors and gradients, we need to initialise the API. To do that, we'll simply call the function returned by the library script, which will give us the API.

``` {.lua .copy}
local ColorPaneInit = require(path.to.library)
local ColorPane = ColorPaneInit(plugin, "MyProjectId")
```

The parameters for the initialisation function are (1) a [Plugin](https://create.roblox.com/docs/reference/engine/classes/Plugin) object and (2) a unique identifier, used to make sure each instance of ColorPane has its own plugin windows.

## Getting Colors

/// note
Familiarity with the promise pattern, as well as the specific Promises from evaera's [roblox-lua-promise](https://eryn.io/roblox-lua-promise/) library, is recommended. While some explanation is given here, the additional reading may help you.
///

To prompt the user for colors, you will use [`PromptForColor`](api-reference.md#promptforcolor).

``` {.lua .copy}
local colorPromise = ColorPane.PromptForColor({
    PromptTitle = "Pick a color!"
    InitialColor = Color3.new(0.5, 0.5, 0.5),
})
```

To customise the prompt, you can pass a table of options. The two options specified here are the most common. `PromptTitle` sets what the window text says, and `InitialColor` sets what color the user starts with (grey in this example).

![Color picker window with custom title and color (dark theme)](../images/integration-colorpromptoptions-example-dark.png#only-dark){ width="500" }
![Color picker window with custom title and color (light theme)](../images/integration-colorpromptoptions-example-light.png#only-light){ width="500" }

The API will return a Promise. The basic idea is that a Promise represents a value that will be given *in the future*. That Promise will either be fulfilled (resolved), or broken (rejected). In this example, if the Promise resolves, it will resolve with a [Color3](https://create.roblox.com/docs/reference/engine/datatypes/Color3), and if it rejects, it will reject with an error object or message, depending on where the rejection came from.

We can attach callbacks onto the Promise to handle resolutions and rejections with `Promise:andThen()`.

``` {.lua .copy}
colorPromise
    :andThen(function(color)
        -- This function is called when the Promise resolves
    end, function(err)
        -- This function is called when the Promise rejects
    end)
```

The Promise may reject for a variety of reasons, including:

- You passed some bad options into the function (e.g. setting `InitialColor` to a string)
- The color editor is already open
- The user decides to close the prompt without selecting a color

If you don't want or need to use the Promise pattern, you can use `Promise:await()` to turn it into a synchronous function (a yielding function, like [`task.wait`](https://create.roblox.com/docs/reference/engine/libraries/task#wait)). The function will return values in the same manner as [`pcall`](https://create.roblox.com/docs/reference/engine/globals/LuaGlobals#pcall): the first value tells you if the Promise resolved, and then any other values the Promise resolves/rejects with.

``` {.lua .copy}
local resolved, value = colorPromise:await()

if (resolved) then
    -- do stuff with the color
else
    -- do stuff with the error
end
```

## Getting Gradients

The same rules for Promises apply here as they do for getting colors. To prompt the user for gradients, you'll use [`PromptForGradient`](api-reference.md#promptforgradient). The configuration options are slightly different here, and in this example, the Promise will resolve with a [ColorSequence](https://create.roblox.com/docs/reference/engine/datatypes/ColorSequence).

``` {.lua .copy}
local gradientPromise = ColorPane.PromptForGradient({
    PromptTitle = "Pick a gradient!",
    InitialGradient = ColorSequence.new(
        Color3.new(0, 0, 0),
        Color3.new(1, 1, 1)
    )
})

gradientPromise:andThen(function(gradient)
    -- resolved
end, function(err)
    -- rejected
end)
```

## Advanced

### Previewing Changes

An additional configuration option, `OnColorChanged` for [`PromptForColor`](api-reference.md#promptforcolor) and `OnGradientChanged` for [`PromptForGradient`](api-reference.md#promptforgradient), lets you "preview" color changes. This option is a callback that will be called every time the user makes a modification to the color or gradient. This is useful for letting the user see their changes before committing to them.

The callbacks you pass **must not** yield, meaning that you can't use [`task.wait()`](https://create.roblox.com/docs/reference/engine/libraries/task#wait), [`RBXScriptSignal:Wait()`](https://create.roblox.com/docs/reference/engine/datatypes/RBXScriptSignal#Wait), [`Instance:WaitForChild()`](https://create.roblox.com/docs/reference/engine/classes/Instance#WaitForChild) or any other function that yields or suspends a thread.

``` {.lua .copy}
ColorPane.PromptForColor({
    InitialColor = Color3.new(1, 1, 1),

    OnColorChanged = function(color)
        -- your code here
    end,
})

ColorPane.PromptForGradient({
    InitialGradient = ColorSequence.new(
        Color3.new(0, 0, 0),
        Color3.new(1, 1, 1)
    ),

    OnGradientChanged = function(gradient)
        -- your code here
    end,
})
```

/// warning
The values passed to `OnColorChanged`/`OnGradientChanged` are for **temporary use only**. If the user cancels color selection, anything you've changed with the preview colors should be changed back to their original values.
///

### Alternate Color Objects

If you're familiar with the [Color](https://blupo.github.io/Color/) library, the API also allows you to prompt for these types of colors instead of [Color3s](https://create.roblox.com/docs/reference/engine/datatypes/Color3) and [ColorSequences](https://create.roblox.com/docs/reference/engine/datatypes/ColorSequence). Note that this will also affect the types of the values passed to `OnColorChanged`/`OnGradientChanged`.

``` {.lua .copy}
ColorPane.PromptForColor({
    ColorType = "Color",
})  -- Will resolve with a Color instead of a Color3

ColorPane.PromptForGradient({
    GradientType = "Gradient",
})  -- Will resolve with a Gradient instead of a ColorSequence
```

For Gradients, you can also specify the options used for generating intermediate colors:

``` {.lua .copy}
ColorPane.PromptForGradient({
    GradientType = "Gradient",
    InitialGradient = Gradient.fromColors(
        Color.new(0, 0, 0),
        Color.new(1, 1, 1)
    ),

    InitialColorSpace = "Lab",
    InitialHueAdjustment = "Longer",
    InitialPrecision = 0,
})
```

## Plugin Permissions

ColorPane includes some functionality that requires certain plugin permissions. These permissions are not required, and the core functionality of ColorPane will still work without them. Your plugin itself, however, may need these permissions to work, and ColorPane will also be able to use them if granted.

* Script injection
    * Exporting palettes into the DataModel as a ModuleScript
* HTTP requests
    * The Picular palette sends HTTP requests to [backend.picular.co](https://backend.picular.co)
    * Importing palettes via URL, which can be from *any* domain