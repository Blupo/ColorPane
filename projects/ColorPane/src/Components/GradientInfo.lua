local root = script.Parent.Parent
local Common = root.Common

local CommonPluginModules = Common.PluginModules
local Style = require(CommonPluginModules.Style)
local Translator = require(CommonPluginModules.Translator)

local CommonIncludes = Common.Includes
local Roact = require(CommonIncludes.RoactRodux.Roact)
local RoactRodux = require(CommonIncludes.RoactRodux.RoactRodux)

local CommonComponents = Common.Components
local Button = require(CommonComponents.Button)
local TextInput = require(CommonComponents.TextInput)

local StandardComponents = CommonComponents.StandardComponents
local StandardScrollingFrame = require(StandardComponents.ScrollingFrame)
local StandardTextLabel = require(StandardComponents.TextLabel)
local StandardUIListLayout = require(StandardComponents.UIListLayout)
local StandardUIPadding = require(StandardComponents.UIPadding)

local PluginModules = root.PluginModules
local Constants = require(PluginModules.Constants)
local PluginEnums = require(PluginModules.PluginEnums)
local Util = require(PluginModules.Util)

---

local HUE_COLOR_SPACES = { 
    HSB = true,
    HWB = true,
    HSL = true,
    LChab = true,
    LChuv = true,
}

local COLOR_SPACE_BUTTONS_PER_ROW = 4
local HUE_ADJUSTMENT_BUTTONS_PER_ROW = 3

local MIN_PRECISION = 0
local MAX_PRECISION = 18

local uiTranslations = Translator.GenerateTranslationTable({
    "RGB_ColorType",
    "CMYK_ColorType",
    "HSB_ColorType",
    "HSL_ColorType",
    "HWB_ColorType",
    "Lab_ColorType",
    "Luv_ColorType",
    "LChab_ColorType",
    "LChuv_ColorType",
    "xyY_ColorType",
    "XYZ_ColorType",
    
    "Shorter_HueInterpolation",
    "Longer_HueInterpolation",
    "Increasing_HueInterpolation",
    "Decreasing_HueInterpolation",
    "Specified_HueInterpolation",

    "ColorSpace_Label",
    "HueInterpolation_Label",
    "Precision_Label",
    "MaxKeypoints_ButtonText",
    "Reset_ButtonText",
})

local getMaxKeypointPrecision = function(numKeypoints): number
    if (numKeypoints == 2) then
        return MAX_PRECISION
    else
        return math.floor((Constants.MAX_COLORSEQUENCE_KEYPOINTS - 1) / (numKeypoints - 1)) - 1
    end
end

---

--[[
    store props

        theme: StudioTheme
        colorSpace: string?
        hueAdjustment: string?
        precision: number?

        setColorSpace: (string) -> nil
        setHueAdjustment: (string) -> nil
        setPrecision: (number) -> nil
]]

local GradientInfo = Roact.PureComponent:extend("GradientInfo")

GradientInfo.init = function(self)
    self.pageLength, self.updatePageLength = Roact.createBinding(0)
end

