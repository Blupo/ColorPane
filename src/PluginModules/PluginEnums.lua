local makeEnum = function(...)
	local enum = {}
	local enumItems = {...}
	
	for i = 1, #enumItems do
		local enumItem = enumItems[i]
		
		enum[enumItem] = enumItem
	end
	
	return setmetatable(enum, {
		__index = function(_, k)
			error(tostring(k) .. " is not a valid member of enum")
		end,
		
		__newindex = function(_, k)
			error(tostring(k) .. " cannot be assigned to", 2)
		end,
	})
end

return {
	StoreActionType = makeEnum(
        "SetTheme",
        "UpdateSessionData",

        "ColorEditor_SetColor",
        "ColorEditor_AddQuickPaletteColor",
        "ColorEditor_AddPalette",
        "ColorEditor_RemovePalette",
        "ColorEditor_DuplicatePalette",
        "ColorEditor_ChangePaletteName",
        "ColorEditor_AddPaletteColor",
        "ColorEditor_AddCurrentColorToPalette",
        "ColorEditor_RemovePaletteColor",
        "ColorEditor_ChangePaletteColorName",
        "ColorEditor_ChangePaletteColorPosition",

        "ColorSequenceEditor_SetSnapValue"
    )
}