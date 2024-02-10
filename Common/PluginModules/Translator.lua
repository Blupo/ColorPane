--!strict
-- Provides translation functionality

local StudioService: StudioService = game:GetService("StudioService")

---

local Translations: LocalizationTable = script.Parent.Parent.Translations

local fallbackTranslator: Translator = Translations:GetTranslator("en-us")
local localTranslator: Translator = Translations:GetTranslator(StudioService.StudioLocaleId)

---

local Translator = {}

--[[
    Returns a formatted translation string, see [Translator:FormatByKey()](https://create.roblox.com/docs/reference/engine/classes/Translator#FormatByKey)
    @param key The key to look up in the translation table
    @param args A table of format arguments in the translation string
    @return The formatted translatin string
]]
Translator.FormatByKey = function(key: string, args: {[any]: any}?): string
    local success: boolean, translatedString: string = pcall(function()
        return localTranslator:FormatByKey(key, args)
    end)

    if (not success) then
        return fallbackTranslator:FormatByKey(key, args)
    else
        return translatedString
    end
end

--[[
    Returns a table of translated strings.
    This function should only be used for translation strings without any format arguments.
    @param keys The array of keys to look up in the translation table
    @return A dictionary containing the translated strings where each dictionary key corresponds to a translation key
]]
Translator.GenerateTranslationTable = function(keys: {[number]: string}): {[string]: string}
    local t: {[string]: string} = {}

    for i = 1, #keys do
        local key = keys[i]

        t[key] = Translator.FormatByKey(key)
    end

    return t
end

return Translator