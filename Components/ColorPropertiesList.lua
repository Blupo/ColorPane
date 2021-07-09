local TextService = game:GetService("TextService")

---

local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local ColorPane = require(PluginModules:FindFirstChild("APIBroker"))
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local PluginSettings = require(PluginModules:FindFirstChild("PluginSettings"))
local SelectionManager = require(PluginModules:FindFirstChild("SelectionManager"))
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local ConnectTheme = require(Components:FindFirstChild("ConnectTheme"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardScrollingFrame = StandardComponents.ScrollingFrame
local StandardTextLabel = StandardComponents.TextLabel
local StandardUICorner = StandardComponents.UICorner
local StandardUIListLayout = StandardComponents.UIListLayout
local StandardUIPadding = StandardComponents.UIPadding

---

local LIST_ITEM_LEFT_PADDING = 24

local getCellTextSizes = function(propName, displayClassName, showClassName)
    local propNameTextSize = TextService:GetTextSize(propName, Style.StandardTextSize, Style.StandardFont, Vector2.new(math.huge, math.huge))
    local classNameTextSize = showClassName and TextService:GetTextSize(displayClassName, Style.StandardTextSize, Style.StandardFont, Vector2.new(math.huge, math.huge)) or Vector2.new()

    return propNameTextSize, classNameTextSize
end

local toColor3 = function(color, colorType)
    if (colorType == "BrickColor") then
        return color.Color
    elseif (colorType == "Vector3") then
        return Color3.new(color.X, color.Y, color.Z)
    else
        return color
    end
end

local fromColor3 = function(color, colorType)
    if (colorType == "BrickColor") then
        return BrickColor.new(color)
    elseif (colorType == "Vector3") then
        return Vector3.new(color.R, color.G, color.B)
    else
        return color
    end
end

---

--[[
    props

        AnchorPoint?
        Size?
        Position?

        propName: string
        className: string
        showClassName: boolean?

        selected: boolean?
        disabled: boolean?

        colorType: "Color3" | "ColorSequence"
        color: Binding(Color3 | ColorSequence | nil)

        promptEdit: () -> nil
]]

local PropertyListItem = Roact.PureComponent:extend("PropertyListItem")

PropertyListItem.render = function(self)
    local theme = self.props.theme
    local color = self.props.color

    local isColorSequence = (self.props.colorType == "ColorSequence")
    local isSelected, isDisabled = self.props.selected, self.props.disabled
    local displayClassName = "(" .. self.props.className .. ")"
    local propNameTextSize, classNameTextSize = getCellTextSizes(self.props.propName, displayClassName, self.props.showClassName)

    local propertyLabelTextColor

    if (isSelected) then
        propertyLabelTextColor = theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Selected)
    else
        propertyLabelTextColor = theme:GetColor(
            Enum.StudioStyleGuideColor.MainText,
            isDisabled and Enum.StudioStyleGuideModifier.Disabled or nil
        )
    end

    return Roact.createElement("TextButton", {
        AnchorPoint = self.props.AnchorPoint,
        Size = self.props.Size,
        Position = self.props.Position,
        LayoutOrder = self.props.LayoutOrder,
        AutoButtonColor = false,
        BorderSizePixel = 1,
        BorderMode = Enum.BorderMode.Outline,

        Text = "",
        TextTransparency = 1,

        BackgroundColor3 = isSelected and
            theme:GetColor(Enum.StudioStyleGuideColor.TableItem, Enum.StudioStyleGuideModifier.Selected)
        or theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),

        BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),

        [Roact.Event.MouseEnter] = function(obj)
            if (isSelected or isDisabled) then return end

            obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.TableItem, Enum.StudioStyleGuideModifier.Hover)
        end,

        [Roact.Event.MouseLeave] = function(obj)
            if (isSelected or isDisabled) then return end

            obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
        end,

        [Roact.Event.Activated] = function()
            if (isSelected or isDisabled) then return end

            self.props.promptEdit()
        end,
    }, {
        UIPadding = Roact.createElement(StandardUIPadding, { Style.MinorElementPadding, Style.MinorElementPadding, LIST_ITEM_LEFT_PADDING, Style.MinorElementPadding }),

        PropertyNameLabel = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0, propNameTextSize.X, 1, 0),
            Position = UDim2.new(0, 0, 0.5, 0),
            Text = self.props.propName,

            TextColor3 = propertyLabelTextColor,
        }),

        ClassNameLabel = self.props.showClassName and
            Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, classNameTextSize.X, 1, 0),
                Position = UDim2.new(0, propNameTextSize.X + Style.MinorElementPadding, 0.5, 0),
                Text = displayClassName,

                TextColor3 = theme:GetColor(
                    Enum.StudioStyleGuideColor.MainText,
                    (not isSelected) and Enum.StudioStyleGuideModifier.Disabled or Enum.StudioStyleGuideModifier.Selected
                ),
            })
        or nil,

        ColorButtonContainer = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, Style.ColorSequencePreviewWidth, 1, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
        
            BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border)
        }, {
            UICorner = Roact.createElement(StandardUICorner),

            ColorButton = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundTransparency = 0,

                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,

                Text = color:map(function(value)
                    return (not value) and "(Multiple)" or "" 
                end),

                BackgroundColor3 = color:map(function(value)
                    local colorValue = isColorSequence and Color3.new(1, 1, 1) or value

                    return colorValue or theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
                end),
            }, {
                UICorner = Roact.createElement(StandardUICorner),

                UIGradient = isColorSequence and
                    Roact.createElement("UIGradient", {
                        Color = color:map(function(value)
                            return value or ColorSequence.new(Color3.new(1, 1, 1))
                        end)
                    })
                or nil,
            })
        })
    })
