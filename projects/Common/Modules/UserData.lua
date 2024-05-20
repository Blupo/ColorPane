--!strict

local root = script.Parent.Parent

local Includes = root.Includes
local Signal = require(Includes.Signal)

local Modules = root.Modules
local Enums = require(Modules.Enums)
local Types = require(Modules.Types)
local UserDataDiffs = require(Modules.UserDataDiffs)
local UserDataValidators = require(Modules.UserDataValidators)
local Util = require(Modules.Util)

---

type UserDataImpl = {
    __index: UserDataImpl,

    --[[
        Creates a new UserData.

        @param userData The user data values to operate on
        @return A new UserData
    ]]
    new: (Types.UserData) -> UserData,

    --[[
        Retrieves a user data value.

        @param self The UserData to retrieve the value from
        @param key The name of the value to retrieve
        @return If the retrieval was successful or not
        @return The user data value if the retrieval was successful. Otherwise, an error message.
    ]]
    getValue: (UserData, string) -> (boolean, any),

    --[[
        Retrieves all user data values.

        @param self The UserData to retrieve data from
        @return The user data table
    ]]
    getAllValues: (UserData) -> Types.UserData,

    --[[
        Updates a user data value.

        @param self The UserData to be updated
        @param key The name of the value to update
        @param value The new value
        @return If the update waas successful
        @return An error message if the update was not successful
    ]]
    setValue: (UserData, string, any) -> (boolean, string?),
}

export type UserData = typeof(setmetatable(
    {}::{
        __data: Types.UserData,
        __fireValueChanged: Signal.FireSignal<Types.UserDataValue>,

        --[[
            Fires when a user data value changes.
        ]]
        valueChanged: Signal.Signal<Types.UserDataValue>,
    },

    {}::UserDataImpl
))

---

--[[
    Represents a bundle of user data values and operations
    on those values.
]]
local UserData: UserDataImpl = {}::UserDataImpl
UserData.__index = UserData

UserData.new = function(userData: Types.UserData): UserData
    local userDataIsValid: boolean, invalidReason: string? = UserDataValidators.UserData(userData)

    if (not userDataIsValid) then
        error("Invalid user data: " .. invalidReason::string)
    end

    local valueChangedSignal: Signal.Signal<Types.UserDataValue>, fireValueChanged: Signal.FireSignal<Types.UserDataValue> = Signal.createSignal()

    local self = {
        __data = userData, 
        __fireValueChanged = fireValueChanged,

        valueChanged = valueChangedSignal,
    }

    return setmetatable(self, UserData)
end

UserData.getValue = function(self: UserData, key: string): (boolean, any)
    if (not Enums.UserDataKey[key]) then
        return false, Enums.UserDataError.InvalidKey
    end

    local value = self.__data[key]

    if (typeof(value) == "table") then
        return true, Util.table.deepCopy(value)
    else
        return true, value
    end
end

UserData.getAllValues = function(self: UserData): Types.UserData
    return Util.table.deepCopy(self.__data)
end

UserData.setValue = function(self: UserData, key: string, value: any): (boolean, string?)
    if (not Enums.UserDataKey[key]) then
        return false, Enums.UserDataError.InvalidKey
    end

    -- validate value
    local validator = UserDataValidators[key]

    if (not validator) then
        error("Validator for key " .. key .. " not found!")
    end

    local valueIsValid: boolean, invalidReason: string? = validator(value)
    
    if (not valueIsValid) then
        return false, invalidReason
    end

    -- compare values to see if they're actually different
    local originalValue: any = self.__data[key]
    local isSameValue: boolean

    if (key == "UserColorPalettes") then
        isSameValue = not UserDataDiffs.ColorPalettesAreDifferent(originalValue, value)
    elseif (key == "UserGradientPalettes") then
        isSameValue = not UserDataDiffs.GradientPalettesAreDifferent(originalValue, value)
    else
        isSameValue = originalValue == value
    end

    if (isSameValue) then
        return false, Enums.UserDataError.SameValue
    end

    -- add a copy of tables to prevent unintended behaviour
    if (typeof(value) == "table") then
        self.__data[key] = Util.table.deepCopy(value)
    else
        self.__data[key] = value
    end

    self.__fireValueChanged({
        Key = key,
        Value = value
    })

    return true
end

---

return UserData