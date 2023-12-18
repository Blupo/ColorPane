# Integration

:::note
This guide is intended for plugin developers who want to integrate ColorPane into their projects. If you simply want to use the plugin, read [the user guide](/docs/user-guide/color-editor).
:::

There are two ways to integrate ColorPane into your plugin: communicate directly with the API, or use the proxy module. We'll be going over the second option in this tutorial.

## Using the Proxy

```lua
local ColorPaneProxy = require(...)
```

The proxy functions will return response objects, which tell if you if the function call was success, and information of any errors.

```lua
local response = ColorPaneProxy.PromptForColor(...)

if (not response.Success) then
    warn(string.format(
        "[ColorPane.Proxy] Call failed, got status \"%s\" and message \"%s\"",
        response.Status,
        response.StatusMessage
    ))
else
    local colorPromise = response.Body
end
```

## Getting Colors (and Gradients)



## Unloading

