local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local ColorEditorInputSignals = require(PluginModules:FindFirstChild("EditorInputSignals")).ColorEditor
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local PluginSettings = require(PluginModules:FindFirstChild("PluginSettings"))
local Translator = require(PluginModules:FindFirstChild("Translator"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local BuiltInPaletteComponents = require(Components:FindFirstChild("BuiltInPaletteComponents"))
local ExportPalette = require(Components:FindFirstChild("ExportPalette"))
local ImportPalette = require(Components:FindFirstChild("ImportPalette"))
local NamePalette = require(Components:FindFirstChild("NamePalette"))
local Pages = require(Components:FindFirstChild("Pages"))
local Palette = require(Components:FindFirstChild("Palette"))
local RemovePalette = require(Components:FindFirstChild("RemovePalette"))

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
        askNameBeforeCreation = PluginSettings.Get(PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation),
        displayPage = "palettes",

        leftShiftDown = false,
        rightShiftDown = false,
    })
end

PalettePages.didMount = function(self)
    self.keyDown = ColorEditorInputSignals.InputBegan:Connect(function(input)
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

    self.keyUp = ColorEditorInputSignals.InputEnded:Connect(function(input)
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

    self.settingsChanged = PluginSettings.SettingChanged:Connect(function(key, newValue)
        if (key ~= PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation) then return end

        self:setState({
            askNameBeforeCreation = newValue
        })
    end)
end

PalettePages.willUnmount = function(self)
    self.keyDown:Disconnect()
    self.keyUp:Disconnect()
    self.settingsChanged:Disconnect()
end

PalettePages.render = function(self)
    local palettes = self.props.palettes
    local numBuiltInPalettes = #BuiltInPaletteComponents

    local selectedPage = self.props.lastPalettePage
    local selectedPageSection, selectedPageNum = selectedPage[1], selectedPage[2]

    local displayPage = self.state.displayPage
    local displayPageElement
    local builtInPalettePages = {}
    local userPalettePages = {}

    for i = 1, numBuiltInPalettes do
        local palette = BuiltInPaletteComponents[i]

        table.insert(builtInPalettePages, {
            name = palette.name,
            content = palette.getContent(self)
        })
    end

    for i = 1, #palettes do
        local palette = palettes[i]

        table.insert(userPalettePages, {
            name = palette.name,

            content = Roact.createElement(Palette, {
                palette = palette,
                paletteIndex = i,
            })
        })
    end
    
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

            options = {
                {
                    name = uiTranslations["CreatePalette_ButtonText"],

                    onActivated = function()
                        if (self.state.askNameBeforeCreation) then
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

                (selectedPageSection == 2) and {
                    name = uiTranslations["ExportPalette_ButtonText"],

                    onActivated = function()
                        self:setState({
                            displayPage = "exportPalette",
                            paletteIndex = selectedPageNum,
                        })
                    end
                } or nil,

                (selectedPageSection == 2) and {
                    name = uiTranslations["DuplicatePalette_ButtonText"],

                    onActivated = function()
                        self.props.duplicatePalette(selectedPageNum)
                        self.props.updatePalettePage(2, #palettes + 1)
                    end
                } or nil,

                (selectedPageSection == 2) and {
                    name = uiTranslations["RenamePalette_ButtonText"],

                    onActivated = function()
                        self:setState({
                            displayPage = "renamePalette",
                            paletteIndex = selectedPageNum,
                        })
                    end
                } or nil,

                (selectedPageSection == 2) and {
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
                } or nil,
            }
        })
    end

    return displayPageElement
end

---

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,

        palettes = state.colorEditor.palettes,
        lastPalettePage = state.sessionData.lastPalettePage,
    }
end, function(dispatch)
    return {
        updatePalettePage = function(section, page)
            dispatch({
                type = PluginEnums.StoreActionType.UpdateSessionData,
                slice = {
                    lastPalettePage = {section, page}
                }
            })
        end,

        addPalette = function(name)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_AddPalette,
                name = name
            })
        end,

        duplicatePalette = function(index)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_DuplicatePalette,
                index = index,
            })
        end,

        removePalette = function(index)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_RemovePalette,
                index = index
            })
        end,
    }
end)(PalettePages)