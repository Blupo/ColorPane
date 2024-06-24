--!strict
--[[
    A class wrapper for a list of key-value pairs.
]]

local root = script.Parent.Parent

local Includes = root.Includes
local Signal = require(Includes.Signal)
local t = require(Includes.t)

local Modules = root.Modules
local Enums = require(Modules.Enums)
local Types = require(Modules.Types)
local Util = require(Modules.Util)

---

type Values = Types.UserDataValues

type UserDataImpl = {
    __index: UserDataImpl,

    --[[
        Creates a new UserData.

        @param keys The set of valid user data keys
        @param validators The set of user data value validators
        @param diffs The set of custom user data value comparators
        @param userData The initial set of user data values
        @return A new UserData
    ]]
    new: (
        Values,
        {[string]: (any) -> (boolean, string?)},
        {[string]: (any, any) -> boolean},
        Values
    ) -> UserData,

    --[[
        Retrieves a user data value.

        @param self The UserData to retrieve the value from
        @param key The name of the value to retrieve
        @return The user data value
    ]]
    getValue: (UserData, string) -> any,

    --[[
        Retrieves all user data values.

        @param self The UserData to retrieve data from
        @return The user data table
    ]]
    getAllValues: (UserData) -> Values,

    --[[
        Updates a user data value.

        @param self The UserData to be updated
        @param key The name of the value to update
        @param value The new value
        @return If the value was actually updated
    ]]
    setValue: (UserData, string, any) -> boolean,
}

export type UserData = typeof(setmetatable(
    {}::{
        __data: Values,
        __keys: Values,
        __validators: {[string]: (any) -> (boolean, string?)},
        __diffs: {[string]: (any, any) -> boolean},
        __fireValueChanged: Signal.FireSignal<Types.KeyValue>,

        --[[
            Fires when a user data value changes.
        ]]
        valueChanged: Signal.Signal<Types.KeyValue>,
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

UserData.new = function(
    keys: Values,
    validators: {[string]: (any) -> (boolean, string?)},
    diffs: {[string]: (any, any) -> boolean},
    userData: Values
): UserData
    local userDataIsValidTable = t.keys(t.string)
    assert(userDataIsValidTable, Enums.UserDataError.InvalidUserData)

    for key, value in pairs(userData) do
        local validator: (any) -> (boolean, string?) = validators[key]
        assert(validator, Enums.UserDataError.ValidatorNotFound .. " " .. key)
        assert(validator(value), Enums.UserDataError.InvalidUserData)
    end

    local valueChangedSignal: Signal.Signal<Types.KeyValue>, fireValueChanged: Signal.FireSignal<Types.KeyValue> = Signal.createSignal()

    local self = {
        __data = userData,
        __keys = keys,
        __validators = validators,
        __diffs = diffs,
        __fireValueChanged = fireValueChanged,

        valueChanged = valueChangedSignal,
    }

    return setmetatable(self, UserData)
end

UserData.getValue = function(self: UserData, key: string): any
    assert(self.__keys[key], Enums.UserDataError.InvalidKey)

    local value = self.__data[key]

    if (typeof(value) == "table") then
        return Util.table.deepCopy(value)
    else
        return value
    end
end

UserData.getAllValues = function(self: UserData): Values
    return Util.table.deepCopy(self.__data)
end

UserData.setValue = function(self: UserData, key: string, value: any): boolean
    assert(self.__keys[key], Enums.UserDataError.InvalidKey)

    -- validate value
    local validator = self.__validators[key]
    assert(validator, Enums.UserDataError.ValidatorNotFound)

    local valueIsValid: boolean = validator(value)
    assert(valueIsValid, Enums.UserDataError.InvalidValue)

    -- compare values to see if they're actually different
    local originalValue: any = self.__data[key]
    local isDifferentValue: boolean

    if (self.__diffs[key]) then
        isDifferentValue = self.__diffs[key](originalValue, value)
    else
        isDifferentValue = originalValue ~= value
    end

    if (not isDifferentValue) then
        return false
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