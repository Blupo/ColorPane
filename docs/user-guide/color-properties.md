The Color Properties window allows you to edit the color properties of objects in your projects.

![Color Properties](../images/color-properties.png)

## Activation

Color Properties will require manual activation the first time you use it. You will see a prompt when you open the window telling you that the API data has not been loaded (pictured below). On this screen you can load the API data and change the settings for automatic activation and caching (see the next section).

!!! attention
    API data is retrieved via HTTP requests to `setup.rbxcdn.com`. You will be prompted by Studio to allow HTTP requests to this domain the first time you use Color Properties. If you deny this permission, you will not be able to use Color Properties.

!!! info
    The Roblox API data necessary for Color Properties and the [ColorPane API](../api/) are not related, and you do not need to inject the ColorPane API to use Color Properties.

![Color Properties, not loaded](../images/color-properties-unloaded.png)

## Usage During Testing

Since HTTP requests are not allowed from plugins during testing, trying to use Color Properties won't work. You can enable the *Cache Roblox API data* setting to get around this, which will store the Roblox API data on your computer so that it can be used instead of having to make an HTTP request. Enabling this option may cause noticable pauses whenever the cache needs to be updated.

## Performance

Using Color Properties can cause performance problems, specifically in changing the selection and previewing color changes. By default, when changing color properties, you can see what your changes will look like before you apply them. You can change the *Preview color changes before applying them* setting to disable previewing, which can help in these cases.

Performance regarding changing the selection may be improved in future releases.