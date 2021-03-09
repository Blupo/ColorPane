![The color editor](../images/all-editors.png)

The color editor has several components to it:

[TOC]

If the editor window is large enough, then the color wheel, sliders, and palettes will be shown at the same time, otherwise you can use the button bar at the right of the window to pick which one to view. By default, the window is only large enough to show the wheel and sliders.

Outside of being used in a plugin, you can use the plugin toolbar to bring up the color editor at any time.

## Color Wheel

![Color wheel](../images/color-wheel.png)

The color wheel is an [HSB](https://wikipedia.org/wiki/HSL_and_HSV) color wheel with a square for the Saturation and Brightness. There is a button bar at the bottom for basic color harmonies. The main color markers are denoted as circles, while any harmonies are denoted as squares.

## Sliders

![RGB sliders](../images/rgb-sliders.png)

There are 6 types of sliders:

- RGB
- CMYK
- HSB
- HSL
- Monochrome (black-and-white)
- Temperature
    - Lets you pick colors corresponding to Kelvin temperatures, with some presets. Implementation is based on [neilbartlett's color-temperature](https://github.com/neilbartlett/color-temperature).

## Palettes

![The palettes view](../images/palettes.png)

Palettes let you store lists of colors. The overflow menu lets you create, delete, rename, and duplicate palettes.

You can use the search bar to filter colors, and you can use the ![plus](../images/plus.png) button to add colors to the palette. Clicking on a color will select it, which allows you to use the color options:

- The *Set Color* button will set the current color to the selected color (you can also double-click on a color to do this)
- The ![minus](../images/minus.png) button will remove the color from the palette
- The ![left](../images/left.png) and ![right](../images/right.png) buttons will move the color around the list
- You can rename the color using the text box

ColorPane includes two built-in palettes:

- A BrickColor palette
- A page for the [ColorBrewer](https://colorbrewer2.org) palettes (clicking on a color in the ColorBrewer page will immediately set the current color instead of selecting it)

!!! info
    You cannot create a palette with any of the following names, as they correspond to the names of built-in palettes (case in-sensitive):

    - BrickColor
    - BrickColors
    - ColorBrewer

## Quick Palette

![The quick palette](../images/quick-palette.png)

The quick palette at the bottom of the window lets you temporarily store colors for quick access. The ![plus](../images/plus.png) button will add the current color, and clicking on a color will set the current color.

!!! info
    The quick palette will display as many colors as the size of the window can accomodate, and stores up to 99. If you add more colors after the 99th, colors will be removed from the end of the list to accommodate.

## Comparison and Hex Input

![The comparison and hex input](../images/tools.png)

The comparison square shows the current and starting colors (on the top and bottom respectively), with the Quick Palette next to it. If you ever need to start over, you can click on the starting color to reset. The hex input accepts either 3 (`ABC` = `AABBCC`) or 6 (`ABCDEF`) digits.