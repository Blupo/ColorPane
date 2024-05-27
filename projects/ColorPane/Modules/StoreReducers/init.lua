--!strict

local root = script.Parent.Parent
local Common = root.Common

local CommonIncludes = Common.Includes
local Cryo = require(CommonIncludes.Cryo)

local Modules = root.Modules
local Enums = require(Modules.Enums)
local Types = require(Modules.Types)
local Util = require(Modules.Util)

local ColorEditorReducers = require(script.ColorEditorReducers)
local GradientEditorReducers = require(script.GradientEditorReducers)

---

type table = Types.table

---

--[[
    Rodux reducers for store updates.
]]
return Cryo.Dictionary.join({
    --[[
        Updates the UI theme.
        
        ```
        action =  {
            theme: StudioTheme
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.SetTheme] = function(oldState: table, action: table): table
        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            theme = action.theme
        }))
    end,

    --[[
        Updates some session information.

        ```
        action = {
            slice: {[any]: any}
        }
        ```

        @param oldState The previous state
        @param action The action information
        @return The next state
    ]]
    [Enums.StoreActionType.UpdateSessionData] = function(oldState: table, action: table): table
        return Util.table.deepFreeze(Cryo.Dictionary.join(oldState, {
            sessionData = Cryo.Dictionary.join(oldState.sessionData, action.slice)
        }))
    end,
}, ColorEditorReducers, GradientEditorReducers)