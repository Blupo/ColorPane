# Contributing

## Feature Requests

Features requests should be submitted through GitHub issue. Feature requests should align with ColorPane's purpose of being a general-purpose suite of color tools. Please be as detailed as possible, and include images and/or video if necessary. New features should be fully discussed before contributing any code.

## Bug Reports

Bugs should be submitted via GitHub issue. Make sure that the bug you're reporting isn't already part of another issue.

Please include a detailed description and an image and/or video of the bug to make it easier to track down. If there's relevant error output in Studio, please include it.

## Documentation

If you find any errors or places for improvement in the documentation, feel free to open an issue or submit a pull request. ColorPane's documentation uses [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) (version 9.5.27 as of this writing).

## Translations

To reach as many developers as possible, one of ColorPane's goals is to be fully translated into several languages. If you would like to help translate ColorPane, you can contribute to the [Crowdin project](https://crowdin.com/project/colorpane). Translations for the documentation are currently not being accepted, but this may change in the future.

Currently, the targeted languages are:

- [Simplifed Chinese](https://crowdin.com/project/colorpane/zh-CN) (`zh-CN`)
- [Traditional Chinese](https://crowdin.com/project/colorpane/zh-TW) (`zh-TW`)
- [French](https://crowdin.com/project/colorpane/fr) (`fr`)
- [German](https://crowdin.com/project/colorpane/de) (`de`)
- [Indonesian](https://crowdin.com/project/colorpane/id) (`id`)
- [Italian](https://crowdin.com/project/colorpane/it) (`it`)
- [Japanese](https://crowdin.com/project/colorpane/jp) (`jp`)
- [Korean](https://crowdin.com/project/colorpane/ko) (`ko`)
- [Portuguese](https://crowdin.com/project/colorpane/pt-PT) (`pt-PT`)
- [Russian](https://crowdin.com/project/colorpane/ru) (`ru`)
- [Spanish](https://crowdin.com/project/colorpane/es-ES) (`es-ES`)

## Code Contributions

/// note
Code contributions should target the [develop](https://github.com/Blupo/ColorPane/tree/develop) branch, unless they're critical fixes.
///

If you have code you would like to contribute to ColorPane, please submit a pull request. ColorPane uses [Rojo](https://rojo.space) (version 7.4.1 as of this writing) for project management. When testing the plugin in Studio, serve `workspace.project.json` instead of the `default.project.json`. There will be 3 build objects in ServerStorage:

* CPTester, which is a debug plugin that provides direct access to the ColorPane API script from the Workspace
* Companion, the Companion plugin
* ColorPane, the ColorPane library

## Donations

If you like ColorPane, consider [donating](https://ko-fi.com/blupo)!