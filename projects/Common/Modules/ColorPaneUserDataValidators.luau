--!strict
--[[
    Defines the set of validators for ColorPane user data values.
]]

local root = script.Parent.Parent

local Modules = root.Modules
local Constants = require(Modules.Constants)
local Enums = require(Modules.Enums)
local Util = require(Modules.Util)

local Includes = root.Includes
local t = require(Includes.t)

---

--[[
    Checks if a value is a valid RGB tuple (a 3-element array of numbers).

    @param value The value to check
    @return If the value is a valid RGB tuple
    @return An error message, if the value was invalid
]]
local rgbTuple = t.strictInterface({
    [1] = t.number,
    [2] = t.number,
    [3] = t.number,
})

--[[
    Checks if a value is a valid color palette item.
    A valid value is a dictionary in the format:

    ```
    {
        name: string,
        color: rgbTuple
    }
    ```

    @param value The value to check
    @return If the value is a valid color palette item
    @return An error message, if the value was invalid
]]
local colorPaletteItem = t.strictInterface({
    name = t.string,
    color = rgbTuple,
})

--[[
    Checks if a value is a valid color palette.
    A valid value is a dictionary in the format:

    ```
    {
        name: string,
        colors: array<colorPaletteItem>
    }
    ```

    @param value The value to check
    @return If the value is a valid color palette
    @return An error message, if the value was invalid
]]
local colorPalette = t.strictInterface({
    name = t.string,
    colors = t.array(colorPaletteItem)
})

--[[
    Checks if a value is a valid gradient keypoint.
    A valid value is a dictionary in the format:

    ```
    {
        time: number,
        color: rgbTuple
    }
    ```

    where `time` is in the range [0, 1].

    @param value The value to check
    @return If the value is a valid gradient keypoint
    @return An error message, if the value was invalid
]]
local gradientKeypoint = t.strictInterface({
    time = t.numberConstrained(0, 1),
    color = rgbTuple,
})

