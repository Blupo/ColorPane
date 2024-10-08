## [0.5.0] - 2024-08-13

### Added
- Added partial translations for French (`fr`), Korean (`ko`), and Russian (`ru`)
- Color editor: Added a dedicated "Set Color" button for colors in the palette list layout
- Color editor: Added a random color button
- Gradient editor: Added a "Reset" button for gradient precision
- Companion: Added settings importing and exporting
- API: Added `API.IsColorPromptAvailable` to check if calling `API.PromptForColor` will succeed or immediately reject (replaces `API.IsColorEditorOpen`)
- API: Added `API.IsGradientPromptAvailable` to check if calling `API.PromptForGradient` will succeed or immediately reject (replaces `API.IsGradientEditorOpen`)

### Changed
- Script injection is no longer a required plugin permission
- Settings: Invalid palettes will no longer cause the entire list of palettes to be removed, just the invalid palettes
- Color editor: Duplicating palettes with the same name will now create or increment a counter instead of naming it "Palette (1) (1) (1) ..."
- Color Properties: Changing color properties now uses the [Recording API](https://devforum.roblox.com/t/2512500)
- API: Promises from the API no longer cancel if the user closes the prompt, they will now instead reject with `PromptError.PromptCancelled`
- API: For `GradientPromptOptions`, the type of `InitialGradient` and the value of `GradientType` are no longer required to match
- API: For `ColorPromptOptions`, the type of `InitialColor` and the value of `ColorType` are no longer required to match
- API: The `API.PromptError` enum has been re-named to `API.PromptRejection`
- API: The `API.PromptForColor` Promise now rejects with `SameAsInitial` instead of `PromptCancelled` if the initial and new colors are the same
- API: The `API.PromptForGradient` Promise now rejects with `SameAsInitial` instead of `PromptCancelled` if the initial and new gradients are the same
- API: The color tools of ColorPane have been spun off into their own library, and the old method of using ColorPane will no longer work. Please read the Integration page of the documentation for details on the updated integration method.

### Fixed
- API: `API.PromptForColorSequence` (deprecated) now returns a Promise as expected
- API: Promises returned by `API.PromptForColor` will no longer reject when the initial and new colors are the same even though you didn't specify an initial color
- API: Promises returned by `API.PromptForGradient` will no longer reject when the initial and new gradients are the same even though you didn't specify an initial gradient

### Deprecated
- API: `API.IsColorEditorOpen` is now deprecated, please use `API.IsColorPromptAvailable` for new work
- API: `API.IsGradientEditorOpen` is now deprecated, please use `API.IsGradientPromptAvailable` for new work
- API: `API.PromptError` is now deprecated, please use `API.PromptRejection` for new work
- API: `API.Unloading` is now deprecated, you should use your plugin's [Unloading](https://create.roblox.com/docs/reference/engine/classes/Plugin#Unloading) event instead
- API: `API.GetVersion` is now deprecated

### Removed
- Removed the first-time use plugin permissions warning
- Automatic update-checking has been removed
- Color editor: Removed the Copic color palette

## [0.4.1] - 2022-09-30

### Fixed
- Fixed a bug where the HSL saturation and lightness sliders would only show a red hue (this is *purely* a visual bug and did not affect color selection)

## [0.4.0] - 2022-04-19

### Added
- Added `API.GetVersion` which allows external applications to check which version of the plugin is installed
- Added `API.PromptForGradient` as a replacement for `API.PromptForColorSequence`, which can prompt for either [Gradients](https://blupo.github.io/Color/api/gradient/) or [ColorSequences](https://developer.roblox.com/api-reference/datatype/ColorSequence)
- Added color interpolation controls and ColorSequence code exporting to the Gradient Editor
- Added the Color Tools section where the Color Info page used to be
- Added HWB, Lab, Luv, LCh(ab/uv), xyY, and XYZ to Color Info
- A first-time use prompt will now appear informing the user that script injection is required for exporting palettes to ModuleScripts and the API
- Added a warning in the export dialog that script injection is required for exporting palettes to ModuleScripts
- Added a color sorter that uses CIEDE2000 in the Color Tools section
- Added a Picular palette (idea from csqrl's [Picular plugin](https://devforum.roblox.com/t/914148))
- Added a Gradient picker tool which allows users to pick colors from their gradients
- Color Properties now shows the color type of the each property
- Right-clicking on a property in Color Properties now shows a menu to view the property documentation
- Mouse drag inputs now work outside of editor windows

### Changed
- `API.PromptForColor` now allows for prompting either [Colors](https://blupo.github.io/Color/api/color/) or [Color3s](https://developer.roblox.com/api-reference/datatype/Color3)
- Improved keypoint dragging behaviour in the Gradient Editor
- Improved performance (probably)
- `API.PromptForColor` and `API.PromptForGradient` now reject with PromptErrors instead of message strings
- Checking for updates now gracefully handles errors
- Checking for updates no longer does excess work if an update notice has already been shown
- Changed the message when notifying the user that a new version is available
- Moved the Color Variations palette to the Color Tools section
- API injection is now automatically done at startup
- Releases now contain binary (rbxm) files, so file size is reduced
- Terrain material color properties were renamed to "\[Material\] Material" (e.g. "Asphalt Material") from "\[Material\] Color" (e.g. "Asphalt Color")

### Fixed
- Exporting palettes now lists color components correctly (components were listed in the order R*BG* instead of R*GB*)
- Changing palettes now deselects the selected color
- Changing palettes in the export dialog now correctly persists the export type
- Scrollbars no longer interfere with mouse drag inputs

### Deprecated
- `API.PromptForColorSequence` has been deprecated, please use `API.PromptForGradient` for new work
- `API.IsColorSequenceEditorOpen` has been deprecated, please use `API.IsGradientEditorOpen` for new work

### Removed
- The "*Preview color changes before applying them when using Color Properties*" setting was removed

## [0.3.1] - 2021-12-09

### Fixed
- Fixed a bug where trying to use the scroll wheel on a dropdown selector (e.g. slider or palette pickers) resulted in a blank page

## [0.3.0] - 2021-07-21

### Added
- Added the ability to import palettes from ModuleScripts, StringValues, JSON files, or URLs
- Added the ability to export palettes as ModuleScripts or StringValues
- Users will now be notified at startup if their version of ColorPane is out-of-date, with the option to disable this in the Settings
- Added a palette showing variations of the selected color, including hues, shades, tints, and tones
- Added a [Copic](https://copic.jp/en/) color palette
- Holding down either Shift key when selecting the option to delete a palette will now bypass the confirmation dialog
- Users can now use the arrow keys to traverse palettes when a color is selected, as well as switch between keypoints in the ColorSequence editor when one is selected
- Setting data will now automatically save instead of only when the plugin is unloaded or when the Settings window is closed, with options to disable this or modify the interval in the Settings
- Users now have the option to cache the Roblox API data so that Color Properties can be used during testing or offline with the "Cache Roblox API data" setting
- Added a gradient palette
- Added a toolbar button to summon the Gradient Editor
- Added a setting to toggle previewing color changes before applying them when using Color Properties

### Fixed
- Fixed a bug that occurred when the API script was modified while the API wasn't loaded
- Fixed a bug where trying to use the scroll wheel on the palette page picker would break the palettes page if the user didn't have any User Palettes
- Fixed a bug that occurred if Color Properties tried referencing an object property that existed in the API dump but didn't exist on the object, most likely because the Studio and API dump versions were mismatched
- Fixed a bug that occurred when a text input was focused and destroyed due to a re-render

### Changed
- Testing sessions (e.g. Play Solo) can no longer modify settings or write data to disk
- Changed the behaviour for data writing when multiple Studio sessions are open
- Modified some setting descriptions to more accurately reflect what they actually do
- Changed the "Load API" toolbar button's text and description to more accurately reflect what it actually does
- Color Properties now shows a notice if the selection has no color properties instead of showing a blank window
- Several text inputs, mainly for color components, will now select their entire text when you focus on them
- Palette search will now update as the search text changes and no longer requires the user to release the TextBox's focus
- Text inputs will now respond to overflow text and changes to the cursor position
- When adding a new color to a palette, the search query will reset and the new color will be selected
- Changed the icons for the Color and Gradient Editor toolbar buttons
- Differentiated the icon denoting a removal from a subtraction
- Removed the 99 quick palette color limit
- Settings will now visually indicate to the user if saving is disabled

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
