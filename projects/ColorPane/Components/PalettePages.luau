-- A Pages container for all the built-in and user palettes
local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local CommonEnums = require(CommonModules.Enums)
local Translator = require(CommonModules.Translator)

local CommonIncludes = Common.Includes
local Cryo = require(CommonIncludes.Cryo)
local Roact = require(CommonIncludes.RoactRodux.Roact)
local RoactRodux = require(CommonIncludes.RoactRodux.RoactRodux)

local Modules = root.Modules
local ColorEditorInputSignals = require(Modules.EditorInputSignals).ColorEditor
local Enums = require(Modules.Enums)
local Util = require(Modules.Util)

local BuiltInPalettes = Modules.BuiltInPalettes
local BrickColors = require(BuiltInPalettes.BrickColors)
local WebColors = require(BuiltInPalettes.WebColors)

local Components = root.Components
local ColorBrewerPalettes = require(Components.ColorBrewerPalettes)
local ExportPalette = require(Components.ExportPalette)
local ImportPalette = require(Components.ImportPalette)
local NamePalette = require(Components.NamePalette)
local Pages = require(Components.Pages)
local Palette = require(Components.Palette)
local PicularPalette = require(Components.PicularPalette)
local RemovePalette = require(Components.RemovePalette)

---

local uiTranslations = Translator.GenerateTranslationTable({
    "BuiltInPalette_Category",
    "UserPalette_Category",
    "CreatePalette_ButtonText",
    "ImportPalette_ButtonText",
    "ExportPalette_ButtonText",
    "DuplicatePalette_ButtonText",
    "RenamePalette_ButtonText",
    "DeletePalette_ButtonText",
})

local builtInPaletteElements = {
    {
        name = "BrickColors",
        
        content = Roact.createElement(Palette, {
            palette = Util.typeColorPalette(BrickColors, "Color3"),
            paletteIndex = -1,
            readOnly = true
        })
    },

    {
        name = "ColorBrewer",
        content = Roact.createElement(ColorBrewerPalettes)
    },

    {
        name = "Picular",
        content = Roact.createElement(PicularPalette),
    },

    {
        name = Translator.FormatByKey("Web_BuiltInPaletteName"),

        content = Roact.createElement(Palette, {
            palette = Util.typeColorPalette(WebColors, "Color3"),
            paletteIndex = -2,
            readOnly = true
        })
    }
}

---

--[[
    store props
        theme: StudioTheme
        palettes: array<Palette>
        lastPalettePage: number

        updatePalettePage: (number, number) -> nil
        addPalette: (string) -> nil
        duplicatePalette: (number) -> nil
        removePalette: (number) -> nil
]]

local PalettePages = Roact.PureComponent:extend("PalettePages")

PalettePages.init = function(self)
    self:setState({
        displayPage = "palettes",

        leftShiftDown = false,
        rightShiftDown = false,
    })
end

PalettePages.didMount = function(self)
    self.keyDown = ColorEditorInputSignals.InputBegan.Event:subscribe(function(input: InputObject)
        if (input.UserInputType ~= Enum.UserInputType.Keyboard) then return end

        if (input.KeyCode == Enum.KeyCode.LeftShift) then
            self:setState({
                leftShiftDown = true,
            })
        elseif (input.KeyCode ~= Enum.KeyCode.RightShift) then
            self:setState({
                rightShiftDown = true,
            })
        end
    end)

    self.keyUp = ColorEditorInputSignals.InputEnded.Event:subscribe(function(input: InputObject)
        if (input.UserInputType ~= Enum.UserInputType.Keyboard) then return end

        if (input.KeyCode == Enum.KeyCode.LeftShift) then
            self:setState({
                leftShiftDown = false,
            })
        elseif (input.KeyCode ~= Enum.KeyCode.RightShift) then
            self:setState({
                rightShiftDown = false,
            })
        end
    end)
end

PalettePages.willUnmount = function(self)
    self.keyDown:unsubscribe()
    self.keyUp:unsubscribe()
end

