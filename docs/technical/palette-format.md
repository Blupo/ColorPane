When [importing](../../user-guide/color-editor/#import) palettes, they must follow this JSON format:

```json
{
    "name": "Palette Name",
    
    "colors": [
        {
            "name": "Color Name",
            "color": [0, 0, 0]
        },

        {
            "name": "Another Color Name",
            "color": [0.5, 0.5, 0.5]
        },

        {
            "name": "Yet Another Color Name",
            "color": [1, 1, 1]
        }
    ]
}
```

The color array of each color object is a 3-element array representing the RGB channels, which range from [0, 1]. No two colors can share the same name, however any number of colors have have the same color array.

If importing from a ModuleScript, the palette can also be a Lua table representation of the above format, i.e.

```lua
{
    name = "Palette Name",
    
    colors = {
        {
            name = "Color Name",
            color = {0, 0, 0}
        },

        {
            name = "Another Color Name",
            color = {0.5, 0.5, 0.5}
        },

        {
            name = "Yet Another Color Name",
            color = {1, 1, 1}
        }
    }
}
```