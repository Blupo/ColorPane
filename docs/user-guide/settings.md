This page explains the various options in the Settings window, in the order that they appear.

- *Automatically load the Roblox API data for Color Properties on startup*: Used in [Color Properties](color-properties.md). If enabled, the plugin will automatically load Roblox API data, which lets you use Color Properties without having to manually activate it.
- *Auto-save settings and palettes*: Self-explanatory. It enabled, settings and palettes will be saved periodically.
- *Auto-save interval*: Used to determine the interval in which settings and palettes are auto-saved, in minutes.
- *Cache Roblox API data for use during testing sessions*: Used in Color Properties. If enabled, the plugin will save Roblox API data, which lets you use Color Properties while testing your project.
- *Periodically check for updates*: Self-explanatory. If enabled, the plugin will check for updates periodically.
- *Name palettes before creating them*: Self-explanatory. If enabled, you will have the opportunity to change the palette's name *before* you create it. If not, you can only do that *after* the palette is created.
- The <span class="cp-button">Claim Session Lock</span> button: To prevent data overwriting, the plugin only allows one Studio instance at a time to modify its settings. It does this by placing a "lock" in the settings, and is removed when the Studio instance that placed the lock is closed. In some situations, however (such as Studio closing unexpectedly), this lock won't be removed, which is what this button is for.
    - If you need to use this button, it will usually come with this warning in Studio's output: "**Data saving is locked to another session. You will need to close the other session(s) to modify settings and save palettes.**"