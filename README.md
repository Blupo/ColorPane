# ColorPane

ColorPane is a suite of color tools for Roblox Studio plugins. Some of the tools included are:

- A color editor with a color wheel, several types of sliders, and various color palettes, with the ability to create, import, and export your own palettes.
- A gradient editor, similar to the Studio editor, with some quality-of-life changes including keypoint snapping, buttons to swap keypoint colors around, and a gradient palette.

## Restructuring for v0.5

Previously, ColorPane was a singular plugin, and using its color editing tools requires a complicated process akin to sending web requests. The original reason for doing this was to ensure that there was a single "source of truth" for settings and palettes. Several developers trying to integrate ColorPane into their projects ended up shoving the whole plugin in their project folders, which was not the intended design.

In v0.5, however, I'm moving away from this approach to make it easier for plugin developers to use ColorPane's tools. For the new structure of the project, keep reading below.

## The Library (if you want to add ColorPane to your project)

The library is the core of ColorPane, and includes all the color tools. You can include this project using Rojo, or grab it from the marketplace (TBA). It consists of a ModuleScript that you need to call to initialise the tools:

```lua
local InitialiseColorPane = require(...)
local ColorPane = InitialiseColorPane(plugin, "YourProjectId")
```

You can then use the tools using the API (TBA).

## The Plugins (if you want to use ColorPane)

### Companion

The Companion plugin takes up the previous ColorPane plugin's responsibility of syncing settings and palettes. Though not required, installing it will allow you to create and save palettes and other settings, and is *highly* recommended. Without it, palette creation will be disabled, and settings changes will not persist between Studio sessions. It also includes buttons to test the color tools like the old plugin did.

You can install it from the marketplace (TBA).

### Color Properties

Color Properties was a functionality integrated into the previous ColorPane plugin that allowed users to modify the color properties of objects using the color tools. This functionality will be spun off into its own plugin, as it originally was when ColorPane first released.