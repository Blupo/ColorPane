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
    SBPlaneImage = "rbxassetid://5685199701",
    HarmonyMarkerImage = "rbxassetid://6208151356",

    -- dropdown icons
    DropdownCloseImage = "rbxassetid://2064489060",
    DropdownOpenImage = "rbxassetid://367867055",

    -- palette page
    PaletteGridViewImage = "rbxassetid://6541631629",
    PaletteListViewImage = "rbxassetid://6313201384",
    PaletteColorMoveUpImage = "rbxassetid://965323360",
    PaletteColorMoveDownImage = "rbxassetid://913309373",
    PaletteColorMoveLeftImage = "rbxassetid://330699522",
    PaletteColorMoveRightImage = "rbxassetid://330699633",

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
    ColorInfoEditorImage = "rbxassetid://6554131676",

    -- cs editor icons
    CSEditorReverseSequenceImage = "rbxassetid://6409046433",
    CSEditorSwapKeypointLeftImage = "rbxassetid://330699522",
    CSEditorSwapKeypointRightImage = "rbxassetid://330699633",

    -- toolbar
    ToolbarColorEditorButtonImage = "rbxassetid://7066707717",
    ToolbarGradientEditorButtonImage = "rbxassetid://7066742393",
    ToolbarInjectAPIButtonImage = "rbxassetid://6498542225",
    ToolbarSettingsButtonImage = "rbxassetid://6528624327",
    ToolbarColorPropertiesButtonImage = "rbxassetid://6531028502",

    -- status
    StatusGoodImage = "rbxassetid://1469818624",
    StatusBadImage = "rbxassetid://367878870",
    StatusWaitingImage = "rbxassetid://6973265105",

    -- add/remove
    AddImage = "rbxassetid://919844482",
    SubtractImage = "rbxassetid://6213137847",
    DeleteImage = "rbxassetid://919846965",

    -- other
    MarkerSize = 8,
    StandardCornerRadius = 4,
    StandardInputHeight = 22,
    DialogButtonWidth = 70,
    EditorPageWidth = 265,
    ColorSequencePreviewWidth = 62,
}

Style.StandardButtonSize = Style.StandardTextSize + (Style.MinorElementPadding * 2)
Style.LargeButtonSize = Style.StandardButtonSize + (Style.MinorElementPadding * 2)

-- preload images
do
    local styleImages = {}

    for key, value in pairs(Style) do
        local start = string.find(key, "Image")

        if (start) then
            local newImageLabel = Instance.new("ImageLabel")
            newImageLabel.Image = value

            table.insert(styleImages, newImageLabel)
        end
    end

    ContentProvider:PreloadAsync(styleImages)

    for i = 1, #styleImages do
        styleImages[i]:Destroy()
    end
end

return Style