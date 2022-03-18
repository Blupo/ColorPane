local makeEnum = function(name, enumItems)
    local enum = {}
    
    for i = 1, #enumItems do
        local enumItem = enumItems[i]
        
        enum[enumItem] = enumItem
    end
    
    return setmetatable(enum, {
        __index = function(_, key)
            error(tostring(key) .. " is not a valid member of enum " .. name)
        end,
        
        __newindex = function()
            error(name .. " cannot be modified")
        end,
    })
end

return setmetatable({
    StoreActionType = makeEnum("PluginEnums.StoreActionType", {
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

        "GradientEditor_ResetState",
        "GradientEditor_SetKeypoints",
        "GradientEditor_SetGradient",
        "GradientEditor_SetSnapValue",
        "GradientEditor_AddPaletteColor",
        "GradientEditor_RemovePaletteColor",
        "GradientEditor_ChangePaletteColorName",
        "GradientEditor_ChangePaletteColorPosition",
    }),

    PluginSettingKey = makeEnum("PluginEnums.PluginSettingKey", {
        "UserPalettes",
        "SnapValue",
        "AutoLoadColorProperties",
        "AskNameBeforePaletteCreation",
        "AutoCheckForUpdate",
        "AutoSave",
        "AutoSaveInterval",
        "CacheAPIData",
        "UserGradients",
        "ColorPropertiesLivePreview",
        "FirstTimeSetup",
        
        -- DEPRECATED
        "UserColorSequences",
    }),

    EditorKey = makeEnum("PluginEnums.EditorKey", {
        "ColorWheel",
        "RGBSlider",
        "CMYKSlider",
        "HSBSlider",
        "HSLSlider",
        "GreyscaleSlider",
        "KelvinSlider",

        "Default",
    }),

    PromptError = makeEnum("PluginEnums.PromptError", {
        "InvalidPromptOptions",
        "PromptAlreadyOpen",
        "ReservationProblem",
    }),
}, {
    __index = function(_, key)
        error(tostring(key) .. " is not a valid enum")
    end,

    __newindex = function()
        error("Enum table cannot be modified")
    end
})