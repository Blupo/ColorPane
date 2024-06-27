# ColorPane

--8<-- "docs/developer-guide/dev-guide-note.md"

## Types

### ColorPromptOptions

<pre><code>type ColorPromptOptions = {
    PromptTitle: string?,
    InitialColor: (<a href="https://blupo.github.io/Color/api/color/">Color</a> | <a href="https://create.roblox.com/docs/reference/engine/datatypes/Color3">Color3</a>)?,
    ColorType: ("Color" | "Color3")?,
    OnColorChanged: (((<a href="https://blupo.github.io/Color/api/color/">Color</a>) -> ()) | ((<a href="https://create.roblox.com/docs/reference/engine/datatypes/Color3">Color3</a>) -> ()))?
}</code></pre>

`ColorType` determines the type of value the Promise will resolve with, and the type of value passed to `OnColorChanged`.

### GradientPromptOptions

<pre><code>type GradientPromptOptions = {
    PromptTitle: string?,
    InitialGradient: (<a href="https://blupo.github.io/Color/api/gradient/">Gradient</a> | <a href="https://create.roblox.com/docs/reference/engine/datatypes/ColorSequence">ColorSequence</a>)?,
    InitialColorSpace: <a href="https://blupo.github.io/Color/api/color/#colormix">MixableColorType</a>?,
    InitialHueAdjustment: <a href="https://blupo.github.io/Color/api/color/#colormix">HueAdjustment</a>?,
    InitialPrecision: number?,
    GradientType: ("Gradient" | "ColorSequence")?,
    OnGradientChanged: (((<a href="https://blupo.github.io/Color/api/gradient/">Gradient</a>) -> ()) | ((<a href="https://create.roblox.com/docs/reference/engine/datatypes/ColorSequence">ColorSequence</a>) -> ()))?
}</code></pre>

`GradientType` determines the type of value the Promise will resolve with, and the type of value passed to `OnGradientChanged`.

## Enums

### PromptRejection

```
{
    InvalidPromptOptions,
    PromptAlreadyOpen,
    ReservationProblem,
    PromptCancelled,
    SameAsInitial
}
```

* `PromptRejection.InvalidPromptOptions`: One or more of the prompt configuration options was invalid (bad value, wrong type, etc.)
* `PromptRejection.PromptAlreadyOpen`: The prompt you were trying to open is already open
* `PromptRejection.ReservationProblem`: If you were trying to open the color prompt, then the gradient prompt is currently open. If you were trying to open the gradient prompt, the color prompt is currently open.
* `PromptRejection.PromptCancelled`: The user closed the prompt without confirming a color/gradient
* `PromptRejection.SameAsInitial`: If you provided an initial color/gradient value, the user confirmed the exact same value

### PromiseStatus

Same as [`Promise.Status`](https://eryn.io/roblox-lua-promise/api/Promise#Status).

```
{
    Started,
    Resolved,
    Rejected,
    Cancelled
}
```

## Functions

### IsColorPromptAvailable

<pre><code>ColorPane.IsColorPromptAvailable(): boolean</code></pre>

Returns if a request to prompt for a color will succeed instead of immediately rejecting.

### IsGradientPromptAvailable

<pre><code>ColorPane.IsGradientPromptAvailable(): boolean</code></pre>

Returns if a request to prompt for a gradient will succeed instead of immediately rejecting.

### PromptForColor

<pre><code>ColorPane.PromptForColor(options: <a href="#colorpromptoptions">ColorPromptOptions</a>?): Promise</code></pre>

Prompts the user for a color.

``` {.lua .copy}
local colorPromise = ColorPane.PromptForColor({
    PromptTitle = "Hello, world!",
    InitialColor = Color3.new(0.1, 0.2, 0.3),

    ColorType = "Color3",
    OnColorChanged = print,
})
```

`OnColorChanged` must not yield. The specified `ColorType` and the type parameter to `OnColorChanged` should match, i.e.

- `ColorType` is `"Color3"`, and `OnColorChanged` accepts a `Color3`, or
- `ColorType` is `"Color"`, and `OnColorChanged` accepts a `Color`

but not

- `ColorType` is `"Color3"`, and `OnColorChanged` accepts a `Color`, nor
- `ColorType` is `"Color"`, and `OnColorChanged` accepts a `Color3`

### PromptForGradient

<pre><code>ColorPane.PromptForGradient(options: <a href="#gradientpromptoptions">GradientPromptOptions</a>?): Promise</code></pre>

Prompts the user for a gradient.

``` {.lua .copy}
local gradientPromise = ColorPane.PromptForGradient({
    PromptTitle = "Hello, world!",
    InitialGradient = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(1, 1, 1)),

    GradientType = "ColorSequence",
    OnGradientChanged = print,
})
```

`OnGradientChanged` must not yield. The specified `GradientType` and the type parameter to `OnGradientChanged` should match, i.e.

- `GradientType` is `"ColorSequence"`, and `OnGradientChanged` accepts a `ColorSequence`, or
- `GradientType` is `"Gradient"`, and `OnGradientChanged` accepts a `Gradient`

but not

- `GradientType` is `"ColorSequence"`, and `OnGradientChanged` accepts a `Gradient`, nor
- `GradientType` is `"Gradient"`, and `OnGradientChanged` accepts a `ColorSequence`.