--[[
    Checks if a value is a valid gradient keypoint list.
    A valid value is an array of gradient keypoints where:
    - the keypoints are ordered such that `keypoint[i].time >= keypoint[i+1].time`,
    - `keypoints[1].time = 0` (first keypoint's time is 0)
    - `keypoints[#keypoints].time = 1` (last keypoint's time is 1)

    @param value The value to check
    @return If the value is a valid gradient keypoint list
    @return An error message, if the value was invalid
]]
local gradientKeypoints = function(a): (boolean, string?)
    local success, failReason = t.array(gradientKeypoint)(a)

    if (not success) then
        return success, failReason
    end

    for i = 1, #a - 1 do
        local thisKeypoint = a[i]
        local nextKeypoint = a[i + 1]

        if ((i == 1) and (thisKeypoint.time ~= 0)) then
            return false, "first keypoint must have time 0"
        elseif ((i == (#a - 1)) and (nextKeypoint.time ~= 1)) then
            return false, "last keypoint must have time 1"
        elseif (thisKeypoint.time >= nextKeypoint.time) then
            return false, "keypoints must be ordered in time"
        end
    end

    return true
end

--[[
    Checks if a value is a valid gradient palette item.
    A valid value is a dictionary in the format:

    ```
    {
        name: string,
        colorSpace: MixableColorType (see Constants),
        precision: integer,
        hueAdjustment: HueAdjustment (see Constants),

        keypoints: gradientKeypoints
    }
    ```

    @param value The value to check
    @return If the value is a valid gradient palette item
    @return An error message, if the value was invalid
]]
local gradientPaletteItem = function(value: any): (boolean, string?)
    local success: boolean, failReason: string? = t.strictInterface({
        name = t.string,
        colorSpace = t.valueOf(Constants.VALID_GRADIENT_COLOR_SPACES),
        precision = t.integer,
        hueAdjustment = t.valueOf(Constants.VALID_HUE_ADJUSTMENTS),

        keypoints = gradientKeypoints,
    })(value)

    if (not success) then
        return false, failReason::string
    end

    local isPrecisionValid: boolean =
        Util.gradient.getUtilisedKeypoints(#value.keypoints, value.precision)
            <=
        Constants.MAX_COLORSEQUENCE_KEYPOINTS
    
    if (not isPrecisionValid) then
        return false, "invalid precision"
    else
        return true
    end
end

--[[
    Checks if a value is a valid gradient palette.
    A valid value is a dictionary in the format:

    ```
    {
        name: string,
        gradients: array<gradientPaletteItem>
    }
    ```

    @param value The value to check
    @return If the value is a valid gradient palette
    @return An error message, if the value was invalid
]]
local gradientPalette = t.strictInterface({
    name = t.string,
    gradients = t.array(gradientPaletteItem),
})

---

local ColorPaneUserDataValidators = {
    _colorPalette = colorPalette,
    _gradientPalette = gradientPalette,

    --[[
        Checks if a value is valid for the AskNameBeforePaletteCreation value.

        @param value The value to check
        @return If the value is valid
        @return An error message, if the value was invalid
    ]]
    [Enums.ColorPaneUserDataKey.AskNameBeforePaletteCreation] = t.boolean,

    --[[
        Checks if a value is a valid snap value (a constrained number).

        @param value The value to check
        @return If the value is a valid snap value
        @return An error message, if the value was invalid
    ]]
    [Enums.ColorPaneUserDataKey.SnapValue] = t.numberConstrained(Constants.MIN_SNAP_VALUE, Constants.MAX_SNAP_VALUE),

    --[[
        Checks if a value is an array of color palettes.

        @param value The value to check
        @return If the value is an array of color palettes
        @return An error message, if the value was invalid
    ]]
    [Enums.ColorPaneUserDataKey.UserColorPalettes] = t.array(colorPalette),

    --[[
        Checks if a value is an array of gradient palettes.

        @param value The value to check
        @return If the value is an array of gradient palettes
        @return An error message, if the value was invalid
    ]]
    [Enums.ColorPaneUserDataKey.UserGradientPalettes] = t.array(gradientPalette),

    --[[
        Checks if a value is a valid legacy gradient palette.

        @param value The value to check
        @return If the value is valid
        @return An error message, if the value was invalid
    ]]
    _userGradients = t.array(t.strictInterface({
        name = t.string,
        colorSpace = t.string,
        precision = t.integer,
        hueAdjustment = t.string,

        keypoints = function(a): (boolean, string?)
            local success, failReason = t.array(t.strictInterface({
                Time = t.numberConstrained(0, 1),
                Color = rgbTuple,
            }))(a)

            if (not success) then
                return success, failReason
            end
        
            for i = 1, #a - 1 do
                local thisKeypoint = a[i]
                local nextKeypoint = a[i + 1]
        
                if ((i == 1) and (thisKeypoint.Time ~= 0)) then
                    return false, "first keypoint must have time 0"
                elseif ((i == (#a - 1)) and (nextKeypoint.Time ~= 1)) then
                    return false, "last keypoint must have time 1"
                elseif (thisKeypoint.Time >= nextKeypoint.Time) then
                    return false, "keypoints must be ordered in time"
                end
            end
        
            return true
        end
    })),
}

--[[
    Checks if a value is a valid user data table.

    @param value The value to check
    @return If the value is valid
    @return An error message, if the value was invalid

]]
ColorPaneUserDataValidators._userData = t.interface({
    AskNameBeforePaletteCreation = ColorPaneUserDataValidators.AskNameBeforePaletteCreation,
    SnapValue = ColorPaneUserDataValidators.SnapValue,
    UserColorPalettes = ColorPaneUserDataValidators.UserColorPalettes,
    UserGradientPalettes = ColorPaneUserDataValidators.UserGradientPalettes,
})

---

return ColorPaneUserDataValidators