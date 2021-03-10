local ContentProvider = game:GetService("ContentProvider")

---

local Style = {
    -- paddings
    MajorElementPadding = 16,
    MinorElementPadding = 4,
    SpaciousElementPadding = 8,
    PagePadding = 8,

    -- text stuff
    StandardFont = Enum.Font.SourceSans,
    StandardTextSize = 14,
    LargeTextSize = 18,
    TextObjectPadding = 4,

    -- scrollbar
    ScrollbarThickness = 16,
    ScrollbarImage = "rbxassetid://590077572",

    -- harmony icons
    HarmonyNoneImage = "rbxassetid://6237978084",
    HarmonyComplementImage = "rbxassetid://6237986907",
    HarmonyAnalogousImage = "rbxassetid://6237983501",
    HarmonyTriadImage = "rbxassetid://6237989125",
    HarmonySplitComplementImage = "rbxassetid://6237993440",
    HarmonySquareImage = "rbxassetid://6237995215",
    HarmonyRectangleImage = "rbxassetid://6237996947",
    HarmonyHexagonImage = "rbxassetid://6238003104",

    -- color wheel
    ColorWheelRingWidth = 20,
    HueWheelImage ="rbxassetid://5686040244",
    SVPlaneImage = "rbxassetid://5685199701",
    HarmonyMarkerImage = "rbxassetid://6208151356",

    -- dropdown icons
    DropdownCloseImage = "rbxassetid://2064489060",
    DropdownOpenImage = "rbxassetid://367867055",

    -- palette page
    PaletteAddColorImage = "rbxassetid://919844482",
    PaletteRemoveColorImage = "rbxassetid://6213137847",
    PaletteColorMoveUpImage = "rbxassetid://330699522",
    PaletteColorMoveDownImage = "rbxassetid://330699633",

    -- Pages
    PageOptionsImage = "rbxassetid://6308568235",

    -- ColorBrewer data type icons
    CBDataTypeSequentialImage = "rbxassetid://6313201384",
    CBDataTypeDivergingImage = "rbxassetid://6308594803",
    CBDataTypeQualitativeImage = "rbxassetid://6308596898",

    -- editor icons
    ColorWheelEditorImage = "rbxassetid://6333198466",
    SliderEditorImage = "rbxassetid://6333325727",
    PaletteEditorImage = "rbxassetid://6333569516",

    -- cs editor icons
    CSEditorReverseSequenceImage = "rbxassetid://6409046433",
    CSEditorRemoveKeypointImage = "rbxassetid://6213137847",
    CSEditorSwapKeypointLeftImage = "rbxassetid://330699522",
    CSEditorSwapKeypointRightImage = "rbxassetid://330699633",

    -- toolbar
    ToolbarColorEditorImage = "rbxassetid://6498550308",
    ToolbarRefreshButtonImage = "rbxassetid://6498542225",

    -- other
    MarkerSize = 6,
    StandardCornerRadius = 4,
    StandardInputHeight = 22,
    DialogButtonWidth = 70,
    EditorPageWidth = 265,
}

Style.StandardButtonSize = Style.StandardTextSize + (Style.MinorElementPadding * 2)
Style.LargeButtonSize = Style.StandardButtonSize + (Style.MinorElementPadding * 2)

-- preload images
do
    local styleImages = {}

    for k, v in pairs(Style) do
        local start = string.find(k, "Image")

        if (start) then
            styleImages[#styleImages + 1] = v
        end
    end

    ContentProvider:PreloadAsync(styleImages)
end

return Style