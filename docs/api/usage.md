## Acquiring the API

The API is exposed through a ModuleScript named `ColorPane` that is dropped into the [CoreGui](https://developer.roblox.com/api-reference/class/CoreGui) once the plugin has been initialised.

```lua
local CoreGui = game:GetService("CoreGui")

-- this
local ColorPane = require(CoreGui:WaitForChild("ColorPane"))

-- or maybe this
CoreGui.ChildAdded(function(child)
    if ((child.Name == "ColorPane") and child:IsA("ModuleScript")) then
        ColorPane = require(child)
    end
end)
```

## Getting Colors

You can obtain colors with the [PromptForColor](../reference#colorpanepromptforcolor) and [PromptForColorSequence](../reference#colorpanepromptforcolorsequence) functions. You can also pass options to them (refer to [PromptOptions](../reference#promptoptions)) to modify the prompt and subscribe to color changes.

```lua
local editPromise = ColorPane:PromptForColor({
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

## Unloading

You should use the [Unloading](../reference#colorpaneunloading) event to clean up anything that uses ColorPane, with some exceptions that will be cleaned up automatically noted below.

```lua
ColorPane.Unloading:Connect(function()
    ColorPane = nil
end)
```

!!! info
    Any open prompts will be closed and their associated Promises will be cancelled automatically, and any connections to Unloading will be disconnected automatically.

## Example: ColorProps

[ColorProps](https://www.roblox.com/library/6494015679) is companion plugin to ColorPane that lets you edit the color properties of objects. You can [view its source code](https://github.com/Blupo/ColorProps) if you want to learn more about how to use ColorPane.