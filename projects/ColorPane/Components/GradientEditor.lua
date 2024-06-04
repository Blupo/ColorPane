-- The entire gradient editor interface

local TextService = game:GetService("TextService")

---

local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local CommonEnums = require(CommonModules.Enums)
local Constants = require(CommonModules.Constants)
local Style = require(CommonModules.Style)
local Translator = require(CommonModules.Translator)
local Window = require(CommonModules.Window)

local CommonIncludes = Common.Includes
local Roact = require(CommonIncludes.RoactRodux.Roact)
local RoactRodux = require(CommonIncludes.RoactRodux.RoactRodux)

local CommonComponents = Common.Components
local Button = require(CommonComponents.Button)
local TextInput = require(CommonComponents.TextInput)

local StandardComponents = CommonComponents.StandardComponents
local StandardTextLabel = require(StandardComponents.TextLabel)
local StandardUICorner = require(StandardComponents.UICorner)
local StandardUIListLayout = require(StandardComponents.UIListLayout)
local StandardUIPadding = require(StandardComponents.UIPadding)

local Components = root.Components
local GradientInfo = require(Components.GradientInfo)
--local GradientPalette = require(Components.GradientPalette)

local Includes = root.Includes
local ColorLib = require(Includes.Color)

local Modules = root.Modules
local Enums = require(Modules.Enums)
local GradientEditorInputSignals = require(Modules.EditorInputSignals).GradientEditor
local Store = require(Modules.Store)
local Util = require(Modules.Util)
local WidgetInfo = require(Modules.WidgetInfo)

local Color, Gradient = ColorLib.Color, ColorLib.Gradient

---

local CURSOR_KEYPOINT_SNAP_VALUE = 0.01

local uiTranslations = Translator.GenerateTranslationTable({
    "SnapInput_Label",
    "Reset_ButtonText",
    "GradientInfo_WindowTitle",
    "GradientPalette_WindowTitle"
})

