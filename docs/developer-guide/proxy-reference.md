# Proxy

--8<-- "docs/developer-guide/dev-guide-note.md"

## Types

### ResponseStatus

```
type ResponseStatus = "NoError"
    | "NoAPIConnection"
    | "APIError"
    | "IncompatibilityError"
    | "UnknownError"
```

Value | Description
----- | -----------
`"NoError"` | The request completed successfully.
`"NoAPIConnection"` | The API is not available.
`"APIError"` | There was a problem communicating with the API.
`"IncompatibilityError"` | This version of the proxy is incompatible with the user's ColorPane installation.
`"UnknownError"` | An unknown error occurred.

### ProxyResponse

<pre><code>type ProxyResponse&lt;T&gt; = {
    Success: boolean,
    Status: <a href="#responsestatus">ResponseStatus</a>,
    StatusMessage: string,
    Body: T?
}</code></pre>

## Functions

### GetVersion

`Proxy.GetVersion(): (number, number, number)`

Returns the major, minor, and patch version of the proxy.

### IsAPIConnected

`Proxy.IsAPIConnected(): boolean`

Returns if the proxy is connected to ColorPane.

### IsColorEditorOpen

<code>Proxy.IsColorEditorOpen(): <a href="#proxyresponse">ProxyResponse</a>&lt;boolean&gt;</code>

Resolves with whether or not the color editor is open. See [`ColorPane.IsColorEditorOpen`](api-reference.md#iscoloreditoropen) for more information.

### IsGradientEditorOpen

<code>Proxy.IsGradientEditorOpen(): <a href="#proxyresponse">ProxyResponse</a>&lt;boolean&gt;</code>

Resolves with whether or not the gradient editor is open. See [`ColorPane.IsGradientEditorOpen`](api-reference.md#isgradienteditoropen) for more information.

### PromptForColor

<pre><code>Proxy.PromptForColor(options: <a href="../api-reference/#colorpromptoptions">ColorPromptOptions</a>?):
    <a href="#proxyresponse">ProxyResponse</a>&lt;<a href="https://eryn.io/roblox-lua-promise/api/Promise">Promise</a>&lt;<a href="https://blupo.github.io/Color/api/Color">Color</a> | <a href="https://create.roblox.com/docs/reference/engine/datatypes/ColorSequence">Color3</a>&gt;&gt;</code></pre>

Prompts for a color. Resolves with a Promise that will resolve with a Color or Color3. See [`ColorPane.PromptForColor`](api-reference.md#promptforcolor) for more information.

### PromptForGradient

<pre><code>Proxy.PromptForGradient(options: <a href="../api-reference/#gradientpromptoptions">GradientPromptOptions</a>?):
    <a href="#proxyresponse">ProxyResponse</a>&lt;<a href="https://eryn.io/roblox-lua-promise/api/Promise">Promise</a>&lt;<a href="https://blupo.github.io/Color/api/gradient/">Gradient</a> | <a href="https://create.roblox.com/docs/reference/engine/datatypes/Color3">ColorSequence</a>&gt;&gt;</code></pre>

Prompts for a gradient. Resolves with a Promise that will resolve with a Gradient or ColorSequence. See [`ColorPane.PromptForGradient`](api-reference.md#promptforcolor) for more information.

## Events

### Unloading

`Proxy.Unloading: RBXScriptSignal<nil>`

Fires when the API connection is about to be severed.