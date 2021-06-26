## Unreleased

### Added
- Added the ability to import palettes from ModuleScripts, StringValues, JSON files, or URLs
- Added the ability to export palettes as ModuleScripts or StringValues
- Users will now be notified at startup if their version of ColorPane is out-of-date, with the option to disable this in the Settings
- Added a palette showing variations of the selected color, including hues, shades, tints, and tones
- Added a [Copic](https://copic.jp/en/) color palette

### Fixed
- Fixed a bug that occurred when the API script was modified while the API wasn't loaded
- Fixed a bug where trying to use the scroll wheel on the palette page picker would break the palettes page if the user didn't have any User Palettes

## [0.2.1] - 2021-03-29
### Fixed
- The Color Properties window no longer tries to load in testing modes
- The Color Properties window will now show the loading screen if it is enabled on startup instead of being blank

## [0.2.0] - 2021-03-29
### Added
- Added a Settings window
- Integrated the functionality of ColorProps into ColorPane, with the option to automatically load the window at startup in the Settings
- You can now view palettes in either a grid or list layout
- Added a palette of [web colors](https://www.w3.org/TR/2020/WD-css-color-4-20201112/#named-colors)
- Added sections to the palette list to distinguish between built-in and user-created palettes
- Added an editor page that lets you copy/paste between different color types

### Changed
- API loading is no longer occurs at startup by default, the user must now explicitly load it or set the option to automatically load it in the Settings
- Color Properties: You can now click anywhere inside a property list item to edit the color, not just on the item's color indicator
- Changed the behaviour of the palette grid double-click shortcut: clicking on the color at any time after it has been selected will set the current color, not just within the amount of time that would be considered a "double click"
- When searching for a palette color, if the selected color is included in the filtered list, it will now stay selected instead of being deselected
- You will now be asked to input a name *before* creating new palettes, with the option to disable this in the Settings
- The palette naming prompt will now show you what the actual new name will be if the inputted name is already being used

### Fixed
- The titles of the editor windows now reset to an identifiable name once they are closed
- Setting the initial prompt value when calling `PromptForColor` no longer causes `OnColorChanged` to be called
- Improved the performance of multiple components, the effects of which will be particularly noticable when resizing editor windows or using the palettes page
- The editor page bar in the color editor window now correctly highlights the currently-chosen editor page
- Editor pages in the color editor now have the proper minimum width, previously the calculations did not take padding into account and ended up making them slightly smaller than the minimum
- Fixed improper behaviour in the color wheel due to some misplaced code: the color value should have updated when the left mouse button was pressed down on the saturation-brightness square, however it occurred when the mouse button was released instead
- If you close the Color Properties window while editing a property, the color editor window(s) should now close

### Removed
- Removed the undocumented `OpenColorEditor` function from the API
- Removed the name restrictions on user-created palettes

## [0.1.2] - 2021-03-10
### Added
- Added a toolbar button that lets the user attempt to drop the API script into CoreGui if it could not be done automatically
- Added toolbar button icons
- Added a warning when modifying the API script's Source

### Changed
- Updated and fixed some documentation
- Changed the name of the color editor toolbar button to "Color Editor" (from just "Editor")

### Removed
- Removed the undocumented `OpenColorSequenceEditor` function from the API (`OpenColorEditor` will be removed in future update)

## [0.1.1] - 2021-03-09
### Changed
- Now gracefully handles script injection

## [0.1.0] - 2021-03-09
### Added
- ColorPane first release