end

---

--[[
    props

        AnchorPoint?
        Size?
        Position?

]]

local ColorPropertiesList = Roact.PureComponent:extend("ColorPropertiesList")

ColorPropertiesList.init = function(self)
    self.selectionPropertyValues, self.updateSelectionPropertyValues = Roact.createBinding({})
    self.listLength, self.updateListLength = Roact.createBinding(0)

    self.selectionChanged = SelectionManager.SelectionChanged:Connect(function()
        if (self.state.editColorPromise) then
            self.state.editColorPromise:cancel()
        end        

        self:setState({
            properties = SelectionManager.GetColorProperties()
        })
    end)

    self.selectionColorsChanged = SelectionManager.SelectionColorsChanged:Connect(function()
        if (self.state.editColorPromise) then return end

        self.updateSelectionPropertyValues(SelectionManager.GetCommonColorPropertyValues())
    end)

    self.settingChanged = PluginSettings.SettingChanged:Connect(function(key, newValue)
        if (key ~= PluginEnums.PluginSettingKey.ColorPropertiesLivePreview) then return end

        self:setState({
            livePreview = newValue
        })
    end)

    SelectionManager.Connect()
    SelectionManager.RegenerateCommonColorPropertyValues()
    self.updateSelectionPropertyValues(SelectionManager.GetCommonColorPropertyValues())

    self:setState({
        properties = SelectionManager.GetColorProperties(),
        livePreview = PluginSettings.Get(PluginEnums.PluginSettingKey.ColorPropertiesLivePreview)
    })
end

ColorPropertiesList.willUnmount = function(self)
    if (self.state.editColorPromise) then
        self.state.editColorPromise:cancel()
    end

    self.selectionChanged:Disconnect()
    self.selectionColorsChanged:Disconnect()
    self.settingChanged:Disconnect()

    SelectionManager.Disconnect()
end