local getNearestKeypointIndex = function(keypoints, time: number): (number?, number?)
    if (time == 0) then
        return 1, 0
    elseif (time == 1) then
        return #keypoints, 0
    end

    for i = 1, (#keypoints - 1) do
        local thisKeypoint, nextKeypoint = keypoints[i], keypoints[i + 1]
        local thisKeypointTime, nextKeypointTime = thisKeypoint.Time, nextKeypoint.Time

        if ((time >= thisKeypointTime) and (time < nextKeypointTime)) then
            local thisTimeDiff = time - thisKeypointTime
            local nextTimeDiff = nextKeypointTime - time

            if (thisTimeDiff < nextTimeDiff) then
                return i, thisTimeDiff
            else
                return (i + 1), nextTimeDiff
            end
        end
    end

    return
end

local getColorSequenceCode = function(keypoints): string
    local code = "ColorSequence.new({"

    for i = 1, #keypoints do
        local keypoint = keypoints[i]

        code = code ..
            string.format("\n    ColorSequenceKeypoint.new(%f, Color3.new(%f, %f, %f))", keypoint.Time, keypoint.Color:components()) ..
            (if (i ~= #keypoints) then "," else "")
    end

    code = code .. "\n})"
    return code
end

---

--[[
    props
        originalKeypoints: array<GradientKeypoint>
        originalColorSpace: string
        originalHueAdjustment: string
        originalPrecision: number
        fireFinished: FireSignal<boolean>

        promptForColorEdit: (ColorPromptOptions?) -> Promise<Color>

    store props
        theme: StudioTheme
        state: table

        keypoints: array<Gradientkeypoint>
        colorSpace: string
        hueAdjustment: string?
        precision: number
        timeSnapValue: number

        resetState: () -> nil
        setKeypoints: (array<GradientKeypoint>?, number?) -> nil
        setSnapValue: (number) -> nil
]]

local GradientEditor = Roact.PureComponent:extend("GradientEditor")

GradientEditor.init = function(self)
    self.timelineStartPosition, self.updateTimelineStartPosition = Roact.createBinding(Vector2.new(0, 0))
    self.timelineWidth, self.updateTimelineWidth = Roact.createBinding(0)
    self.timelineProgress, self.updateTimelineProgress = Roact.createBinding(0)

    self.gradientInfoWindow = Window.new(WidgetInfo.GradientInfo.Id, WidgetInfo.GradientInfo.Info)
    self.gradientPaletteWindow = Window.new(WidgetInfo.GradientPalette.Id, WidgetInfo.GradientPalette.Info)

    self.markerTime = self.timelineProgress:map(function(timelineProgress)
        local keypoints = self.props.keypoints

        local nearestKeypoint, nearestKeypointTimeDiff = getNearestKeypointIndex(keypoints, timelineProgress)
        local isKeypointInSnapProximity = (nearestKeypointTimeDiff < CURSOR_KEYPOINT_SNAP_VALUE)

        return (if isKeypointInSnapProximity then keypoints[nearestKeypoint].Time else timelineProgress)
    end)

    self.getNewKeypointTime = function(time: number, snapValue: number?): number?
        local keypoints = self.props.keypoints
        local selectedKeypoint = self.props.selectedKeypoint
        local timeSnapValue = snapValue or self.props.timeSnapValue

        local newTime = Util.round(time, math.log10(timeSnapValue))
        local nearestKeypoint, nearestKeypointTimeDiff = getNearestKeypointIndex(keypoints, time)

        if (nearestKeypointTimeDiff < timeSnapValue) then
            if (nearestKeypoint == 1) then
                newTime = timeSnapValue
            elseif (nearestKeypoint == #keypoints) then
                newTime = 1 - timeSnapValue
            else
                local nearestKeypointTime = keypoints[nearestKeypoint].Time

                if (nearestKeypoint < selectedKeypoint) then
                    newTime = math.min(nearestKeypointTime + timeSnapValue, 1)
                elseif (nearestKeypoint > selectedKeypoint) then
                    newTime = math.max(nearestKeypointTime - timeSnapValue, 0)
                end
            end

            nearestKeypoint, nearestKeypointTimeDiff = getNearestKeypointIndex(keypoints, newTime)

            if (nearestKeypointTimeDiff < timeSnapValue) then
                newTime = nil
            end
        end

        return newTime
    end

    self.updateSelectedKeypointTime = function(cursorPosition)
        local selectedKeypointIndex = self.props.selectedKeypoint
        if ((selectedKeypointIndex == 1) or (selectedKeypointIndex == #self.props.keypoints)) then return end

        local keypoints = Util.table.deepCopy(self.props.keypoints)

        local distanceFromStart = cursorPosition - self.timelineStartPosition:getValue()
        local newTime = self.getNewKeypointTime(math.clamp(distanceFromStart.X / self.timelineWidth:getValue(), 0, 1))
        if (not newTime) then return end

        local newKeypoint = { Time = newTime, Color = keypoints[selectedKeypointIndex].Color }
        keypoints[selectedKeypointIndex] = newKeypoint

        table.sort(keypoints, function(keypointA, keypointB)
            return keypointA.Time < keypointB.Time
        end)

        local newKeypointIndex = table.find(keypoints, newKeypoint)

        self.props.setKeypoints(keypoints, newKeypointIndex)
    end

    self.removeKeypoint = function(index)
        local keypoints = Util.table.deepCopy(self.props.keypoints)

        table.remove(keypoints, index)
        self.props.setKeypoints(keypoints, -1)
    end

    self:setState({
        tracking = false,
        showTimelineMarker = false,
    })
end

GradientEditor.didMount = function(self)
    self.mousePositionChanged = GradientEditorInputSignals.MousePositionChanged.Event:subscribe(function(cursorPosition: Vector2)
        local distanceFromStart = cursorPosition - self.timelineStartPosition:getValue()
        self.updateTimelineProgress(math.clamp(distanceFromStart.X / self.timelineWidth:getValue(), 0, 1))

        if (self.state.tracking and self.props.selectedKeypoint) then
            self.updateSelectedKeypointTime(cursorPosition)
        end
    end)
end

GradientEditor.willUnmount = function(self)
    self.unmounting = true

    self.gradientInfoWindow:destroy()
    self.gradientPaletteWindow:destroy()

    if (self.state.colorEditPromise) then
        self.state.colorEditPromise:cancel()
    end
    
    if (self.mousePositionChanged) then
        self.mousePositionChanged:unsubscribe()
    end
end

GradientEditor.render = function(self)
    local theme = self.props.theme

    local keypoints = Util.table.deepCopy(self.props.keypoints)
    local displayKeypoints = self.props.displayKeypoints
    local colorSpace = self.props.colorSpace
    local hueAdjustment = self.props.hueAdjustment
    local precision = self.props.precision

    local selectedKeypoint = self.props.selectedKeypoint
    local timeSnapValue = self.props.timeSnapValue

    local colorEditPromise = self.state.colorEditPromise
    local showCode = self.state.showCode
    local maxUserKeypoints = Util.getMaxUserKeypoints(Constants.MAX_COLORSEQUENCE_KEYPOINTS, precision)

    local gradient = Gradient.new(keypoints)
    local displayGradient = Gradient.new(displayKeypoints)

    local gradientElements = {}
    local colorSequenceCode
    local colorSequenceCodeTextSize

    if (showCode) then
        colorSequenceCode = getColorSequenceCode(displayKeypoints)

        colorSequenceCodeTextSize = TextService:GetTextSize(
            colorSequenceCode,
            Style.Constants.StandardTextSize,
            Enum.Font.Code,
            Vector2.new(math.huge, math.huge)
        )
    end

    for i = 1, #keypoints do
        local keypoint = keypoints[i]
        local isFixed = (i == 1) or (i == #keypoints)

        table.insert(gradientElements, Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(keypoint.Time, 0, 0.5, 0),
            Size = Style.UDim2.MarkerSize,
            BorderSizePixel = 0,
            ZIndex = 2,

            BackgroundColor3 = keypoint.Color:bestContrastingColor(
                Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)):invert()
            ):toColor3(),
        }, {
            UICorner = if (not isFixed) then
                Roact.createElement(StandardUICorner)
            else nil,

            Inner = if (selectedKeypoint == i) then
                Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(1, -2, 1, -2),
                    BorderSizePixel = 0,
                    
                    BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder, Enum.StudioStyleGuideModifier.Selected),
                }, {
                    UICorner = if (not isFixed) then
                        Roact.createElement(StandardUICorner)
                    else nil,
                })
            else nil
        }))
    end

    gradientElements.TimelineMarker = if (self.state.showTimelineMarker) then
        Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 1, 1, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            Position = self.markerTime:map(function(markerTime)
                return UDim2.new(markerTime, 0, 0.5, 0)
            end),

            BackgroundColor3 = self.markerTime:map(function(markerTime)
                return displayGradient:color(markerTime):bestContrastingColor(
                    Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                    Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)):invert()
                ):toColor3()
            end),
        })
    else nil

    gradientElements.UICorner = Roact.createElement(StandardUICorner)
    gradientElements.UIGradient = Roact.createElement("UIGradient", {
        Color = displayGradient:colorSequence()
    })

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame),

        [Roact.Event.InputBegan] = function(_, input)
            if (input.UserInputType ~= Enum.UserInputType.Keyboard) then return end
            if (not selectedKeypoint) then return end

            local keyCode = input.KeyCode
            local nextSelected

            if (keyCode == Enum.KeyCode.Left) then
                nextSelected = selectedKeypoint - 1
            elseif (keyCode == Enum.KeyCode.Right) then
                nextSelected = selectedKeypoint + 1
            end

            if (not keypoints[nextSelected]) then return end

            self.props.setKeypoints(nil, nextSelected)

            self:setState({
                tracking = false,
            })
        end,
    }, {
        UIPadding = Roact.createElement(StandardUIPadding, {
            paddings = {Style.Constants.PagePadding}
        }),

        GradientEditor = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, -60),
            BackgroundTransparency = 1,
        }, {
            Border = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 0,

                BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
            }, {
                UICorner = Roact.createElement(StandardUICorner),

                Editor = if (not showCode) then
                    Roact.createElement("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        Size = UDim2.new(1, -2, 1, -2),
                        BackgroundTransparency = 0,
                        ClipsDescendants = true,

                        BackgroundColor3 = Color3.new(1, 1, 1),

                        [Roact.Event.InputBegan] = function(_, input)
                            if (input.UserInputType == Enum.UserInputType.MouseMovement) then
                                self:setState({
                                    showTimelineMarker = true,
                                })
                            else
                                if (colorEditPromise) then return end

                                local timelineProgress = self.timelineProgress:getValue()
                                local nearestKeypoint, nearestKeypointTimeDiff = getNearestKeypointIndex(keypoints, timelineProgress)
                                local isKeypointInSnapProximity = (nearestKeypointTimeDiff < CURSOR_KEYPOINT_SNAP_VALUE)

                                if (input.UserInputType == Enum.UserInputType.MouseButton1) then
                                    if (isKeypointInSnapProximity) then
                                        self.props.setKeypoints(nil, nearestKeypoint)

                                        self:setState({
                                            tracking = true
                                        })
                                    else
                                        if (#keypoints < maxUserKeypoints) then
                                            local newKeypointTime = self.getNewKeypointTime(timelineProgress)
                                            if (not newKeypointTime) then return end

                                            local newKeypoint = { Time = newKeypointTime, Color = gradient:color(newKeypointTime, colorSpace, hueAdjustment) }
                                            table.insert(keypoints, newKeypoint)

                                            table.sort(keypoints, function(keypointA, keypointB)
                                                return keypointA.Time < keypointB.Time
                                            end)

                                            local newKeypointIndex = table.find(keypoints, newKeypoint)

                                            self.props.setKeypoints(keypoints, newKeypointIndex)

                                            --[[
                                                Defer tracking to prevent the currently-selected
                                                keypoint from being tracked instead of the
                                                newly-created one
                                            ]]
                                            task.defer(function()
                                                self:setState({
                                                    tracking = true,
                                                })
                                            end)
                                        end
                                    end
                                elseif (input.UserInputType == Enum.UserInputType.MouseButton2) then
                                    if (not isKeypointInSnapProximity) then return end
                                    if ((nearestKeypoint == 1) or (nearestKeypoint == #keypoints)) then return end

                                    self.removeKeypoint(nearestKeypoint)
                                end
                            end
                        end,
            
                        [Roact.Event.InputEnded] = function(_, input)
                            if (input.UserInputType == Enum.UserInputType.MouseMovement) then
                                self:setState({
                                    showTimelineMarker = false,
                                })
                            elseif ((input.UserInputType == Enum.UserInputType.MouseButton1) and self.state.tracking) then
                                self:setState({
                                    tracking = false,
                                })
                            end
                        end,
        
                        [Roact.Change.AbsolutePosition] = function(obj)
                            self.updateTimelineStartPosition(obj.AbsolutePosition)
                            self.updateTimelineWidth(obj.AbsoluteSize.X)
                        end,
            
                        [Roact.Change.AbsoluteSize] = function(obj)
                            self.updateTimelineStartPosition(obj.AbsolutePosition)
                            self.updateTimelineWidth(obj.AbsoluteSize.X)
                        end,
                    }, gradientElements)
                else nil,

                ColorSequenceCode = if (showCode) then
                    Roact.createElement("ScrollingFrame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,

                        CanvasSize = UDim2.new(
                            0, colorSequenceCodeTextSize.X + (Style.Constants.MinorElementPadding * 2),
                            0, colorSequenceCodeTextSize.Y + (Style.Constants.MinorElementPadding * 2)
                        ),

                        ClipsDescendants = true,
                        TopImage = Style.Images.ScrollbarImage,
                        MidImage = Style.Images.ScrollbarImage,
                        BottomImage = Style.Images.ScrollbarImage,
                        HorizontalScrollBarInset = Enum.ScrollBarInset.Always,
                        VerticalScrollBarInset = Enum.ScrollBarInset.Always,
                        VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right,
                        ScrollBarThickness = Style.Constants.ScrollbarThickness / 4,

                        ScrollBarImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ScrollBar),
                    }, {
                        UIPadding = Roact.createElement(StandardUIPadding, {
                            paddings = {Style.Constants.MinorElementPadding}
                        }),

                        TextBox = Roact.createElement("TextBox", {
                            AnchorPoint = Vector2.new(0, 0),
                            Position = UDim2.new(0, 0, 0, 0),
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,

                            Text = colorSequenceCode,
                            Font = Enum.Font.Code,
                            TextSize = Style.Constants.StandardTextSize,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextYAlignment = Enum.TextYAlignment.Top,
                            ClearTextOnFocus = false,
                            TextEditable = false,

                            TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),

                            [Roact.Event.Focused] = function(obj)
                                obj.CursorPosition = string.len(obj.Text) + 1
                                obj.SelectionStart = 1
                            end,
                        })
                    })
                else nil,
            }),
        }),

        SelectedKeypointInfo = if selectedKeypoint then
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, -(Style.Constants.StandardButtonHeight + Style.Constants.SpaciousElementPadding)),
                Size = UDim2.new(0.5, 0, 0, Style.Constants.StandardButtonHeight),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                ColorLabel = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.new(0, 28, 1, 0),
                    Text = "Color",
                }),

                EditColor = Roact.createElement(Button, {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0, 50, 1, 0),
                    Position = UDim2.new(0, 28 + Style.Constants.MinorElementPadding, 0.5, 0),

                    displayType = "color",
                    color = keypoints[selectedKeypoint].Color:toColor3(),
                    disabled = if colorEditPromise then true else false,

                    onActivated = function()
                        if (colorEditPromise) then
                            colorEditPromise:cancel()
                        end

                        local originalColor = keypoints[selectedKeypoint].Color

                        local editPromise = self.props.promptForColorEdit({
                            PromptTitle = string.format("Gradient keypoint, %.3f%%", keypoints[selectedKeypoint].Time * 100),
                            ColorType = "Color",
                            InitialColor = originalColor,

                            OnColorChanged = function(color)
                                local newKeypoints = Util.table.deepCopy(self.props.keypoints)
                                local keypoint = newKeypoints[selectedKeypoint]

                                newKeypoints[selectedKeypoint] = { Time = keypoint.Time, Color = color }

                                self.props.setKeypoints(newKeypoints)
                            end,
                        })

                        editPromise:andThen(function(newColor)
                            local newKeypoints = Util.table.deepCopy(self.props.keypoints)
                            local keypoint = keypoints[selectedKeypoint]

                            newKeypoints[selectedKeypoint] = { Time = keypoint.Time, Color = newColor }

                            self.props.setKeypoints(newKeypoints, nil)
                        end, function(err)
                            if (err == Enums.PromptRejection.PromptCancelled) then
                                local keypoint = keypoints[selectedKeypoint]

                                local newKeypoints = Util.table.deepCopy(self.props.keypoints)
                                newKeypoints[selectedKeypoint] = { Time = keypoint.Time, Color = originalColor }

                                self.props.setKeypoints(newKeypoints, nil)
                            end
                        end):finally(function()
                            if (not self.unmounting) then
                                self:setState({
                                    colorEditPromise = Roact.None,
                                })
                            end
                        end)

                        self:setState({
                            colorEditPromise = editPromise,
                        })
                    end
                }),

                ProgressInput = Roact.createElement(TextInput, {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 28 + 50 + Style.Constants.MinorElementPadding + Style.Constants.SpaciousElementPadding, 0.5, 0),
                    Size = UDim2.new(0, 50, 1, 0),
                    Text = string.format("%.3f", keypoints[selectedKeypoint].Time * 100),
                    TextXAlignment = Enum.TextXAlignment.Center,

                    isTextAValidValue = function(text)
                        local n = tonumber(text)
                        if (not n) then return false end

                        n = n / 100
                        return ((n > 0) and (n < 1))
                    end,
    
                    onSubmit = function(text)
                        local newTime = tonumber(text)
                        newTime = self.getNewKeypointTime(newTime / 100, Constants.MIN_SNAP_VALUE)
                        if (not newTime) then return end

                        local newKeypoint = { Time = newTime, Color = keypoints[selectedKeypoint].Color }
                        keypoints[selectedKeypoint] = newKeypoint

                        table.sort(keypoints, function(keypointA, keypointB)
                            return keypointA.Time < keypointB.Time
                        end)

                        local newKeypointIndex = table.find(keypoints, newKeypoint)

                        self.props.setKeypoints(keypoints, newKeypointIndex)
                    end,
                    
                    disabled = if colorEditPromise then true else false,
                }),

                ProgressLabel = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 28 + 50 + 50 + (Style.Constants.MinorElementPadding * 2) + Style.Constants.SpaciousElementPadding, 0.5, 0),
                    Size = UDim2.new(0, 10, 1, 0),
                    Text = "%",
                }),
            })
        else nil,

        GradientInfo = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, 0, 1, -(Style.Constants.StandardButtonHeight + Style.Constants.SpaciousElementPadding)),
            Size = UDim2.new(0, 180 + Style.Constants.StandardButtonHeight, 0, Style.Constants.StandardButtonHeight),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            UIListLayout = Roact.createElement(StandardUIListLayout, {
                Padding = UDim.new(0, Style.Constants.SpaciousElementPadding),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            }),

            InfoLabel = Roact.createElement(StandardTextLabel, {
                Size = UDim2.new(0, 180, 0, Style.Constants.StandardTextSize),
                LayoutOrder = 0,

                Text = Translator.FormatByKey("KeypointReadout_Label", { #keypoints, maxUserKeypoints }),
                TextXAlignment = Enum.TextXAlignment.Right,
                TextYAlignment = Enum.TextYAlignment.Center,
                
                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
            }),

            CodeButton = Roact.createElement(Button, {
                Size = Style.UDim2.StandardButtonSize,
                LayoutOrder = 1,

                displayType = "image",
                image = if showCode then Style.Images.HideCodeButtonIcon else Style.Images.ShowCodeButtonIcon,

                onActivated = function()
                    local newShowCode = (not showCode)

                    if (newShowCode) then
                        if (colorEditPromise) then
                            colorEditPromise:cancel()
                        end

                        self.props.setKeypoints(nil, -1)
                    end

                    self:setState({
                        showCode = newShowCode,
                        colorEditPromise = if newShowCode then Roact.None else nil,
                        tracking = false,
                    })
                end,
            }),

            GradientInfoButton = Roact.createElement(Button, {
                Size = Style.UDim2.StandardButtonSize,
                LayoutOrder = 2,

                displayType = "image",
                image = Style.Images.GradientInfoButtonIcon,

                onActivated = function()
                    if (self.gradientInfoWindow:isMounted()) then
                        self.gradientInfoWindow:unmount()
                    else
                        self.gradientInfoWindow:mount(
                            uiTranslations["GradientInfo_WindowTitle"],
                            Roact.createElement(GradientInfo),
                            Store
                        )
                    end
                end,
            })
        }),

        EditorActions = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(0, 274, 0, Style.Constants.StandardButtonHeight),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            UIListLayout = Roact.createElement(StandardUIListLayout, {
                Padding = UDim.new(0, Style.Constants.SpaciousElementPadding),
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            }),

            -- keypoint must be selected
            -- t ~= 0, 1
            RemoveKeypointButton = Roact.createElement(Button, {
                LayoutOrder = 1,

                displayType = "image",
                image = Style.Images.DeleteButtonIcon,
                disabled = (colorEditPromise or (not selectedKeypoint) or (selectedKeypoint == 1) or (selectedKeypoint == #keypoints)),

                onActivated = function()
                    self.removeKeypoint(selectedKeypoint)
                end,
            }),

            -- keypoint must be selected
            -- t ~= 0
            SwapKeypointLeftButton = Roact.createElement(Button, {
                LayoutOrder = 2,

                displayType = "image",
                image = Style.Images.MoveLeftButtonIcon,
                disabled = (colorEditPromise or (not selectedKeypoint) or (selectedKeypoint == 1)),

                onActivated = function()
                    local thisKeypoint = keypoints[selectedKeypoint]
                    local prevKeypoint = keypoints[selectedKeypoint - 1]

                    keypoints[selectedKeypoint] = { Time = thisKeypoint.Time, Color = prevKeypoint.Color }
                    keypoints[selectedKeypoint - 1] = { Time = prevKeypoint.Time, Color = thisKeypoint.Color }

                    self.props.setKeypoints(keypoints, selectedKeypoint - 1)
                end,
            }),

            -- keypoint must be selected
            -- t ~= 1
            SwapKeypointRightButton = Roact.createElement(Button, {
                LayoutOrder = 3,

                displayType = "image",
                image = Style.Images.MoveRightButtonIcon,
                disabled = (colorEditPromise or (not selectedKeypoint) or (selectedKeypoint == #keypoints)),

                onActivated = function()
                    local thisKeypoint = keypoints[selectedKeypoint]
                    local nextKeypoint = keypoints[selectedKeypoint + 1]

                    keypoints[selectedKeypoint] = { Time = thisKeypoint.Time, Color = nextKeypoint.Color }
                    keypoints[selectedKeypoint + 1] = { Time = nextKeypoint.Time, Color = thisKeypoint.Color }

                    self.props.setKeypoints(keypoints, selectedKeypoint + 1)
                end,
            }),

            ReverseSequenceButton = Roact.createElement(Button, {
                LayoutOrder = 5,

                displayType = "image",
                image = Style.Images.ReverseGradientButtonIcon,
                disabled = if colorEditPromise then true else false,

                onActivated = function()
                    local reversedKeypoints = {}
                    local reversedSelectedKeypoint

                    for i = #keypoints, 1, -1 do
                        local keypoint = keypoints[i]
                        local reversedIndex = #reversedKeypoints + 1

                        if (selectedKeypoint == i) then
                            reversedSelectedKeypoint = reversedIndex
                        end

                        reversedKeypoints[reversedIndex] = { Time = 1 - keypoint.Time, Color = keypoint.Color }
                    end

                    self.props.setKeypoints(reversedKeypoints, reversedSelectedKeypoint)
                end,
            }),

            SnapContainer = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, -30),
                Size = UDim2.new(0, 94, 0, 22),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = 6,
            }, {
                SnapLabel = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.new(0, 26, 1, 0),
    
                    Text = uiTranslations["SnapInput_Label"],
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextYAlignment = Enum.TextYAlignment.Center,
                }),
    
                SnapInput = Roact.createElement(TextInput, {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 30, 0.5, 0),
                    Size = UDim2.new(0, 50, 1, 0),
                    
                    Text = timeSnapValue * 100,
                    TextXAlignment = Enum.TextXAlignment.Center,
    
                    isTextAValidValue = function(text)
                        local n = tonumber(text)
                        if (not n) then return false end

                        n = n / 100
                        return ((n >= Constants.MIN_SNAP_VALUE) and (n <= Constants.MAX_SNAP_VALUE))
                    end,
    
                    onSubmit = function(text)
                        local n = tonumber(text)
                        n = math.clamp(n / 100, Constants.MIN_SNAP_VALUE, Constants.MAX_SNAP_VALUE)
                        n = Util.round(n, math.log10(Constants.MIN_SNAP_VALUE))

                        self.props.setSnapValue(n)
                    end,
                }),
    
                SnapUnitLabel = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 84, 0.5, 0),
                    Size = UDim2.new(0, 10, 1, 0),

                    Text = "%",
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextYAlignment = Enum.TextYAlignment.Center,
                }),
            }),
        }),

        MainActions = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            
            Size = UDim2.new(
                0, (Style.Constants.StandardButtonHeight + (Style.Constants.DialogButtonWidth * 3) + (Style.Constants.SpaciousElementPadding * 3)),
                0, Style.Constants.StandardButtonHeight),
        }, {
            UIListLayout = Roact.createElement(StandardUIListLayout, {
                Padding = UDim.new(0, Style.Constants.SpaciousElementPadding),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            }),

            --[[
            PalettesButton = Roact.createElement(Button, {
                LayoutOrder = 1,

                displayType = "image",
                image = Style.Images.PaletteEditorButtonIcon,

                onActivated = function()
                    if (self.gradientPaletteWindow:isMounted()) then
                        self.gradientPaletteWindow:unmount()
                    else
                        self.gradientPaletteWindow:mount(
                            uiTranslations["GradientPalette_WindowTitle"],

                            Roact.createElement(GradientPalette, {
                                beforeSetGradient = function()
                                    if (self.state.colorEditPromise) then
                                        self.state.colorEditPromise:cancel()
                                    end
            
                                    self.props.setKeypoints(nil, -1)
            
                                    self:setState({
                                        colorEditPromise = Roact.None,
                                    })
                                end,
                            }),

                            Store
                        )
                    end
                end
            }),
            --]]

            ResetButton = Roact.createElement(Button, {
                Size = UDim2.new(0, Style.Constants.DialogButtonWidth, 0, Style.Constants.StandardButtonHeight),
                LayoutOrder = 2,

                displayType = "text",
                text = uiTranslations["Reset_ButtonText"],

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton, Enum.StudioStyleGuideModifier.Hover),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonText),

                onActivated = function()
                    if (colorEditPromise) then
                        colorEditPromise:cancel()
                    end

                    self.props.setKeypoints(nil, -1)
                    self.props.setGradient(self.props.originalKeypoints, self.props.originalColorSpace, self.props.originalHueAdjustment, self.props.originalPrecision)

                    self:setState({
                        colorEditPromise = Roact.None,
                        tracking = false,
                    })
                end
            }),

            CancelButton = Roact.createElement(Button, {
                Size = UDim2.new(0, Style.Constants.DialogButtonWidth, 0, Style.Constants.StandardButtonHeight),
                LayoutOrder = 3,

                displayType = "text",
                text = "Cancel",

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton, Enum.StudioStyleGuideModifier.Hover),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonText),

                onActivated = function()
                    self.props.fireFinished(false)
                end
            }),

            ConfirmButton = Roact.createElement(Button, {
                Size = UDim2.new(0, Style.Constants.DialogButtonWidth, 0, Style.Constants.StandardButtonHeight),
                LayoutOrder = 4,

                displayType = "text",
                text = "OK",

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton, Enum.StudioStyleGuideModifier.Hover),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText),

                onActivated = function()
                    self.props.fireFinished(true)
                end
            }),
        })
        or nil
    })
