--!strict
-- GUI styling information and image IDs

---

local Style = {
    UDim2 = {},

    Fonts = {
        Standard = Enum.Font.SourceSans,
        Monospaced = Enum.Font.RobotoMono,
    },

    Constants = {
        -- Paddings
        MajorElementPadding = 16,
        MinorElementPadding = 4,
        SpaciousElementPadding = 8,
        PagePadding = 8,
        TextObjectPadding = 4,

        -- Element sizes
        MarkerSize = 8,

        StandardTextSize = 14,
        LargeTextSize = 18,

        DialogButtonWidth = 70,
        EditorPageWidth = 265,
        ColorWheelRingWidth = 20,
        ColorSequencePreviewWidth = 62,
        ScrollbarThickness = 16,

        -- Misc.
        StandardCornerRadius = 4,
    },

    Images = {
        -- Color wheel images
        HueWheel = "rbxassetid://5686040244",
        SBPlane = "rbxassetid://5685199701",

        -- Color harmony icons
        HarmonyMarker = "rbxassetid://6208151356",
        NoHarmonyButtonIcon = "rbxassetid://6237978084",
        ComplementaryHarmonyButtonIcon = "rbxassetid://6237986907",
        AnalogousHarmonyButtonIcon = "rbxassetid://6237983501",
        TriadicHarmonyButtonIcon = "rbxassetid://6237989125",
        SplitComplementaryButtonIcon = "rbxassetid://6237993440",
        SquareHarmonyButtonIcon = "rbxassetid://6237995215",
        TetradicHarmonyButtonIcon = "rbxassetid://6237996947",
        HexagonalHarmonyButtonIcon = "rbxassetid://6238003104",

        -- ColorBrewer palette types
        SequentialDataTypeButtonIcon = "rbxassetid://6313201384",
        DivergingDataTypeButtonIcon = "rbxassetid://6308594803",
        QualitativeDataTypeButtonIcon = "rbxassetid://6308596898",

        -- Palette controls
        GridViewButtonIcon = "rbxassetid://6541631629",
        ListViewButtonIcon = "rbxassetid://6313201384",

        -- Color Editor buttons
        ColorWheelEditorButtonIcon = "rbxassetid://6333198466",
        SlidersEditorButtonIcon = "rbxassetid://6333325727",
        PaletteEditorButtonIcon = "rbxassetid://6333569516",
        ColorToolsEditorButtonIcon = "rbxassetid://8988492544",
        RandomColorButtonIcon = "rbxassetid://15839330129",

        -- Gradient editor buttons
        ReverseGradientButtonIcon = "rbxassetid://6409046433",
        GradientInfoButtonIcon = "rbxassetid://6554131676",
        ShowCodeButtonIcon = "rbxassetid://8521488559",
        HideCodeButtonIcon  = "rbxassetid://8521969115",

        -- Dropdown buttons
        CloseDropdownButtonIcon = "rbxassetid://2064489060",
        OpenDropdownButtonIcon = "rbxassetid://367867055",

        -- Async status icons
        ResultOkIcon = "rbxassetid://1469818624",
        ResultNotOkIcon = "rbxassetid://367878870",
        ResultWaitingIcon = "rbxassetid://6973265105",

        -- Generic control buttons
        MoveUpButtonIcon = "rbxassetid://965323360",
        MoveDownButtonIcon = "rbxassetid://913309373",
        MoveLeftButtonIcon = "rbxassetid://330699522",
        MoveRightButtonIcon = "rbxassetid://330699633",

        AddButtonIcon = "rbxassetid://919844482",
        SubtractButtonIcon = "rbxassetid://6213137847",
        DeleteButtonIcon = "rbxassetid://919846965",

        -- Misc. UI
        PageOptionsButtonIcon = "rbxassetid://6308568235",
        ScrollbarImage = "rbxassetid://590077572",
        SearchHistoryButtonIcon = "rbxassetid://9126497911",
        ColorSequenceTypeIcon = "rbxassetid://1097454788",

        -- Companion toolbar buttons
        ColorEditorToolbarButtonIcon = "rbxassetid://7066707717",
        GradientEditorToolbarButtonIcon = "rbxassetid://7066742393",
        SettingsToolbarButtonIcon = "rbxassetid://6528624327",
    }
}

-- Derived values

Style.Constants.StandardButtonHeight = Style.Constants.StandardTextSize + (Style.Constants.MinorElementPadding * 2)
Style.Constants.LargeButtonHeight = Style.Constants.StandardButtonHeight + (Style.Constants.MinorElementPadding * 2)
Style.Constants.StandardInputHeight = Style.Constants.StandardButtonHeight

Style.UDim2.StandardButtonSize = UDim2.new(0, Style.Constants.StandardButtonHeight, 0, Style.Constants.StandardButtonHeight)
--Style.UDim2.LargeButtonSize = UDim2.new(0, Style.Constants.LargeButtonHeight, 0, Style.Constants.LargeButtonHeight)
Style.UDim2.DialogButtonSize = UDim2.new(0, Style.Constants.DialogButtonWidth, 0, Style.Constants.StandardButtonHeight)
Style.UDim2.ButtonBarSize = UDim2.new(1, 0, 0, Style.Constants.StandardButtonHeight)
Style.UDim2.MarkerSize = UDim2.new(0, Style.Constants.MarkerSize, 0, Style.Constants.MarkerSize)
Style.UDim2.MinorElementPaddingSize = UDim2.new(0, Style.Constants.MinorElementPadding, 0, Style.Constants.MinorElementPadding)

---

return Style