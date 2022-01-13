The ColorPane API allows plugin developers to use ColorPane in their projects in place of creating their own pickers.

!!! info
    You only need to use this page if a third-party plugin is asking for access to ColorPane. The ColorPane API and Roblox API data for [Color Properties](../color-properties/) are not related, and you do not need to use the ColorPane API to use Color Properties.

## Injecting the API

Injecting the API involves adding a ModuleScript to CoreGui, which requires script injection. As the user, you can control when you allow the API to be used with the *Inject API* toolbar button, and you can also allow this on start-up with the *Automatically inject the ColorPane API script on startup* setting. If you have multiple installations of ColorPane, only one installation can inject its API script.

!!! attention
    You will be prompted by Studio to allow script injection the first time you want to use the API. Denying this permission will not allow third-party plugins to use ColorPane.

## Usage

Read the [API reference](../../technical/api-reference/) if you want more information on the functions presented in this section.

### Acquiring the API

The API is added to the CoreGui as a ModuleScript named `ColorPane`. As mentioned above, injection of the API script is controlled by the user, so this script may not be available when your plugin starts, and may never become available if the user doesn't have ColorPane installed or never allows API injection.

```lua
local CoreGui = game:GetService("CoreGui")

-- this
local ColorPane = require(CoreGui:WaitForChild("ColorPane"))

-- or maybe this
CoreGui.ChildAdded:Connect(function(child)
    if ((child.Name == "ColorPane") and child:IsA("ModuleScript")) then
        ColorPane = require(child)
    end
end)
```

### Getting Colors

You can obtain colors with the [PromptForColor](../../technical/api-reference/#colorpanepromptforcolor) and [PromptForGradient](../../technical/api-reference/#colorpanepromptforgradient) functions. You can also pass options to them (refer to [PromptOptions](../../technical/api-reference/#promptoption-types)) to modify the prompt and subscribe to color changes.

!!! attention
    You **must** use the dot operator (`.`) when calling functions from the API.

```lua
local editPromise = ColorPane.PromptForColor({
    PromptTitle = "Hello, Roblox!",

    -- start the prompt with a random color
    InitialColor = Color3.new(
        math.random(),
        math.random(),
        math.random()
    ),

    OnColorChanged = function(intermediateColor)
        -- some cool stuff
    end
})
```

The functions return [Promises](https://eryn.io/roblox-lua-promise/), which allows you to ask for colors without yielding, and you can cancel them if obtaining a color is no longer important.

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

### Unloading

You should use the [Unloading](../../technical/api-reference/#colorpaneunloading) event to clean up anything that uses ColorPane. Any Promises created from the API will automatically be cancelled.

```lua
ColorPane.Unloading:Connect(function()
    ColorPane = nil
end)
```