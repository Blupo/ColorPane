local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PaletteUtils = require(PluginModules:FindFirstChild("PaletteUtils"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local PluginSettings = require(PluginModules:FindFirstChild("PluginSettings"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local BuiltInPalettes = require(Components:FindFirstChild("BuiltInPalettes"))
local ExportPalette = require(Components:FindFirstChild("ExportPalette"))
local ImportPalette = require(Components:FindFirstChild("ImportPalette"))
local NamePalette = require(Components:FindFirstChild("NamePalette"))
local Pages = require(Components:FindFirstChild("Pages"))
local Palette = require(Components:FindFirstChild("Palette"))
local RemovePalette = require(Components:FindFirstChild("RemovePalette"))

---

local shallowCompare = Util.shallowCompare

---

local PalettePages = Roact.Component:extend("PalettePages")

PalettePages.init = function(self)
    self:setState({
        askNameBeforeCreation = PluginSettings.Get(PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation),
        displayPage = "palettes",
    })
end

PalettePages.shouldUpdate = function(self, nextProps, nextState)
    local propsDiff = shallowCompare(self.props, nextProps)
    local stateDiff = shallowCompare(self.state, nextState)

    if (#stateDiff > 0) then return true end

    if ((#propsDiff == 1) and (propsDiff[1] ~= "palettes")) then
        -- props.lastPaletteModification will tell us if the palettes changed without having to compare them
        return true
    elseif (#propsDiff > 1) then
        return true
    end

    return false
end

PalettePages.didMount = function(self)
    self.settingsChanged = PluginSettings.SettingChanged:Connect(function(key, newValue)
        if (key ~= PluginEnums.PluginSettingKey.AskNameBeforePaletteCreation) then return end

        self:setState({
            askNameBeforeCreation = newValue
        })
    end)
end

PalettePages.willUnmount = function(self)
    self.settingsChanged:Disconnect()
end

PalettePages.render = function(self)
    local palettes = self.props.palettes
    local numBuiltInPalettes = #BuiltInPalettes

    local selectedPage = self.props.lastPalettePage
    local selectedPageSection, selectedPageNum = selectedPage[1], selectedPage[2]

    local displayPage = self.state.displayPage
    local displayPageElement
    local builtInPalettePages = {}
    local userPalettePages = {}

    for i = 1, numBuiltInPalettes do
        local palette = BuiltInPalettes[i]

        table.insert(builtInPalettePages, {
            name = palette.name,
            content = palette.getContent()
        })
    end

    for i = 1, #palettes do
        local palette = palettes[i]

        table.insert(userPalettePages, {
            name = palette.name,

            content = Roact.createElement(Palette, {
                palette = palette
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
                    name = "Built-In Palettes",
                    items = builtInPalettePages,
                },

                {
                    name = "User Palettes",
                    items = userPalettePages,
                }
            },

            options = {
                {
                    name = "Create a New Palette",

                    onActivated = function()
                        if (self.state.askNameBeforeCreation) then
                            self:setState({
                                displayPage = "namePalette",
                                newPaletteName = PaletteUtils.getNewPaletteName(palettes, "New Palette")
                            })
                        else
                            self.props.addPalette()
                            self.props.updatePalettePage(2, #palettes + 1)
                        end
                    end
                },

                {
                    name = "Import a Palette",

                    onActivated = function()
                        self:setState({
                            displayPage = "importPalette"
                        })
                    end
                },

                (selectedPageSection == 2) and {
                    name = "Export this Palette",

                    onActivated = function()
                        self:setState({
                            displayPage = "exportPalette",
                            paletteIndex = selectedPageNum,
                        })
                    end
                } or nil,

                (selectedPageSection == 2) and {
                    name = "Duplicate this Palette",

                    onActivated = function()
                        self.props.duplicatePalette(palettes[selectedPageNum].name)
                        self.props.updatePalettePage(2, #palettes + 1)
                    end
                } or nil,

                (selectedPageSection == 2) and {
                    name = "Rename this Palette",

                    onActivated = function()
                        self:setState({
                            displayPage = "renamePalette",
                            paletteIndex = selectedPageNum,
                        })
                    end
                } or nil,

                (selectedPageSection == 2) and {
                    name = "Delete this Palette",

                    onActivated = function()
                        self:setState({
                            displayPage = "removePalette",
                            paletteIndex = selectedPageNum
                        })
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
        lastPaletteModification = state.colorEditor.lastPaletteModification,
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

        duplicatePalette = function(paletteName)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_DuplicatePalette,
                name = paletteName
            })
        end,
    }
end)(PalettePages)