local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Constants = require(PluginModules:FindFirstChild("Constants"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local Style = require(PluginModules:FindFirstChild("Style"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local TextInput = require(Components:FindFirstChild("TextInput"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardScrollingFrame = StandardComponents.ScrollingFrame
local StandardTextLabel = StandardComponents.TextLabel
local StandardUIListLayout = StandardComponents.UIListLayout
local StandardUIPadding = StandardComponents.UIPadding

---

local HUE_COLOR_SPACES = { 
    HSB = true,
    HWB = true,
    HSL = true,
    LChab = true,
    LChuv = true,
}

local COLOR_SPACE_NAMES = {
    LChab = "LCh(ab)",
    LChuv = "LCh(uv)", 
}

local HUE_ADJUSTMENT_NAMES = {
    Raw = "Specified"
}

local COLOR_SPACE_BUTTONS_PER_ROW = 4
local HUE_ADJUSTMENT_BUTTONS_PER_ROW = 3

local MIN_PRECISION = 0
local MAX_PRECISION = 18

local getMaxKeypointPrecision = function(numKeypoints): number
    if (numKeypoints == 2) then
        return MAX_PRECISION
    else
        return math.floor((Util.MAX_COLORSEQUENCE_KEYPOINTS - 1) / (numKeypoints - 1)) - 1
    end
end

---

--[[

    props

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
            text = COLOR_SPACE_NAMES[listColorSpace] or listColorSpace,

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
            text = HUE_ADJUSTMENT_NAMES[listHueAdjustment] or listHueAdjustment,

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
        CellPadding = UDim2.new(0, Style.MinorElementPadding, 0, Style.MinorElementPadding),
        CellSize = UDim2.new(1 / COLOR_SPACE_BUTTONS_PER_ROW, -math.ceil(Style.MinorElementPadding + (Style.MinorElementPadding / COLOR_SPACE_BUTTONS_PER_ROW)), 0, Style.StandardButtonSize),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    hueAdjustmentListElements.UIGridLayout = Roact.createElement("UIGridLayout", {
        CellPadding = UDim2.new(0, Style.MinorElementPadding, 0, Style.MinorElementPadding),
        CellSize = UDim2.new(1 / HUE_ADJUSTMENT_BUTTONS_PER_ROW, -math.ceil(Style.MinorElementPadding + (Style.MinorElementPadding / HUE_ADJUSTMENT_BUTTONS_PER_ROW)), 0, Style.StandardButtonSize),
        SortOrder = Enum.SortOrder.LayoutOrder,
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
        UIPadding = Roact.createElement(StandardUIPadding, {Style.PagePadding}),

        UIListLayout = Roact.createElement(StandardUIListLayout, {
            Padding = UDim.new(0, Style.SpaciousElementPadding),

            [Roact.Change.AbsoluteContentSize] = function(obj)
                self.updatePageLength(obj.AbsoluteContentSize.Y + (Style.PagePadding * 2))
            end,
        }),

        ColorSpaceSection = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, Style.StandardTextSize + (Style.StandardButtonSize * 3) + (Style.MinorElementPadding * 3)),
            BackgroundTransparency = 1,
            LayoutOrder = 0,
        }, {
            Header = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, Style.StandardTextSize),
    
                Text = "Color Space",
            }),
    
            ColorSpaceList = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, (Style.StandardButtonSize * 3) + (Style.MinorElementPadding * 2)),
                BackgroundTransparency = 1,
            }, colorSpaceListElements),
        }),

        HueAdjustmentSection = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, Style.StandardTextSize + (Style.StandardButtonSize * 2) + (Style.MinorElementPadding * 2)),
            BackgroundTransparency = 1,
            LayoutOrder = 1,
        }, {
            Header = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, Style.StandardTextSize),
    
                Text = "Hue Interpolation",
            }),

            HueAdjustmentList = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, (Style.StandardButtonSize * 2) + Style.MinorElementPadding),
                BackgroundTransparency = 1,
            }, hueAdjustmentListElements),
        }),

        PrecisionSection = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, Style.StandardTextSize + Style.StandardInputHeight + Style.MinorElementPadding),
            BackgroundTransparency = 1,
            LayoutOrder = 2,
        }, {
            Header = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, Style.StandardTextSize),
    
                Text = "Precision",
            }),
    
            PrecisionInputs = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, Style.StandardInputHeight),
                BackgroundTransparency = 1,
            }, {
                UIListLayout = Roact.createElement(StandardUIListLayout, {
                    Padding = UDim.new(0, Style.MinorElementPadding),
                    FillDirection = Enum.FillDirection.Horizontal,
                }),
    
                SubtractPrecisionButton = Roact.createElement(Button, {
                    Size = UDim2.new(0, Style.StandardButtonSize, 0, Style.StandardButtonSize),
                    LayoutOrder = 0,
    
                    displayType = "image",
                    image = Style.SubtractImage,
                    disabled = (precision <= MIN_PRECISION),
    
                    onActivated = function()
                        local newPrecision = precision - 1
                        if (newPrecision < MIN_PRECISION) then return end

                        self.props.setPrecision(newPrecision)
                    end
                }),
    
                AddPrecisionButton = Roact.createElement(Button, {
                    Size = UDim2.new(0, Style.StandardButtonSize, 0, Style.StandardButtonSize),
                    LayoutOrder = 2,
    
                    displayType = "image",
                    image = Style.AddImage,
                    disabled = (precision >= MAX_PRECISION) or (Util.getUtilisedKeypoints(numKeypoints, precision + 1) > Util.MAX_COLORSEQUENCE_KEYPOINTS),
    
                    onActivated = function()
                        local newPrecision = precision + 1
                        if (newPrecision > MAX_PRECISION) then return end

                        self.props.setPrecision(newPrecision)
                    end
                }),

                MaxPrecisionButton = Roact.createElement(Button, {
                    Size = UDim2.new(0, 40, 0, Style.StandardButtonSize),
                    LayoutOrder = 3,
    
                    displayType = "text",
                    text = "Max",
                    disabled = (precision >= MAX_PRECISION) or (precision >= maxPrecision),
    
                    onActivated = function()
                        self.props.setPrecision(maxPrecision)
                    end
                }),
    
                PrecisionInput = Roact.createElement(TextInput, {
                    Size = UDim2.new(0, 40, 0, Style.StandardInputHeight),
                    LayoutOrder = 1,

                    Text = precision,
                    TextXAlignment = Enum.TextXAlignment.Center,

                    isTextAValidValue = function(text)
                        local n = tonumber(text)
                        if (not n) then return false end
                        if (math.floor(n) ~= n) then return false end

                        return (n >= MIN_PRECISION) and (n <= MAX_PRECISION) and (Util.getUtilisedKeypoints(numKeypoints, n) <= Util.MAX_COLORSEQUENCE_KEYPOINTS)
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