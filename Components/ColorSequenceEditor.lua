local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Color = require(PluginModules:FindFirstChild("Color"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local Style = require(PluginModules:FindFirstChild("Style"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local Padding = require(Components:FindFirstChild("Padding"))
local TextInput = require(Components:FindFirstChild("TextInput"))

---

local MAX_COLORSEQUENCE_KEYPOINTS = 20

local CURSOR_KEYPOINT_SNAP_VALUE = 1/100
local MIN_SNAP_VALUE = 0.001/100
local MAX_SNAP_VALUE= 25/100

local noYield = Util.noYield

local round = function(n, power)
    local place = 10 ^ power

    return math.floor(n / place + 0.5) * place
end

-- From the DevHub: https://developer.roblox.com/en-us/api-reference/datatype/ColorSequence
local evalutateColorSequence = function(sequence, time)
    if (time == 0) then return sequence.Keypoints[1].Value end
    if (time == 1) then return sequence.Keypoints[#sequence.Keypoints].Value end

    for i = 1, (#sequence.Keypoints - 1) do
        local thisKeypoint, nextKeypoint = sequence.Keypoints[i], sequence.Keypoints[i + 1]
        local thisKeypointTime, nextKeypointTime = thisKeypoint.Time, nextKeypoint.Time
        
        if ((time >= thisKeypointTime) and (time < nextKeypointTime)) then
            local alpha = (time - thisKeypointTime) / (nextKeypointTime - thisKeypointTime)

            return thisKeypoint.Value:Lerp(nextKeypoint.Value, alpha)
        end
    end
end

local getNearestKeypointIndex = function(sequence, time)
    if (time == 0) then return 1, 0 end
    if (time == 1) then return #sequence.Keypoints, 0 end

    for i = 1, (#sequence.Keypoints - 1) do
        local thisKeypoint, nextKeypoint = sequence.Keypoints[i], sequence.Keypoints[i + 1]
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
end

---

local ColorSequenceEditor = Roact.PureComponent:extend("ColorSequenceEditor")

ColorSequenceEditor.init = function(self, initProps)
    self.timelineStartPosition, self.updateTimelineStartPosition = Roact.createBinding(Vector2.new(0, 0))
    self.timelineWidth, self.updateTimelineWidth = Roact.createBinding(0)
    self.timelineProgress, self.updateTimelineProgress = Roact.createBinding(0)

    self.markerTime = self.timelineProgress:map(function(timelineProgress)
        local colorSequence = self.state.colorSequence
        local keypoints = colorSequence.Keypoints

        local nearestKeypoint, nearestKeypointTimeDiff = getNearestKeypointIndex(colorSequence, timelineProgress)
        local isKeypointInSnapProximity = (nearestKeypointTimeDiff < CURSOR_KEYPOINT_SNAP_VALUE)

        return (isKeypointInSnapProximity and keypoints[nearestKeypoint].Time or timelineProgress)
    end)

    self.updateSelectedKeypointTime = function(cursorPosition)
        local colorSequence = self.state.colorSequence
        local keypoints = colorSequence.Keypoints
        local selectedKeypoint = keypoints[self.state.selectedKeypoint]
        
        if ((selectedKeypoint.Time == 0) or (selectedKeypoint.Time == 1)) then
            return
        end

        local distanceFromStart = cursorPosition - self.timelineStartPosition:getValue()
        local progress = math.clamp(distanceFromStart.X / self.timelineWidth:getValue(), 0, 1)
        progress = round(progress, math.log10(self.props.timeSnapValue))

        local nearestKeypoint, nearestKeypointTimeDiff = getNearestKeypointIndex(colorSequence, progress)

        if (nearestKeypointTimeDiff < MIN_SNAP_VALUE) then
            if (nearestKeypoint == 1) then
                progress = MIN_SNAP_VALUE
            elseif (nearestKeypoint == #keypoints) then
                progress =  1 - MIN_SNAP_VALUE
            end
        end

        local newKeypoint = ColorSequenceKeypoint.new(progress, selectedKeypoint.Value)
        keypoints[self.state.selectedKeypoint] = newKeypoint

        table.sort(keypoints, function(keypointA, keypointB)
            return keypointA.Time < keypointB.Time
        end)

        local newKeypointIndex = table.find(keypoints, newKeypoint)

        self:setState({
            colorSequence = ColorSequence.new(keypoints),
            selectedKeypoint = newKeypointIndex
        })
    end

    self.calculateTimelineProgress = function(cursorPosition)
        local distanceFromStart = cursorPosition - self.timelineStartPosition:getValue()

        self.updateTimelineProgress(math.clamp(distanceFromStart.X / self.timelineWidth:getValue(), 0, 1))
    end

    self:setState({
        colorSequence = initProps.originalColor,
        tracking = false,
        showTimelineMarker = false,
    })
end

ColorSequenceEditor.didMount = function(self)
    
end

ColorSequenceEditor.willUnmount = function(self)
    
end

ColorSequenceEditor.didUpdate = function(self, _, prevState)
    if (self.state.colorSequence == prevState.colorSequence) then return end

    if (self.props.onValueChanged) then
        noYield(self.props.onValueChanged, self.state.colorSequence)
    end
end

ColorSequenceEditor.willUnmount = function(self)
    if (self.state.colorEditPromise) then
        self.state.colorEditPromise:cancel()
    end
end

ColorSequenceEditor.render = function(self)
    local theme = self.props.theme
    local timeSnapValue = self.props.timeSnapValue
    
    local selectedKeypoint = self.state.selectedKeypoint
    local colorEditPromise = self.state.colorEditPromise

    local colorSequence = self.state.colorSequence
    local keypoints = colorSequence.Keypoints

    local gradientElements = {}

    local removeKeypoint = function(index)
        table.remove(keypoints, index)

        self:setState({
            colorSequence = ColorSequence.new(keypoints),
            selectedKeypoint = (selectedKeypoint == index) and Roact.None or nil,
        })
    end

    for i = 1, #keypoints do
        local keypoint = keypoints[i]
        local isFixed = (i == 1) or (i == #keypoints)

        table.insert(gradientElements, Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(keypoint.Time, 0, 0.5, 0),
            Size = UDim2.new(0, Style.MarkerSize, 0, Style.MarkerSize),
            BorderSizePixel = 0,
            ZIndex = 2,

            BackgroundColor3 = Color.toColor3(Color.getBestContrastingColor(
                Color.fromColor3(keypoint.Value),
                Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
            )),
        }, {
            UICorner = (not isFixed) and
                Roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 4)
                })
            or nil,

            Inner = (selectedKeypoint == i) and
                Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(1, -2, 1, -2),
                    BorderSizePixel = 0,
                    
                    BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder, Enum.StudioStyleGuideModifier.Selected),
                }, {
                    UICorner = (not isFixed) and
                        Roact.createElement("UICorner", {
                            CornerRadius = UDim.new(0, 4)
                        })
                    or nil,
                })
            or nil
        }))
    end

    gradientElements["Marker"] = (self.state.showTimelineMarker or self.state.tracking) and
        Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 1, 1, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            Position = self.markerTime:map(function(markerTime)
                return UDim2.new(markerTime, 0, 0.5, 0)
            end),

            BackgroundColor3 = self.markerTime:map(function(markerTime)
                return Color.toColor3(Color.getBestContrastingColor(
                    Color.fromColor3(evalutateColorSequence(colorSequence, markerTime)),
                    Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                    Color.invert(Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)))
                ))
            end),
        })
    or nil

    gradientElements["UICorner"] = Roact.createElement("UICorner", {
        CornerRadius = UDim.new(0, 4)
    })

    gradientElements["UIGradient"] = Roact.createElement("UIGradient", {
        Color = colorSequence
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

            self:setState({
                selectedKeypoint = nextSelected,
                tracking = false,
            })
        end,

        [Roact.Event.InputChanged] = function(_, input)
            if (input.UserInputType ~= Enum.UserInputType.MouseMovement) then return end
            
            local inputPosition = input.Position
            local cursorPosition = Vector2.new(inputPosition.X, inputPosition.Y)
            
            if (self.state.tracking and self.state.selectedKeypoint) then
                self.updateSelectedKeypointTime(cursorPosition)
            end

            self.calculateTimelineProgress(cursorPosition)
        end,
    }, {
        UIPadding = Roact.createElement(Padding, {Style.PagePadding}),

        SequenceEditor = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, -60),
            BackgroundTransparency = 1,
        }, {
            SequenceGradientContainer = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 0,

                BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
            }, {
                UICorner = Roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 4)
                }),

                SequenceGradient = Roact.createElement("Frame", {
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
                            local nearestKeypoint, nearestKeypointTimeDiff = getNearestKeypointIndex(colorSequence, timelineProgress)
                            local isKeypointInSnapProximity = (nearestKeypointTimeDiff < CURSOR_KEYPOINT_SNAP_VALUE)

                            if (input.UserInputType == Enum.UserInputType.MouseButton1) then
                                if (isKeypointInSnapProximity) then
                                    self:setState({
                                        selectedKeypoint = nearestKeypoint,
                                        tracking = true,
                                    })
                                else
                                    if (#keypoints < MAX_COLORSEQUENCE_KEYPOINTS) then
                                        local newKeypointTime = round(timelineProgress, math.log10(timeSnapValue))

                                        local newKeypoint = ColorSequenceKeypoint.new(newKeypointTime, evalutateColorSequence(colorSequence, newKeypointTime))
                                        table.insert(keypoints, newKeypoint)

                                        table.sort(keypoints, function(keypointA, keypointB)
                                            return keypointA.Time < keypointB.Time
                                        end)

                                        local newKeypointIndex = table.find(keypoints, newKeypoint)

                                        self:setState({
                                            colorSequence = ColorSequence.new(keypoints),
                                            selectedKeypoint = newKeypointIndex,
                                            tracking = true,
                                        })
                                    end
                                end
                            elseif (input.UserInputType == Enum.UserInputType.MouseButton2) then
                                if (not isKeypointInSnapProximity) then return end
                                if ((nearestKeypoint == 1) or (nearestKeypoint == #keypoints)) then return end

                                removeKeypoint(nearestKeypoint)
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
            }),
        }),

        SelectedKeypointInfo = selectedKeypoint and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, -(Style.StandardButtonSize + Style.SpaciousElementPadding)),
                Size = UDim2.new(0.5, 0, 0, Style.StandardButtonSize),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                ColorLabel = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.new(0, 28, 1, 0),
                    BackgroundTransparency = 1,

                    Font = Style.StandardFont,
                    TextSize = Style.StandardTextSize,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    Text = "Color",

                    TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
                }),

                EditColor = Roact.createElement(Button, {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0, 50, 1, 0),
                    Position = UDim2.new(0, 28 + Style.MinorElementPadding, 0.5, 0),

                    displayType = "color",
                    color = evalutateColorSequence(colorSequence, keypoints[selectedKeypoint].Time),
                    disabled = (colorEditPromise and true or false),

                    onActivated = function()
                        if (colorEditPromise) then
                            colorEditPromise:cancel()
                        end

                        local originalColor = keypoints[selectedKeypoint].Value

                        local editPromise = self.props.promptForColorEdit({
                            PromptTitle = string.format("ColorSequenceKeypoint, %.3f%%", keypoints[selectedKeypoint].Time * 100),
                            InitialColor = originalColor,

                            OnColorChanged = function(color)
                                local keypoint = keypoints[selectedKeypoint]
                                keypoints[selectedKeypoint] = ColorSequenceKeypoint.new(keypoint.Time, color)

                                self:setState({
                                    colorSequence = ColorSequence.new(keypoints)
                                })
                            end,
                        })

                        editPromise:andThen(function(newColor)
                            local keypoint = keypoints[selectedKeypoint]
                            keypoints[selectedKeypoint] = ColorSequenceKeypoint.new(keypoint.Time, newColor)

                            self:setState({
                                colorSequence = ColorSequence.new(keypoints),
                            })
                        end)
                        
                        editPromise:finally(function(status)
                            local isCancelled = (tostring(status) == "Cancelled")

                            if (isCancelled) then
                                local keypoint = keypoints[self.state.selectedKeypoint]
                                keypoints[self.state.selectedKeypoint] = ColorSequenceKeypoint.new(keypoint.Time, originalColor)
                            end

                            self:setState({
                                colorSequence = isCancelled and ColorSequence.new(keypoints) or nil,
                                colorEditPromise = Roact.None,
                            })
                        end)

                        self:setState({
                            colorEditPromise = editPromise,
                        })
                    end
                }),

                ProgressInput = Roact.createElement(TextInput, {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 28 + 50 + Style.MinorElementPadding + Style.SpaciousElementPadding, 0.5, 0),
                    Size = UDim2.new(0, 50, 1, 0),
                    Text = string.format("%.3f", keypoints[selectedKeypoint].Time * 100),
                    TextXAlignment = Enum.TextXAlignment.Center,
    
                    canClear = false,
                    disabled = (colorEditPromise and true or false),
    
                    isTextAValidValue = function(text)
                        local n = tonumber(text)
                        if (not n) then return false end

                        n = n / 100
                        return ((n >= MIN_SNAP_VALUE) and (n <= (1 - MIN_SNAP_VALUE)))
                    end,
    
                    onTextChanged = function(text)
                        local n = tonumber(text)
                        n = round(n / 100, math.log10(MIN_SNAP_VALUE))

                        local newKeypoint = ColorSequenceKeypoint.new(n, keypoints[selectedKeypoint].Value)
                        keypoints[selectedKeypoint] = newKeypoint

                        table.sort(keypoints, function(keypointA, keypointB)
                            return keypointA.Time < keypointB.Time
                        end)

                        local newKeypointIndex = table.find(keypoints, newKeypoint)

                        self:setState({
                            colorSequence = ColorSequence.new(keypoints),
                            selectedKeypoint = newKeypointIndex
                        })
                    end,
                }),

                ProgressLabel = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 28 + 50 + 50 + (Style.MinorElementPadding * 2) + Style.SpaciousElementPadding, 0.5, 0),
                    Size = UDim2.new(0, 10, 1, 0),
                    BackgroundTransparency = 1,

                    Font = Style.StandardFont,
                    TextSize = Style.StandardTextSize,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    Text = "%",

                    TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
                }),
            })
        or nil,

        KeypointCount = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, 0, 1, -(Style.StandardButtonSize + Style.SpaciousElementPadding)),
            Size = UDim2.new(0, 82, 0, Style.StandardTextSize),
            BackgroundTransparency = 1,

            Font = Style.StandardFont,
            TextSize = Style.StandardTextSize,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextYAlignment = Enum.TextYAlignment.Center,
            Text = #keypoints .. "/" .. MAX_COLORSEQUENCE_KEYPOINTS .. " Keypoints",

            TextColor3 = theme:GetColor((#keypoints == MAX_COLORSEQUENCE_KEYPOINTS) and Enum.StudioStyleGuideColor.WarningText or Enum.StudioStyleGuideColor.MainText)
        }),

        EditorActions = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(0, 274, 0, Style.StandardButtonSize),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            UIListLayout = Roact.createElement("UIListLayout", {
                Padding = UDim.new(0, 8),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            }),

            -- keypoint must be selected
            -- t ~= 0, 1
            RemoveKeypointButton = Roact.createElement(Button, {
                LayoutOrder = 1,

                displayType = "image",
                image = Style.RemoveImage,
                disabled = (colorEditPromise or (not selectedKeypoint) or (selectedKeypoint == 1) or (selectedKeypoint == #keypoints)),

                onActivated = function()
                    if (self.state.colorEditPromise) then
                        self.state.colorEditPromise:cancel()
                    end

                    removeKeypoint(selectedKeypoint)
                end,
            }),

            -- keypoint must be selected
            -- t ~= 0
            SwapKeypointLeftButton = Roact.createElement(Button, {
                LayoutOrder = 2,

                displayType = "image",
                image = Style.CSEditorSwapKeypointLeftImage,
                disabled = (colorEditPromise or (not selectedKeypoint) or (selectedKeypoint == 1)),

                onActivated = function()
                    local thisKeypoint = keypoints[selectedKeypoint]
                    local prevKeypoint = keypoints[selectedKeypoint - 1]

                    keypoints[selectedKeypoint] = ColorSequenceKeypoint.new(thisKeypoint.Time, prevKeypoint.Value)
                    keypoints[selectedKeypoint - 1] = ColorSequenceKeypoint.new(prevKeypoint.Time, thisKeypoint.Value)

                    self:setState({
                        colorSequence = ColorSequence.new(keypoints),
                        selectedKeypoint = selectedKeypoint - 1
                    })
                end,
            }),

            -- keypoint must be selected
            -- t ~= 1
            SwapKeypointRightButton = Roact.createElement(Button, {
                LayoutOrder = 3,

                displayType = "image",
                image = Style.CSEditorSwapKeypointRightImage,
                disabled = (colorEditPromise or (not selectedKeypoint) or (selectedKeypoint == #colorSequence.Keypoints)),

                onActivated = function()
                    local thisKeypoint = keypoints[selectedKeypoint]
                    local nextKeypoint = keypoints[selectedKeypoint + 1]

                    keypoints[selectedKeypoint] = ColorSequenceKeypoint.new(thisKeypoint.Time, nextKeypoint.Value)
                    keypoints[selectedKeypoint + 1] = ColorSequenceKeypoint.new(nextKeypoint.Time, thisKeypoint.Value)

                    self:setState({
                        colorSequence = ColorSequence.new(keypoints),
                        selectedKeypoint = selectedKeypoint + 1
                    })
                end,
            }),

            ReverseSequenceButton = Roact.createElement(Button, {
                LayoutOrder = 5,

                displayType = "image",
                image = Style.CSEditorReverseSequenceImage,
                disabled = (colorEditPromise and true or false),

                onActivated = function()
                    local reversedKeypoints = {}
                    local reversedSelectedKeypoint

                    for i = #keypoints, 1, -1 do
                        local keypoint = keypoints[i]
                        local reversedIndex = #reversedKeypoints + 1

                        if (selectedKeypoint == i) then
                            reversedSelectedKeypoint = reversedIndex
                        end

                        reversedKeypoints[reversedIndex] = ColorSequenceKeypoint.new(1 - keypoint.Time, keypoint.Value)
                    end

                    self:setState({
                        colorSequence = ColorSequence.new(reversedKeypoints),
                        selectedKeypoint = reversedSelectedKeypoint
                    })
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
                SnapLabel = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.new(0, 26, 1, 0),
                    BackgroundTransparency = 1,
    
                    Font = Style.StandardFont,
                    TextSize = Style.StandardTextSize,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    Text = "Snap",
    
                    TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
                }),
    
                SnapInput = Roact.createElement(TextInput, {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 30, 0.5, 0),
                    Size = UDim2.new(0, 50, 1, 0),
                    Text = timeSnapValue * 100,
                    TextXAlignment = Enum.TextXAlignment.Center,
    
                    canClear = false,
    
                    isTextAValidValue = function(text)
                        local n = tonumber(text)
                        if (not n) then return false end

                        n = n / 100
                        return ((n >= MIN_SNAP_VALUE) and (n <= MAX_SNAP_VALUE))
                    end,
    
                    onTextChanged = function(text)
                        local n = tonumber(text)
                        n = math.clamp(n / 100, MIN_SNAP_VALUE, MAX_SNAP_VALUE)
                        n = round(n, math.log10(MIN_SNAP_VALUE))

                        self.props.setSnapValue(n)
                    end,
                }),
    
                SnapUnitLabel = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 84, 0.5, 0),
                    Size = UDim2.new(0, 10, 1, 0),
                    BackgroundTransparency = 1,
    
                    Font = Style.StandardFont,
                    TextSize = Style.StandardTextSize,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    Text = "%",
    
                    TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
                }),
            }),
        }),

        MainActions = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, 0, 1, 0),
            Size = UDim2.new(0, 226, 0, Style.StandardButtonSize),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            UIListLayout = Roact.createElement("UIListLayout", {
                Padding = UDim.new(0, 8),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            }),

            ResetButton = Roact.createElement(Button, {
                Size = UDim2.new(0, Style.DialogButtonWidth, 0, Style.StandardButtonSize),
                LayoutOrder = 0,

                displayType = "text",
                text = "Reset",
                disabled = (colorSequence == self.props.originalColor),

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton, Enum.StudioStyleGuideModifier.Hover),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonText),

                onActivated = function()
                    if (colorEditPromise) then
                        colorEditPromise:cancel()
                    end

                    self:setState({
                        colorSequence = self.props.originalColor,
                        selectedKeypoint = Roact.None,
                        colorEditPromise = Roact.None,
                    })
                end
            }),

            CancelButton = Roact.createElement(Button, {
                Size = UDim2.new(0, Style.DialogButtonWidth, 0, Style.StandardButtonSize),
                LayoutOrder = 1,

                displayType = "text",
                text = "Cancel",

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton, Enum.StudioStyleGuideModifier.Hover),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonText),

                onActivated = function()
                    self.props.finishedEvent:Fire(false)
                end
            }),

            ConfirmButton = Roact.createElement(Button, {
                Size = UDim2.new(0, Style.DialogButtonWidth, 0, Style.StandardButtonSize),
                LayoutOrder = 2,

                displayType = "text",
                text = "OK",

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton, Enum.StudioStyleGuideModifier.Hover),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText),

                onActivated = function()
                    self.props.finishedEvent:Fire(true, self.state.colorSequence)
                end
            }),
        })
        or nil
    })
end

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,
        timeSnapValue = state.colorSequenceEditor.snap,
    }
end, function(dispatch)
    return {
        setSnapValue = function(snapValue)
            dispatch({
                type = PluginEnums.StoreActionType.ColorSequenceEditor_SetSnapValue,
                snap = snapValue
            })
        end,
    }
end)(ColorSequenceEditor)