local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local Translator = require(PluginModules:FindFirstChild("Translator"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local ColorInfo = require(Components:FindFirstChild("ColorInfo"))
local ColorSorter = require(Components:FindFirstChild("ColorSorter"))
local ColorVariations = require(Components:FindFirstChild("ColorVariations"))
local Pages = require(Components:FindFirstChild("Pages"))

---

local uiTranslations = Translator.GenerateTranslationTable({
    "ColorInformation_Page",
    "ColorSorter_Page",
    "ColorVariations_Page",
})

---

--[[
    store props

        lastToolPage: number
        updateToolPage: (number) -> nil
]]

local ColorToolPages = Roact.PureComponent:extend("ColorToolPages")

ColorToolPages.render = function(self)
    return Roact.createElement(Pages, {
        selectedPage = self.props.lastToolPage,
        onPageChanged = self.props.updateToolPage,

        pageSections = {
            {
                name = "",

                items = {
                    {
                        name = uiTranslations["ColorInformation_Page"],
                        content = Roact.createElement(ColorInfo)
                    },

                    {
                        name = uiTranslations["ColorSorter_Page"],
                        content = Roact.createElement(ColorSorter)
                    },

                    {
                        name = uiTranslations["ColorVariations_Page"],
                        content = Roact.createElement(ColorVariations)
                    },
                }
            }
        }
    })
end

---

return RoactRodux.connect(function(state)
    return {
        lastToolPage = state.sessionData.lastToolPage,
    }
end, function(dispatch)
    return {
        updateToolPage = function(section, page)
            dispatch({
                type = PluginEnums.StoreActionType.UpdateSessionData,
                slice = {
                    lastToolPage = {section, page}
                }
            })
        end,
    }
end)(ColorToolPages)