PalettePages.render = function(self)
    local palettes = self.props.palettes
    local numBuiltInPalettes = #builtInPaletteElements
    local upstreamAvailable: boolean = self.props.upstreamAvailable

    local selectedPage = self.props.lastPalettePage
    local selectedPageSection, selectedPageNum = selectedPage[1], selectedPage[2]

    local displayPage = self.state.displayPage
    local displayPageElement
    local builtInPalettePages = {}
    local userPalettePages = {}

    for i = 1, numBuiltInPalettes do
        table.insert(builtInPalettePages, builtInPaletteElements[i])
    end

    for i = 1, #palettes do
        local palette = palettes[i]

        table.insert(userPalettePages, {
            name = palette.name,

            content = Roact.createElement(Palette, {
                palette = palette,
                paletteIndex = i,
                readOnly = not upstreamAvailable,
            })
        })
    end
    
    -- decide which component to display
    if (displayPage == "namePalette") then
        displayPageElement = Roact.createElement(NamePalette, {
            onPromptClosed = function()
                self:setState({
                    displayPage = "palettes"
                })
            end,
        })
    elseif (displayPage == "renamePalette") then
        displayPageElement = Roact.createElement(NamePalette, {
            paletteIndex = self.state.paletteIndex,

            onPromptClosed = function()
                self:setState({
                    displayPage = "palettes",
                    paletteIndex = Roact.None,
                })
            end,
        })
    elseif (displayPage == "removePalette") then
        displayPageElement = Roact.createElement(RemovePalette, {
            paletteIndex = self.state.paletteIndex,

            onPromptClosed = function()
                self:setState({
                    displayPage = "palettes",
                    paletteIndex = Roact.None,
                })
            end
        })
    elseif (displayPage == "importPalette") then
        displayPageElement = Roact.createElement(ImportPalette, {
            onPromptClosed = function(success)
                if (success) then
                    self.props.updatePalettePage(2, #palettes + 1)
                end

                self:setState({
                    displayPage = "palettes"
                })
            end
        })
    elseif (displayPage == "exportPalette") then
        displayPageElement = Roact.createElement(ExportPalette, {
            paletteIndex = self.state.paletteIndex,

            onPromptClosed = function()
                self:setState({
                    displayPage = "palettes",
                    paletteIndex = Roact.None,
                })
            end
        })
    elseif (displayPage == "palettes") then
        local pageOptions = {}

        if (upstreamAvailable) then
            pageOptions = Cryo.List.join(pageOptions, {
                {
                    name = uiTranslations["CreatePalette_ButtonText"],

                    onActivated = function()
                        if (self.props.askNameBeforePaletteCreation) then
                            self:setState({
                                displayPage = "namePalette",
                                newPaletteName = Util.palette.getNewItemName(palettes, "New Palette")
                            })
                        else
                            self.props.addPalette()
                            self.props.updatePalettePage(2, #palettes + 1)
                        end
                    end
                },

                {
                    name = uiTranslations["ImportPalette_ButtonText"],

                    onActivated = function()
                        self:setState({
                            displayPage = "importPalette"
                        })
                    end
                },
            })

            if (selectedPageSection == 2) then
                pageOptions = Cryo.List.join(pageOptions, {
                    {
                        name = uiTranslations["ExportPalette_ButtonText"],

                        onActivated = function()
                            self:setState({
                                displayPage = "exportPalette",
                                paletteIndex = selectedPageNum,
                            })
                        end
                    },

                    {
                        name = uiTranslations["DuplicatePalette_ButtonText"],

                        onActivated = function()
                            self.props.duplicatePalette(selectedPageNum)
                            self.props.updatePalettePage(2, #palettes + 1)
                        end
                    },

                    {
                        name = uiTranslations["RenamePalette_ButtonText"],

                        onActivated = function()
                            self:setState({
                                displayPage = "renamePalette",
                                paletteIndex = selectedPageNum,
                            })
                        end
                    },

                    {
                        name = uiTranslations["DeletePalette_ButtonText"],

                        onActivated = function()
                            if (self.state.leftShiftDown or self.state.rightShiftDown) then
                                self.props.removePalette(selectedPageNum)
                                self.props.updatePalettePage(1, 1)
                            else
                                self:setState({
                                    displayPage = "removePalette",
                                    paletteIndex = selectedPageNum
                                })
                            end
                        end
                    },
                })
            end
        end

        displayPageElement = Roact.createElement(Pages, {
            selectedPage = selectedPage,
            showAllSections = true,
            onPageChanged = self.props.updatePalettePage,

            pageSections = {
                {
                    name = uiTranslations["BuiltInPalette_Category"],
                    items = builtInPalettePages,
                },

                {
                    name = uiTranslations["UserPalette_Category"],
                    items = userPalettePages,
                }
            },

            options = if (#pageOptions > 1) then pageOptions else nil,
        })
    end

    return displayPageElement
end

---

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,

        palettes = state.colorEditor.palettes,
        upstreamAvailable = state.upstreamAvailable,
        lastPalettePage = state.sessionData.lastPalettePage,
        askNameBeforePaletteCreation = state.userData[CommonEnums.ColorPaneUserDataKey.AskNameBeforePaletteCreation]
    }
end, function(dispatch)
    return {
        updatePalettePage = function(section, page)
            dispatch({
                type = Enums.StoreActionType.UpdateSessionData,
                slice = {
                    lastPalettePage = {section, page}
                }
            })
        end,

        addPalette = function(name)
            dispatch({
                type = Enums.StoreActionType.ColorEditor_AddPalette,
                name = name
            })
        end,

        duplicatePalette = function(paletteIndex)
            dispatch({
                type = Enums.StoreActionType.ColorEditor_DuplicatePalette,
                paletteIndex = paletteIndex,
            })
        end,

        removePalette = function(paletteIndex)
            dispatch({
                type = Enums.StoreActionType.ColorEditor_RemovePalette,
                paletteIndex = paletteIndex
            })
        end,
    }
end)(PalettePages)