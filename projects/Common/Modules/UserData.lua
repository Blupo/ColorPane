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
        @return The user data value
    ]]
    getValue: (UserData, string) -> any,

    --[[
        Retrieves all user data values.

        @param self The UserData to retrieve data from
        @return The user data table
    ]]
    getAllValues: (UserData) -> Types.UserData,

    --[[
        Updates a user data value.
        If the new value is the same value as the
        currently-stored value, the update will
        be silently dropped.

        @param self The UserData to be updated
        @param key The name of the value to update
        @param value The new value
    ]]
    setValue: (UserData, string, any) -> (),
}

export type UserData = typeof(setmetatable(
    {}::{
        __data: Types.UserData,
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

UserData.new = function(userData: Types.UserData): UserData
    local userDataIsValid: boolean = UserDataValidators.UserData(userData)
    assert(userDataIsValid, Enums.UserDataError.InvalidUserData)

    local valueChangedSignal: Signal.Signal<Types.KeyValue>, fireValueChanged: Signal.FireSignal<Types.KeyValue> = Signal.createSignal()

    local self = {
        __data = userData, 
        __fireValueChanged = fireValueChanged,

        valueChanged = valueChangedSignal,
    }

    return setmetatable(self, UserData)
end

UserData.getValue = function(self: UserData, key: string): any
    assert(Enums.UserDataKey[key] ~= nil, Enums.UserDataError.InvalidKey)

    local value = self.__data[key]

    if (typeof(value) == "table") then
        return Util.table.deepCopy(value)
    else
        return value
    end
end

UserData.getAllValues = function(self: UserData): Types.UserData
    return Util.table.deepCopy(self.__data)
end

UserData.setValue = function(self: UserData, key: string, value: any): ()
    assert(Enums.UserDataKey[key] ~= nil, Enums.UserDataError.InvalidKey)

    -- validate value
    local validator = UserDataValidators[key]
    assert(validator ~= nil, Enums.UserDataError.ValidatorNotFound)

    local valueIsValid: boolean = validator(value)
    assert(valueIsValid, Enums.UserDataError.InvalidValue)

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
        return
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
end

---

return UserData