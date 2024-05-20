--!strict

local Modules = script.Parent
local Types = require(Modules.Types)

---

type ColorPalettes = Types.ColorPalettes
type GradientPalettes = Types.GradientPalettes
type UserData = Types.UserData

--[[
    Functions for comparing user data values
]]
local UserDataDiffs = {}

--[[
    Checks if two color palettes are different.

    @param this The palette to be compared to
    @param that The palette to compare
    @return `true` if the palettes are different, `false` otherwise
]]
UserDataDiffs.ColorPalettesAreDifferent = function(this: ColorPalettes, that: ColorPalettes): boolean
    if (#that ~= #this) then
        return true
    else
        for i, thatPalette in ipairs(that) do
            local thisPalette = this[i]

            if ((thatPalette.name ~= thisPalette.name) or (#thatPalette.colors ~= #thisPalette.colors)) then
                return true
            else
                for j, thatColor in ipairs(thatPalette.colors) do
                    local thisColor = thisPalette.colors[j]

                    if (thatColor.name ~= thisColor.name) then
                        return true
                    else
                        local thatTuple = thatColor.color
                        local thisTuple = thisColor.color

                        if ((thatTuple[1] ~= thisTuple[1]) or (thatTuple[2] ~= thisTuple[2]) or (thatTuple[3] ~= thisTuple[3])) then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

--[[
    Checks if two gradient palettes are different.

    @param this The palette to be compared to
    @param that The palette to compare
    @return `true` if the palettes are different, `false` otherwise
]]
UserDataDiffs.GradientPalettesAreDifferent = function(this: GradientPalettes, that: GradientPalettes): boolean
    if (#that ~= #this) then
        return true
    else
        for i, thatPalette in ipairs(that) do
            local thisPalette = this[i]

            if ((thatPalette.name ~= thisPalette.name) or (#thatPalette.gradients ~= #thisPalette.gradients)) then
                return true
            else
                for j, thatGradient in ipairs(thatPalette.gradients) do
                    local thisGradient = thisPalette.gradients[j]

                    if (
                        (thatGradient.name ~= thisGradient.name)
                        or (thatGradient.colorSpace ~= thisGradient.colorSpace)
                        or (thatGradient.hueAdjustment ~= thisGradient.hueAdjustment)
                        or (thatGradient.precision ~= thisGradient.precision)
                        or (#thatGradient.keypoints ~= #thisGradient.keypoints)
                    ) then
                        return true
                    else
                        for k, thatKeypoint in ipairs(thatGradient.keypoints) do
                            local thisKeypoint = thisGradient.keypoints[k]

                            if (thatKeypoint.time ~= thisKeypoint.time) then
                                return true
                            else
                                local thatTuple = thatKeypoint.color
                                local thisTuple = thisKeypoint.color

                                if ((thatTuple[1] ~= thisTuple[1]) or (thatTuple[2] ~= thisTuple[2]) or (thatTuple[3] ~= thisTuple[3])) then
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end

--[[
    Compares user data values and returns a table with the differing values.
    The values

    @param this The values to be compared to
    @param that The values to compare
    @return A table containing the differing values between `this` and `that`, whose values come from `that`
]]
UserDataDiffs.GetModifiedValues = function(this: UserData, that: UserData)
    local modifiedValues = {}

    -- compare non-palettes
    if (that.AskNameBeforePaletteCreation ~= this.AskNameBeforePaletteCreation) then
        modifiedValues.AskNameBeforePaletteCreation = that.AskNameBeforePaletteCreation
    end

    if (that.SnapValue ~= this.SnapValue) then
        modifiedValues.SnapValue = that.SnapValue
    end

    -- compare palettes
    if (UserDataDiffs.ColorPalettesAreDifferent(this.UserColorPalettes, that.UserColorPalettes)) then
        modifiedValues.UserColorPalettes = that.UserColorPalettes
    end

    if (UserDataDiffs.GradientPalettesAreDifferent(this.UserGradientPalettes, that.UserGradientPalettes)) then
        modifiedValues.UserGradientPalettes = that.UserGradientPalettes
    end

    return modifiedValues
end

---

return UserDataDiffs