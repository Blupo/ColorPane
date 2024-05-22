--[[
    A Pages container for the Color Information, Color Sorter,
    Color Variations, and Gradient Pickers pages
]]

local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local Translator = require(CommonModules.Translator)

local CommonIncludes = Common.Includes
local Roact = require(CommonIncludes.RoactRodux.Roact)
local RoactRodux = require(CommonIncludes.RoactRodux.RoactRodux)

local Modules = root.Modules
local Enums = require(Modules.Enums)

local Components = root.Components
local ColorInfo = require(Components.ColorInfo)
local ColorSorter = require(Components.ColorSorter)
local ColorVariations = require(Components.ColorVariations)
local GradientPickers = require(Components.GradientPickers)
local Pages = require(Components.Pages)

---

local uiTranslations = Translator.GenerateTranslationTable({
    "ColorInformation_Page",
    "ColorSorter_Page",
    "ColorVariations_Page",
    "GradientPickers_Page"
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

                    {
                        name = uiTranslations["GradientPickers_Page"],
                        content = Roact.createElement(GradientPickers)
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
                type = Enums.StoreActionType.UpdateSessionData,
                slice = {
                    lastToolPage = {section, page}
                }
            })
        end,
    }
end)(ColorToolPages)