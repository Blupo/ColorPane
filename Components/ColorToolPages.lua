local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local ColorInfo = require(Components:FindFirstChild("ColorInfo"))
local Pages = require(Components:FindFirstChild("Pages"))

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
                        name = "Color Information",
                        content = Roact.createElement(ColorInfo)
                    }
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