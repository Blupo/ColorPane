# ColorPane

--8<-- "docs/developer-guide/dev-guide-note.md"

## Types

### ColorPromptOptions

<pre><code>type ColorPromptOptions = {
    PromptTitle: string?,
    ColorType: ("Color" | "Color3")?,
    InitialColor: (<a href="https://blupo.github.io/Color/api/color/">Color</a> | <a href="https://create.roblox.com/docs/reference/engine/datatypes/Color3">Color3</a>)?,
    OnColorChanged: ((<a href="https://blupo.github.io/Color/api/color/">Color</a> | <a href="https://create.roblox.com/docs/reference/engine/datatypes/Color3">Color3</a>) -> nil)?
}</code></pre>

`ColorType` determines the type of value returned through the Promise and the value passed to `OnColorChanged`.

### GradientPromptOptions

<pre><code>type GradientPromptOptions = {
    PromptTitle: string?,
    GradientType: ("Gradient" | "ColorSequence")?,
    InitialGradient: (<a href="https://blupo.github.io/Color/api/gradient/">Gradient</a> | <a href="https://create.roblox.com/docs/reference/engine/datatypes/ColorSequence">ColorSequence</a>)?,
    InitialColorSpace: <a href="https://blupo.github.io/Color/api/color/#colormix">ColorType</a>?,
    InitialHueAdjustment: <a href="https://blupo.github.io/Color/api/color/#colormix">HueAdjustment</a>?,
    InitialPrecision: number?,
    OnGradientChanged: ((<a href="https://blupo.github.io/Color/api/gradient">Gradient</a> | <a href="https://create.roblox.com/docs/reference/engine/datatypes/ColorSequence">ColorSequence</a>) -> nil)?
}</code></pre>

`GradientType` determines the type of value returned through the Promise and the value passed to `OnGradientChanged`.

### ColorSequencePromptOptions

<pre><code>type ColorSequencePromptOptions = {
    PromptTitle: string?
    InitialColor: <a href="https://create.roblox.com/docs/reference/engine/datatypes/ColorSequence">ColorSequence</a>?
    OnColorChanged: ((<a href="https://create.roblox.com/docs/reference/engine/datatypes/ColorSequence">ColorSequence</a>) -> any)?
}</code></pre>

## Functions

### GetVersion

```
ColorPane.GetVersion(): (number, number, number)
```

Returns the major, minor, and patch versions of the API.

### IsColorEditorOpen

```
ColorPane.IsColorEditorOpen(): boolean
```

### IsColorSequenceEditorOpen

/// warning | Deprecated
Since v0.4.0
///

```
ColorPane.IsColorSequenceEditorOpen(): boolean
```

Alias for [`IsGradientEditorOpen`](#isgradienteditoropen).

### IsGradientEditorOpen

```
ColorPane.IsGradientEditorOpen(): boolean
```

### PromptForColor

<pre><code>ColorPane.PromptForColor(options: <a href="#colorpromptoptions">ColorPromptOptions</a>?):
    <a href="https://eryn.io/roblox-lua-promise/api/Promise">Promise</a>&lt;<a href="https://blupo.github.io/Color/api/Color">Color</a> | <a href="https://create.roblox.com/docs/reference/engine/datatypes/ColorSequence">Color3</a>&gt;</code></pre>

Prompts for a color. Will return a Promise that resolves with a Color or Color3, depending on `options.ColorType`. The default configuration is:

```
{
    PromptTitle = "Select a color",
    ColorType = "Color3",
    InitialColor = Color.new(1, 1, 1),
    OnColorChanged = nil
}
```

### PromptForColorSequence

/// warning | Deprecated
Since v0.4.0
///

<pre><code>ColorPane.PromptForColorSequence(options: <a href="#colorsequencepromptoptions">ColorSequencePromptOptions</a>?):
    <a href="">Promise</a>&lt;<a href="https://create.roblox.com/docs/reference/engine/datatypes/ColorSequence">ColorSequence</a>&gt;</code></pre>

### PromptForGradient

<pre><code>ColorPane.PromptForGradient(options: <a href="#gradientpromptoptions">GradientPromptOptions</a>?):
    <a href="https://eryn.io/roblox-lua-promise/api/Promise">Promise</a>&lt;<a href="https://blupo.github.io/Color/api/gradient/">Gradient</a> | <a href="https://create.roblox.com/docs/reference/engine/datatypes/Color3">ColorSequence</a>&gt;</code></pre>

Prompts for a gradient. Will return a Promise that resolves with a Gradient or ColorSequence, depending on `options.GradientType`. The default configuration is:

```
{
    PromptTitle = "Create a gradient",
    GradientType = "ColorSequence",
    InitialGradient = Gradient.fromColors(Color.new(1, 1, 1)),
    InitialColorSpace = "RGB",
    InitialHueAdjustment = "Shorter",
    InitialPrecision = 0,
}
```

## Events

### Unloading

```
ColorPane.Unloading: Signal<nil>
```

Fires when the API is about to be unloaded.