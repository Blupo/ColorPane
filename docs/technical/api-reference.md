!!! info
    The ColorPane API makes use of [Promises](https://eryn.io/roblox-lua-promise), and you should review their documentation if necessary.

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

Refers to the [Status](https://eryn.io/roblox-lua-promise/lib/#status) enum of the Promise library.

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

Returns whether the color editor is open or not. This will also return `true` if the ColorSequence editor is open.

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
ColorPane.PromptForGradient(promptOptions: ColorSequencePromptOptions?): Promise<ColorSequence>
```

Legacy alternative for [`ColorPane.PromptForGradient`](#colorpanepromptforgradient).

## Events

### ColorPane.Unloading

```
ColorPane.Unloading: Signal
```

Fires when the API is unloading. You should use this event to clean up any scripts that use ColorPane.

## PromptOption Types

### ColorPromptOptions

```
{
    PromptTitle: string?,
    ColorType: string?,
    InitialColor: (Color | Color3)?,
    OnColorChanged: ((Color | Color3) -> nil)?
}
```

### GradientPromptOptions

```
{
    PromptTitle: string?,
    GradientType: string?,
    InitialGradient: (Gradient | ColorSequence)?,
    InitialColorSpace: string?,
    InitialHueAdjustment: string?,
    InitialPrecision: number?,
    OnGradientChanged: ((Gradient | ColorSequence) -> nil)?
}
```

### ColorSequencePromptOptions

```
{
    PromptTitle: string?,
    InitialColor: ColorSequence?,
    OnColorChanged: ((ColorSequence) -> nil)?
}
```