GradientInfo.render = function(self)
    local theme = self.props.theme
    
    local colorSpace = self.props.colorSpace
    local hueAdjustment = self.props.hueAdjustment
    local precision = self.props.precision

    local numKeypoints = #self.props.keypoints
    local maxPrecision = getMaxKeypointPrecision(numKeypoints)

    local colorSpaceListElements = {}
    local hueAdjustmentListElements = {}

    for i = 1, #Constants.VALID_GRADIENT_COLOR_SPACES do
        local listColorSpace = Constants.VALID_GRADIENT_COLOR_SPACES[i]
        local selected = (listColorSpace == colorSpace)

        colorSpaceListElements[listColorSpace] = Roact.createElement(Button, {
            LayoutOrder = i,

            displayType = "text",
            text = uiTranslations[listColorSpace .. "_ColorType"],

            hoverColor = selected and
                theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Selected)
            or nil,

            borderColor = selected and
                theme:GetColor(Enum.StudioStyleGuideColor.ButtonBorder, Enum.StudioStyleGuideModifier.Selected)
            or nil,

            backgroundColor = selected and
                theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Selected)
            or nil,

            displayColor = selected and
                theme:GetColor(Enum.StudioStyleGuideColor.ButtonText, Enum.StudioStyleGuideModifier.Selected)
            or nil,

            onActivated = function()
                self.props.setColorSpace(listColorSpace)
            end,
        })
    end

    for i = 1, #Constants.VALID_HUE_ADJUSTMENTS do
        local listHueAdjustment = Constants.VALID_HUE_ADJUSTMENTS[i]
        local selected = (listHueAdjustment == hueAdjustment)

        hueAdjustmentListElements[listHueAdjustment] = Roact.createElement(Button, {
            LayoutOrder = i,

            disabled = (not HUE_COLOR_SPACES[colorSpace]),
            displayType = "text",
            text = uiTranslations[listHueAdjustment .. "_HueInterpolation"],

            hoverColor = selected and
                theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Selected)
            or nil,

            borderColor = selected and
                theme:GetColor(Enum.StudioStyleGuideColor.ButtonBorder, Enum.StudioStyleGuideModifier.Selected)
            or nil,

            backgroundColor = selected and
                theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Selected)
            or nil,

            displayColor = selected and
                theme:GetColor(Enum.StudioStyleGuideColor.ButtonText, Enum.StudioStyleGuideModifier.Selected)
            or nil,

            onActivated = function()
                self.props.setHueAdjustment(listHueAdjustment)
            end,
        })
    end

    colorSpaceListElements.UIGridLayout = Roact.createElement("UIGridLayout", {
        CellPadding = Style.UDim2.MinorElementPaddingSize,
        SortOrder = Enum.SortOrder.LayoutOrder,
        
        CellSize = UDim2.new(
            1 / COLOR_SPACE_BUTTONS_PER_ROW, -math.ceil(Style.Constants.MinorElementPadding + (Style.Constants.MinorElementPadding / COLOR_SPACE_BUTTONS_PER_ROW)),
            0, Style.Constants.StandardButtonHeight
        ),
    })

    hueAdjustmentListElements.UIGridLayout = Roact.createElement("UIGridLayout", {
        CellPadding = Style.UDim2.MinorElementPaddingSize,
        SortOrder = Enum.SortOrder.LayoutOrder,
        
        CellSize = UDim2.new(
            1 / HUE_ADJUSTMENT_BUTTONS_PER_ROW, -math.ceil(Style.Constants.MinorElementPadding + (Style.Constants.MinorElementPadding / HUE_ADJUSTMENT_BUTTONS_PER_ROW)),
            0, Style.Constants.StandardButtonHeight
        ),
    })

    return Roact.createElement(StandardScrollingFrame, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,

        CanvasSize = self.pageLength:map(function(length)
            return UDim2.new(0, 0, 0, length)
        end),
    }, {
        UIPadding = Roact.createElement(StandardUIPadding, {Style.Constants.PagePadding}),

        UIListLayout = Roact.createElement(StandardUIListLayout, {
            Padding = UDim.new(0, Style.Constants.SpaciousElementPadding),

            [Roact.Change.AbsoluteContentSize] = function(obj)
                self.updatePageLength(obj.AbsoluteContentSize.Y + (Style.Constants.PagePadding * 2))
            end,
        }),

        ColorSpaceSection = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize + (Style.Constants.StandardButtonHeight * 3) + (Style.Constants.MinorElementPadding * 3)),
            BackgroundTransparency = 1,
            LayoutOrder = 0,
        }, {
            Header = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
    
                Text = uiTranslations["ColorSpace_Label"],
            }),
    
            ColorSpaceList = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, (Style.Constants.StandardButtonHeight * 3) + (Style.Constants.MinorElementPadding * 2)),
                BackgroundTransparency = 1,
            }, colorSpaceListElements),
        }),

        HueAdjustmentSection = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize + (Style.Constants.StandardButtonHeight * 2) + (Style.Constants.MinorElementPadding * 2)),
            BackgroundTransparency = 1,
            LayoutOrder = 1,
        }, {
            Header = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
    
                Text = uiTranslations["HueInterpolation_Label"],
            }),

            HueAdjustmentList = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, (Style.Constants.StandardButtonHeight * 2) + Style.Constants.MinorElementPadding),
                BackgroundTransparency = 1,
            }, hueAdjustmentListElements),
        }),

        PrecisionSection = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize + Style.Constants.StandardInputHeight + Style.Constants.MinorElementPadding),
            BackgroundTransparency = 1,
            LayoutOrder = 2,
        }, {
            Header = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
    
                Text = uiTranslations["Precision_Label"],
            }),
    
            PrecisionInputs = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardInputHeight),
                BackgroundTransparency = 1,
            }, {
                UIListLayout = Roact.createElement(StandardUIListLayout, {
                    Padding = UDim.new(0, Style.Constants.MinorElementPadding),
                    FillDirection = Enum.FillDirection.Horizontal,
                }),
    
                SubtractPrecisionButton = Roact.createElement(Button, {
                    Size = Style.UDim2.StandardButtonSize,
                    LayoutOrder = 0,
    
                    displayType = "image",
                    image = Style.Images.SubtractButtonIcon,
                    disabled = (precision <= MIN_PRECISION),
    
                    onActivated = function()
                        local newPrecision = precision - 1
                        if (newPrecision < MIN_PRECISION) then return end

                        self.props.setPrecision(newPrecision)
                    end
                }),
    
                AddPrecisionButton = Roact.createElement(Button, {
                    Size = Style.UDim2.StandardButtonSize,
                    LayoutOrder = 2,
    
                    displayType = "image",
                    image = Style.Images.AddButtonIcon,
                    disabled = (precision >= MAX_PRECISION) or (Util.getUtilisedKeypoints(numKeypoints, precision + 1) > Constants.MAX_COLORSEQUENCE_KEYPOINTS),
    
                    onActivated = function()
                        local newPrecision = precision + 1
                        if (newPrecision > MAX_PRECISION) then return end

                        self.props.setPrecision(newPrecision)
                    end
                }),

                MaxPrecisionButton = Roact.createElement(Button, {
                    Size = UDim2.new(0, 40, 0, Style.Constants.StandardButtonHeight),
                    LayoutOrder = 3,
    
                    displayType = "text",
                    text = uiTranslations["MaxKeypoints_ButtonText"],
                    disabled = (precision >= MAX_PRECISION) or (precision >= maxPrecision),
    
                    onActivated = function()
                        self.props.setPrecision(maxPrecision)
                    end
                }),

                ResetPrecisionButton = Roact.createElement(Button, {
                    Size = UDim2.new(0, 40, 0, Style.Constants.StandardButtonHeight),
                    LayoutOrder = 4,
    
                    displayType = "text",
                    text = uiTranslations["Reset_ButtonText"],
                    disabled = (precision == 0),
    
                    onActivated = function()
                        self.props.setPrecision(0)
                    end
                }),
    
                PrecisionInput = Roact.createElement(TextInput, {
                    Size = UDim2.new(0, 40, 0, Style.Constants.StandardInputHeight),
                    LayoutOrder = 1,

                    Text = precision,
                    TextXAlignment = Enum.TextXAlignment.Center,

                    isTextAValidValue = function(text)
                        local n = tonumber(text)
                        if (not n) then return false end
                        if (math.floor(n) ~= n) then return false end

                        return (n >= MIN_PRECISION) and (n <= MAX_PRECISION) and (Util.getUtilisedKeypoints(numKeypoints, n) <= Constants.MAX_COLORSEQUENCE_KEYPOINTS)
                    end,
    
                    onSubmit = function(text)
                        local n = tonumber(text)

                        self.props.setPrecision(n)
                    end,
                    
                    canSubmitEmptyString = false,
                })
            })
        }),
    })
end

---

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,

        keypoints = state.gradientEditor.keypoints,
        colorSpace = state.gradientEditor.colorSpace,
        hueAdjustment = state.gradientEditor.hueAdjustment,
        precision = state.gradientEditor.precision,
    }
end, function(dispatch)
    return {
        setColorSpace = function(colorSpace: string)
            dispatch({
                type = PluginEnums.StoreActionType.GradientEditor_SetGradient,
                colorSpace = colorSpace
            })
        end,

        setHueAdjustment = function(hueAdjustment: string)
            dispatch({
                type = PluginEnums.StoreActionType.GradientEditor_SetGradient,
                hueAdjustment = hueAdjustment
            })
        end,

        setPrecision = function(precision: number)
            dispatch({
                type = PluginEnums.StoreActionType.GradientEditor_SetGradient,
                precision = precision
            })
        end,
    }
end)(GradientInfo)