end

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,

        keypoints = state.gradientEditor.keypoints,
        displayKeypoints = state.gradientEditor.displayKeypoints,
        selectedKeypoint = state.gradientEditor.selectedKeypoint,

        colorSpace = state.gradientEditor.colorSpace,
        hueAdjustment = state.gradientEditor.hueAdjustment,
        precision = state.gradientEditor.precision,
        timeSnapValue = state.userData[CommonEnums.UserDataKey.SnapValue],
    }
end, function(dispatch)
    return {
        setKeypoints = function(keypoints, selectedKeypoint)
            dispatch({
                type = Enums.StoreActionType.GradientEditor_SetKeypoints,

                keypoints = keypoints,
                selectedKeypoint = selectedKeypoint,
            })
        end,

        setGradient = function(keypoints, colorSpace, hueAdjustment, precision)
            dispatch({
                type = Enums.StoreActionType.GradientEditor_SetGradient,

                keypoints = keypoints,
                colorSpace = colorSpace,
                hueAdjustment = hueAdjustment,
                precision = precision,
            })
        end,

        setSnapValue = function(snapValue)
            dispatch({
                type = Enums.StoreActionType.UpdateUserData,
                key = CommonEnums.UserDataKey.SnapValue,
                value = snapValue
            })
        end,

        resetState = function()
            dispatch({
                type = Enums.StoreActionType.GradientEditor_ResetState,
            })
        end,
    }
end)(GradientEditor)