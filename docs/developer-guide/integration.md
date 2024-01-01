# Integration

--8<-- "docs/developer-guide/dev-guide-note.md"

There are two ways to integrate ColorPane into your plugin: communicating directly with the API, or using the provided proxy module. We'll be using the proxy module in this guide; if you want to communicate directly with the API, you'll have to do it yourself.

You can grab a copy of the module on the Asset Marketplace [here]() (TODO), or grab the code directly from the [GitHub repo](https://github.com/Blupo/ColorPane/blob/main/extern/ColorPane.lua).

## Using the Proxy

The proxy module is set up to structure API calls like using [`HttpService.RequestAsync`](https://create.roblox.com/docs/reference/engine/classes/HttpService#RequestAsync): you need to check the status of the request before you can do anything with the response.

For example, let's say you want to check if the color editor is open. Because the state of the color editor resides with the plugin, and not the proxy, we need to send a request to the plugin to get that information. This request might fail, however, for various reasons.

``` {.lua .copy}
local Proxy = require(...)
local response = Proxy.IsColorEditorOpen()

-- we need to check if request succeeded first
if (response.Success) then
    -- everything went according to plan
    local isColorEditorIsOpen = response.Body
else
    -- something went wrong
    warn(response.StatusMessage)
end
```

The function `IsColorEditorOpen` returns a [ProxyResponse](proxy-reference.md#proxyresponse), which will tell you if the request succeeded, and a message stored in `ProxyResponse.StatusMessage` if it didn't. If the request *did* succeed, the value the plugin returned is stored in `ProxyResponse.Body`, as seen in the example above.

## Getting Colors

/// note
Familiarity with the promise pattern, as well as the specific Promises from evaera's [roblox-lua-promise](https://eryn.io/roblox-lua-promise/) library, is recommended. While some explanation is given here, the additional reading may help you.
///

To prompt the user for colors, you will use [`PromptForColor`](proxy-reference.md#promptforcolor). This function has configuration that you can pass, but it's optional.

``` {.lua .copy}
local response = Proxy.PromptForColor({
    PromptTitle = "Pick a color!"
    InitialColor = Color3.new(0.5, 0.5, 0.5),
})

local colorPromise = response.Success and response.Body
if (not colorPromise) then return end
```

These two options are the most common. `PromptTitle` sets what the window text says, and `InitialColor` sets what color the user starts with (in this case, grey).

<img alt="Color picker window with custom title and color" style="max-width: 60%;" src="../../images/integration-colorpromptoptions-example.png">

If the request succeeds, the plugin will return something called a Promise. If you're familiar with Promises in JavaScript, these will be similar. If you're not, examples of how to use them will be shown here.

The basic idea is that a Promise represents a value that will be given *in the future*. That Promise will either be fulfilled (resolved), or broken (rejected). In our case, if the Promise resolves, it will resolve with a [Color3](https://create.roblox.com/docs/reference/engine/datatypes/Color3), and if it rejects, it will do so with an error object or message, depending on where the rejection came from.

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

If you don't need (or want) to use the Promise pattern, you can use `Promise:await()` to turn it into a synchronous function (like what [`task.wait`](https://create.roblox.com/docs/reference/engine/libraries/task#wait) does). The function will return values in the same manner as [`pcall`](https://create.roblox.com/docs/reference/engine/globals/LuaGlobals#pcall): the first value tells you if the Promise resolved, and then any other values the Promise resolves/rejects with.

``` {.lua .copy}
local resolved, value = response:await()

if (resolved) then
    -- do stuff with the color
else
    -- do stuff with the error
end
```

## Getting Gradients

All the same rules apply as the [previous section](#getting-colors) for getting colors. To prompt the user for gradients, you'll use [`PromptForGradient`](proxy-reference.md#promptforgradient). The configuration options are slightly different here, and the Promise will resolve with a [ColorSequence](https://create.roblox.com/docs/reference/engine/datatypes/ColorSequence).

``` {.lua .copy}
local response = Proxy.PromptForGradient({
    PromptTitle = "Pick a gradient!",
    InitialGradient = ColorSequence.new(
        Color3.new(0, 0, 0),
        Color3.new(1, 1, 1)
    )
})

local gradientPromise = response.Success and response.Body
if (not gradientPromise) then return end

-- your code here
```

## Advanced

### Previewing Changes

An additional configuration option, `OnColorChanged` for [`PromptForColor`](proxy-reference.md#promptforcolor) and `OnGradientChanged` for [`PromptForGradient`](proxy-reference.md#promptforgradient), lets you "preview" color changes. This option is a callback that will be called every time the user makes a modification to the color or gradient. This is useful for letting the user see their changes before committing to them.

The callbacks you pass **must not** yield, meaning that you can't use `task.wait()`, `RBXScriptSignal:Wait()`, `Instance:WaitForChild()` or any other function that yields or suspends a thread.

``` {.lua .copy}
Proxy.PromptForColor({
    InitialColor = Color3.new(1, 1, 1),

    OnColorChanged = function(color)
        -- your code here
    end,
})

Proxy.PromptForGradient({
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

### Advanced Color Stuctures

If you're familiar with the [Color](https://blupo.github.io/Color/) library, the API also allows you to prompt for these types of colors instead of [Color3s](https://create.roblox.com/docs/reference/engine/datatypes/Color3) and [ColorSequences](https://create.roblox.com/docs/reference/engine/datatypes/ColorSequence). Note that this will also affect the types of the values passed to `OnColorChanged`/`OnGradientChanged`.

``` {.lua .copy}
Proxy.PromptForColor({
    ColorType = "Color",
})  -- Will resolve with a Color instead of a Color3

Proxy.PromptForGradient({
    GradientType = "Gradient",
})  -- Will resolve with a Gradient instead of a Gradient
```

For Gradients, you can also specify the options used for generating intermediate colors:

``` {.lua .copy}
Proxy.PromptForGradient({
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