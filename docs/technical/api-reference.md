!!! info
    The ColorPane API makes use of [Promises](https://eryn.io/roblox-lua-promise), and you should review their documentation if necessary.

## Types

### ColorPromptOptions

```
{
    PromptTitle: string?,
    ColorType: ("Color3" | "Color")?,
    InitialColor: (Color | Color3)?,
    OnColorChanged: ((Color | Color3) -> nil)?
}
```

Currently, the type of `InitialColor` and the value of `ColorType` must match. This will be changed in a future update.

- `OnColorChanged` must **not** yield.

### ColorSequencePromptOptions

```
{
    PromptTitle: string?,
    InitialColor: ColorSequence?,
    OnColorChanged: ((ColorSequence) -> nil)?
}
```

- `OnColorChanged` must **not** yield.

### GradientPromptOptions

```
{
    PromptTitle: string?,
    GradientType: ("ColorSequence" | "Gradient")?,
    InitialGradient: (Gradient | ColorSequence)?,
    InitialColorSpace: string?,
    InitialHueAdjustment: string?,
    InitialPrecision: number?,
    OnGradientChanged: ((Gradient | ColorSequence) -> nil)?
}
```

Currently, the type of `InitialGradient` and the value of `GradientType` must match. This will be changed in a future update.

- `OnGradientChanged` must **not** yield.
- `InitialColorSpace` refers to the one of the color spaces used by [Color.mix](https://blupo.github.io/Color/api/color/#colormix).
- `InitialHueAdjustment` refers to the one of the hue adjustments used by [Color.mix](https://blupo.github.io/Color/api/color/#colormix).
- `InitialPrecision` refers to the "precision" of the gradient, or how visually-accurate you want it to be. This currently ranges from 0-18, but the maximum precision depends on the number of keypoints in the gradient.
    - Specifically, the maximum precision for `k` keypoints, with maximum `km` keypoints (currently 20) is `math.floor((km - 1) / (k - 1)) - 1`

### PromptError

```
{
    InvalidPromptOptions: "InvalidPrompt",
    PromptAlreadyOpen: "PromptAlreadyOpen",
    ReservationProblem: "ReservationProblem"
}
```

## Properties

### ColorPane.PromptError

```
ColorPane.PromptError: PromptError
```

If a prompt cannot be opened, a PromptError will be the value passed through the Promise. It has the following items:

- `InvalidPromptOptions`, if the options passed to the prompt function are invalid (e.g. trying to pass a Color3 value to the `InitialGradient` key of GradientPromptOptions).
- `PromptAlreadyOpen`, which should be self-explanatory.
- `ReservationProblem`, if you either try to prompt for a color and the gradient editor is already open, or you try to prompt for a gradient and the color editor is already open.

### ColorPane.PromiseStatus

```
ColorPane.PromiseStatus: Status
```

Refers to the [Status](https://eryn.io/roblox-lua-promise/api/Promise#Status) enum of the Promise library.

## Functions

### ColorPane.GetVersion

```
ColorPane.GetVersion(): (number, number, number)
```

Returns the version of ColorPane release, following [semantic versioning](https://semver.org/). This should be used if your applications requires certain versions of ColorPane to function properly.

### ColorPane.IsColorEditorOpen

```
ColorPane.IsColorEditorOpen(): boolean
```

Returns whether the color editor is open or not.

### ColorPane.IsGradientEditorOpen

```
ColorPane.IsGradientEditorOpen(): boolean
```

Returns whether the gradient editor is open or not.

### ColorPane.IsColorSequenceEditorOpen

<img src="https://img.shields.io/badge/-deprecated-orange" alt="Deprecated function" />

Alias for [`ColorPane.IsGradientEditorOpen`](#colorpaneisgradienteditoropen)

### ColorPane.PromptForColor

```
ColorPane.PromptForColor(promptOptions: ColorPromptOptions?): Promise<Color | Color3 | PromptError>
```

Prompts the user for a color. Returns a Promise that will resolve with either a [Color](https://blupo.github.io/Color/api/color/) or [Color3](https://developer.roblox.com/en-us/api-reference/datatype/Color3), or immediately reject if either the color editor or gradient editor prompts are already open. If the user closes the prompt without submitting a color, the Promise will be cancelled.

### ColorPane.PromptForGradient

```
ColorPane.PromptForGradient(promptOptions: GradientPromptOptions?): Promise<Gradient | ColorSequence | PromptError>
```

Prompts the user for a gradient. Returns a Promise that will resolve with either a [Gradient](https://blupo.github.io/Color/api/gradient/) or [ColorSequence](https://developer.roblox.com/en-us/api-reference/datatype/ColorSequence), or immediately reject if the prompt is already open. If the user closes the prompt without submitting a gradient, the Promise will be cancelled.

### ColorPane.PromptForColorSequence

<img src="https://img.shields.io/badge/-deprecated-orange" alt="Deprecated function" />

```
ColorPane.PromptForColorSequence(promptOptions: ColorSequencePromptOptions?): Promise<ColorSequence | PromptError>
```

Legacy alternative for [`ColorPane.PromptForGradient`](#colorpanepromptforgradient). Equivalent to:

```lua
ColorPane.PromptForGradient({
    PromptTitle = promptOptions.PromptTitle,
    GradientType = "ColorSequence",
    InitialGradient = promptOptions.InitialColor,
    OnGradientChanged = promptOptions.OnColorChanged,
})
```

## Events

### ColorPane.Unloading

```
ColorPane.Unloading: Signal
```

Fires when the API is unloading. You should use this event to clean up any scripts that use ColorPane.