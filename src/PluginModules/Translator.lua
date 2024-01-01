--!strict

local StudioService: StudioService = game:GetService("StudioService")

---

local Translations: LocalizationTable = script.Parent.Parent.Translations

local FALLBACK_TRANSLATOR: Translator = Translations:GetTranslator("en-us")
local LocaleTranslator: Translator = Translations:GetTranslator(StudioService.StudioLocaleId)

---

local Translator = {}

Translator.FormatByKey = function(key: string, args: {[any]: any}?): string
    local success, data = pcall(function()
        return LocaleTranslator:FormatByKey(key, args)
    end)

    if (not success) then
        return FALLBACK_TRANSLATOR:FormatByKey(key, args)
    else
        return data
    end
end

Translator.GenerateTranslationTable = function(keys: {[number]: string}): {[string]: string}
    local t: {[string]: string} = {}

    for i = 1, #keys do
        local key = keys[i]

        t[key] = Translator.FormatByKey(key)
    end

    return t
end

return Translator