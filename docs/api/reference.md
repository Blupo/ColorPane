!!! info
    The ColorPane API makes use of [Promises](https://eryn.io/roblox-lua-promise), and you should review their documentation if necessary.

## Properties

### ColorPane.PromiseStatus

```
ColorPane.PromiseStatus: Status
```

Refers to the [Status](https://eryn.io/roblox-lua-promise/lib/#status) enum of the Promise library.

## Functions

### ColorPane.IsColorEditorOpen

```
ColorPane.IsColorEditorOpen(): boolean
```

Returns whether the color editor is open or not. This will also return `true` if the ColorSequence editor is open.

### ColorPane.IsColorSequenceEditorOpen

```
ColorPane.IsColorSequenceEditorOpen(): boolean
```

Returns whether the ColorSequence editor is open or not.

### ColorPane.PromptForColor

```
ColorPane.PromptForColor(promptOptions: PromptOptions?): Promise
```

Prompts the user for a color. Returns a Promise that will resolve with a [Color3](https://developer.roblox.com/en-us/api-reference/datatype/Color3), or reject if *either* prompt is already open. Cancelling the Promise will close the prompt and a value will not be returned.

### ColorPane.PromptForColorSequence

```
ColorPane.PromptForColorSequence(promptOptions: PromptOptions?): Promise
```

Prompts the user for a color. Returns a Promise that will resolve with a [ColorSequence](https://developer.roblox.com/en-us/api-reference/datatype/ColorSequence), or reject if the prompt is already open. Cancelling the Promise will close the prompt and a value will not be returned.

## Events

### ColorPane.Unloading

```
ColorPane.Unloading: RBXScriptSignal()
```

Fires when the API is unloading. You should use this event to clean up any scripts that use ColorPane.

## PromptOptions

`PromptOptions` is a table with the following type annotation:

```
{
    PromptTitle: string?,
    InitialColor: (Color3 | ColorSequence)?,
    OnColorChanged: ((Color3 | ColorSequence) -> nil)?,
}
```

The data type in `InitialColor` and `OnColorChanged` will depend on which prompt function you call.

- `PromptTitle` sets the title of the prompt window
- `InitialColor` sets the starting color value of the prompt
- `OnColorChanged` is a function that is called whenever the user changes the color value in the prompt

!!! warning
    `OnColorChanged` must not yield.