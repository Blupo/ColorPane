# Integration

:::note
This guide is intended for plugin developers who want to integrate ColorPane into their projects. If you simply want to use the plugin, read [the user guide](/docs/user-guide/color-editor).
:::

There are two ways to integrate ColorPane into your plugin: communicating directly with the API, or using the provided proxy module. We'll be using the proxy module in this guide; if you want to communicate directly with the API, you'll have to do it yourself.

## Using the Proxy

```lua
local ColorPaneProxy = require(...)
```

The proxied functions (`IsColorEditorOpen`, `IsGradientEditorOpen`, `PromptForColor`, and `PromptForGradient`) will return [`ProxyResponse`](/api/Proxy#ProxyResponse) objects, which tell you if the function call was successful, and information of any errors. The function parameters are the same as the functions they mirror.

```lua
local response = ColorPaneProxy.PromptForColor(...)

if (not response.Success) then
    warn(string.format(
        "[ColorPane Proxy] Call failed, got status \"%s\" and message \"%s\"",
        response.Status,
        response.StatusMessage
    ))
else
    local colorPromise = response.Body
end
```

## Getting Colors (and Gradients)

To get colors, call the `PromptForColor` function. It takes a table with configuration options, which has this type annotation (simplifed):

```
{
    PromptTitle: string?,
    InitialColor: Color3?,
    OnColorChanged: ((Color3) -> any)?
}
```

For example, if you wanted to get a color, and the initial color is white:

```lua
local response = ColorPaneProxy.PromptForColor({
    InitialColor = Color3.new(1, 1, 1),
})
```

If you want to change what the color picker window text says:

```lua
local response = ColorPaneProxy.PromptForColor({
    PromptText = "Pick a color!",
    InitialColor = Color3.new(1, 1, 1),
})
```

Finally, if you want to respond to color changes as the user edits the color:

```lua
local response = ColorPaneProxy.PromptForColor({
    PromptText = "Pick a color!",
    InitialColor = Color3.new(1, 1, 1),

    OnColorChanged = function(color)
        print("Color was changed: " .. tostring(color))
    end
})
```

:::warning
If you use `OnColorChanged`, the function **must not** yield.
:::

If the call doesn't fail, the `Body` of the response will contain a Promise that will resolve with the new color, or reject if if there was a problem.

## Unloading