ColorPropertiesList.render = function(self)
    local listElements = {}
    local minCellWidth = 0

    local properties = self.state.properties
    local propertiesArray = {}
    local propertyNameCounts = {}

    for propertyData in pairs(properties) do
        local propertyName = propertyData.Name
        
        propertyNameCounts[propertyName] = (propertyNameCounts[propertyName] or 0) + 1
        table.insert(propertiesArray, propertyData)
    end

    for propertyData, propertyClassName in pairs(properties) do
        local propertyName = propertyData.Name
        local propNameTextSize, classNameTextSize = getCellTextSizes(propertyName, "(" .. propertyClassName .. ")", propertyNameCounts[propertyName] > 1)
        local cellWidth = LIST_ITEM_LEFT_PADDING + propNameTextSize.X + Style.MinorElementPadding +
            classNameTextSize.X + Style.MajorElementPadding + Style.ColorSequencePreviewWidth + Style.MinorElementPadding

        minCellWidth = (cellWidth > minCellWidth) and cellWidth or minCellWidth
    end

    table.sort(propertiesArray, function(a, b)
        return a.Name < b.Name
    end)

    for i = 1, #propertiesArray do
        local propertyData = propertiesArray[i]
        local propertyName = propertyData.Name
        local propertyClassName = properties[propertyData]

        local compositeName = propertyClassName .. "/" .. propertyName
        local valueType = propertyData.ValueType.Name
        local isColorSequence = (valueType == "ColorSequence")

        local editColorPromptOptions = {
            PromptTitle = propertyClassName .. "." .. propertyName,

            OnColorChanged = function(intermediateColor)
                if (not self.state.livePreview) then return end

                local transformedColor = isColorSequence and intermediateColor or fromColor3(intermediateColor, valueType)
                local newCommonColorValues = self.selectionPropertyValues:getValue()

                newCommonColorValues[propertyClassName][propertyName] = transformedColor
                self.updateSelectionPropertyValues(newCommonColorValues)
                SelectionManager.ApplyColorProperty(propertyClassName, propertyName, transformedColor, false)
            end
        }

        listElements[compositeName] = Roact.createElement(PropertyListItem, {
            Size = UDim2.new(1, 0, 0, Style.LargeButtonSize),
            LayoutOrder = i,

            propName = propertyName,
            className = propertyClassName,
            showClassName = propertyNameCounts[propertyName] > 1,

            selected = (self.state.editingProperty == compositeName),
            disabled = self.state.editColorPromise and (self.state.editingProperty ~= compositeName),

            colorType = isColorSequence and "ColorSequence" or "Color3",
            color = self.selectionPropertyValues:map(function(values)
                local color = values[propertyClassName] and values[propertyClassName][propertyName] or nil

                if (isColorSequence) then
                    return color
                else
                    return color and toColor3(color, valueType) or nil
                end
            end),

            promptEdit = function()
                if (ColorPane.IsColorEditorOpen()) then return end

                if (self.state.editColorPromise) then
                    self.state.editColorPromise:cancel()
                end

                local propertyValues = self.selectionPropertyValues:getValue()
                local initialColor = propertyValues[propertyClassName] and propertyValues[propertyClassName][propertyName] or nil

                if (isColorSequence) then
                    editColorPromptOptions.InitialColor = initialColor
                else
                    editColorPromptOptions.InitialColor = initialColor and toColor3(initialColor, valueType) or nil
                end

                local editColorPromise = isColorSequence and
                    ColorPane.PromptForColorSequence(editColorPromptOptions)
                or
                    ColorPane.PromptForColor(editColorPromptOptions)
                
                editColorPromise:andThen(function(newColor)
                    SelectionManager.ApplyColorProperty(propertyClassName, propertyName, 
                        isColorSequence and newColor or fromColor3(newColor, valueType),
                    true)
                end, function() end)
                :finally(function(status)
                    if (status == ColorPane.PromiseStatus.Cancelled) then
                        for obj, originalValues in pairs(self.state.originalPropertyValuesSnapshot) do
                            if (obj:IsA(propertyClassName)) then
                                SelectionManager.ApplyObjectColorProperty(obj, propertyClassName, propertyName, originalValues[propertyName])
                            end
                        end

                        SelectionManager.RegenerateCommonColorPropertyValues()
                        self.updateSelectionPropertyValues(SelectionManager.GetCommonColorPropertyValues())
                    end

                    SelectionManager.SetListeningForPropertyChanges(true)

                    self:setState({
                        editColorPromise = Roact.None,
                        editingProperty = Roact.None,
                        originalPropertyValuesSnapshot = Roact.None,
                    })
                end)

                SelectionManager.SetListeningForPropertyChanges(false)

                self:setState({
                    editColorPromise = editColorPromise,
                    editingProperty = compositeName,
                    originalPropertyValuesSnapshot = SelectionManager.GetColorPropertyValuesSnapshot(),
                })
            end,
        })
    end

    listElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateListLength(obj.AbsoluteContentSize.Y)
        end,

        preset = 1,
    })

    return (#propertiesArray > 0) and
        Roact.createElement(StandardScrollingFrame, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            
            CanvasSize = self.listLength:map(function(length)
                return UDim2.new(0, minCellWidth, 0, length)
            end),
        }, listElements)
    or
        Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 0,

            Text = "The selected item(s) do not have any color properties",
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextWrapped = true,
        }, {
            UIPadding = Roact.createElement(StandardUIPadding, {Style.PagePadding})
        })
end

PropertyListItem = ConnectTheme(PropertyListItem)
return ColorPropertiesList