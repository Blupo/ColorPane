local StudioService = game:GetService("StudioService")
local TextService = game:GetService("TextService")

---

local root = script.Parent.Parent

local PluginModules = root.PluginModules
local API = require(PluginModules.APIProvider)
local DocumentationPluginMenu = require(PluginModules.DocumentationPluginMenu)
local PluginEnums = require(PluginModules.PluginEnums)
local SelectionManager = require(PluginModules.SelectionManager)
local Style = require(PluginModules.Style)
local Translator = require(PluginModules.Translator)

local includes = root.includes
local Roact = require(includes.Roact)

local Components = root.Components
local ConnectTheme = require(Components.ConnectTheme)

local StandardComponents = require(Components.StandardComponents)
local StandardScrollingFrame = StandardComponents.ScrollingFrame
local StandardTextLabel = StandardComponents.TextLabel
local StandardUICorner = StandardComponents.UICorner
local StandardUIListLayout = StandardComponents.UIListLayout
local StandardUIPadding = StandardComponents.UIPadding

---

local LIST_ITEM_LEFT_PADDING = 24
local COLOR_TYPE_ICON_SIZE = 12

local partClassIconData = StudioService:GetClassIcon("Part")

local uiTranslations = Translator.GenerateTranslationTable({
    "NoSelectionColorProperties_Message",
    "SelectionColorMultipleValues_Indicator",
})

local getCellTextSizes = function(propName, displayClassName, showClassName)
    local propNameTextSize = TextService:GetTextSize(
        propName,
        Style.Constants.StandardTextSize,
        Style.Fonts.Standard,
        Vector2.new(math.huge, math.huge)
    )

    local classNameTextSize = showClassName and
        TextService:GetTextSize(
            displayClassName,
            Style.Constants.StandardTextSize,
            Style.Fonts.Standard,
            Vector2.new(math.huge, math.huge)
        )
    or Vector2.new()

    return propNameTextSize, classNameTextSize
end

---

--[[
    props

        AnchorPoint?
        Size?
        Position?
        LayoutOrder?

        className: string
        propertyName: string
        custom: boolean?

        colorType: "BrickColor" | "Color3" | "ColorSequence"
        color: Binding<Color | Gradient>
        
        showClassName: boolean?
        selected: boolean?
        disabled: boolean?

        promptForEdit: () -> nil

    store props

        theme: StudioTheme
]]

local ColorPropertyListItem = Roact.PureComponent:extend("ColorPropertyListItem")

ColorPropertyListItem.render = function(self)
    local theme = self.props.theme
    local color = self.props.color
    local colorType = self.props.colorType

    local className = self.props.className
    local propertyName = self.props.propertyName

    local isColorSequence = (colorType == "ColorSequence")
    local selected, disabled = self.props.selected, self.props.disabled
    local displayClassName = "(" .. className .. ")"
    local propertyNameTextSize, classNameTextSize = getCellTextSizes(propertyName, displayClassName, self.props.showClassName)
    
    local colorTypeImage
    local propertyLabelTextColor
    
    if (colorType == "BrickColor") then
        colorTypeImage = partClassIconData.Image
    elseif (colorType == "Color3") then
        colorTypeImage = Style.Images.HueWheel
    elseif (colorType == "ColorSequence") then
        colorTypeImage = Style.Images.ColorSequenceTypeIcon
    end

    if (selected) then
        propertyLabelTextColor = theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Selected)
    else
        propertyLabelTextColor = theme:GetColor(
            Enum.StudioStyleGuideColor.MainText,
            disabled and Enum.StudioStyleGuideModifier.Disabled or nil
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

        BackgroundColor3 = selected and
            theme:GetColor(Enum.StudioStyleGuideColor.TableItem, Enum.StudioStyleGuideModifier.Selected)
        or theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),

        BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),

        [Roact.Event.MouseEnter] = function(obj)
            if (selected or disabled) then return end

            obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.TableItem, Enum.StudioStyleGuideModifier.Hover)
        end,

        [Roact.Event.MouseLeave] = function(obj)
            if (selected or disabled) then return end

            obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
        end,

        [Roact.Event.MouseButton2Click] = function()
            if (self.props.custom) then return end

            local triggerConnection = DocumentationPluginMenu.Action.Triggered:Connect(function()
                DocumentationPluginMenu.ShowPropertyDocumentation(className, propertyName)
            end)

            DocumentationPluginMenu.Menu:ShowAsync()
            triggerConnection:Disconnect()
        end,

        [Roact.Event.Activated] = function()
            if (selected or disabled) then return end

            self.props.promptForEdit()
        end,
    }, {
        UIPadding = Roact.createElement(StandardUIPadding, {
            Style.Constants.MinorElementPadding,
            Style.Constants.MinorElementPadding,
            LIST_ITEM_LEFT_PADDING,
            Style.Constants.MinorElementPadding
        }),

        PropertyNameLabel = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0, propertyNameTextSize.X, 1, 0),
            Position = UDim2.new(0, 0, 0.5, 0),
            Text = self.props.propertyName,

            TextColor3 = propertyLabelTextColor,
        }),

        ClassNameLabel = self.props.showClassName and
            Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, classNameTextSize.X, 1, 0),
                Position = UDim2.new(0, propertyNameTextSize.X + Style.Constants.MinorElementPadding, 0.5, 0),
                Text = displayClassName,

                TextColor3 = theme:GetColor(
                    Enum.StudioStyleGuideColor.MainText,
                    (not selected) and Enum.StudioStyleGuideModifier.Disabled or Enum.StudioStyleGuideModifier.Selected
                ),
            })
        or nil,

        ColorTypeIndicator = Roact.createElement("ImageLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -(Style.Constants.ColorSequencePreviewWidth + Style.Constants.MinorElementPadding), 0.5, 0),
            Size = UDim2.new(0, COLOR_TYPE_ICON_SIZE, 0, COLOR_TYPE_ICON_SIZE),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Image = colorTypeImage,
            ImageRectOffset = (colorType == "BrickColor") and partClassIconData.ImageRectOffset or nil,
            ImageRectSize =  (colorType == "BrickColor") and partClassIconData.ImageRectSize or nil,

            ImageColor3 = disabled and Color3.new(1/2, 1/2, 1/2) or nil,
        }, {
            UICorner = (colorType ~= "BrickColor") and
                Roact.createElement(StandardUICorner, { circular = true, })
            or nil,
        }),

        ColorButtonContainer = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, Style.Constants.ColorSequencePreviewWidth, 1, 0),
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
                    return value and "" or uiTranslations["SelectionColorMultipleValues_Indicator"]
                end),

                BackgroundColor3 = color:map(function(value)
                    local bkgColor

                    if (not isColorSequence) then
                        bkgColor = value and value:toColor3() or nil
                    else
                        bkgColor = Color3.new(1, 1, 1)
                    end

                    return bkgColor or theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
                end),
            }, {
                UICorner = Roact.createElement(StandardUICorner),

                UIGradient = isColorSequence and
                    Roact.createElement("UIGradient", {
                        Color = color:map(function(value)
                            return value and value:colorSequence(nil, "RGB") or ColorSequence.new(Color3.new(1, 1, 1))
                        end),
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
    self.commonPropertyValues, self.updateCommonPropertyValues = Roact.createBinding({})
    self.listLength, self.updateListLength = Roact.createBinding(0)

    self.selectionChanged = SelectionManager.SelectionChanged:subscribe(function()
        if (self.state.editColorPromise) then
            self.state.editColorPromise:cancel()
        end

        self:setState({
            propertyData = SelectionManager.GetSelectionColorPropertyData(),
        })

        self.updateCommonPropertyValues(SelectionManager.GetSelectionCommonColorPropertyValues())
    end)

    self.selectionColorsChanged = SelectionManager.SelectionColorsChanged:subscribe(function()
        self.updateCommonPropertyValues(SelectionManager.GetSelectionCommonColorPropertyValues())
    end)

    self:setState({
        propertyData = SelectionManager.GetSelectionColorPropertyData(),
    })

    self.updateCommonPropertyValues(SelectionManager.GetSelectionCommonColorPropertyValues())
end

ColorPropertiesList.didMount = function()
    SelectionManager.Connect()
end

ColorPropertiesList.willUnmount = function(self)
    self.unmounting = true

    if (self.state.editColorPromise) then
        self.state.editColorPromise:cancel()
    end

    SelectionManager.Disconnect()
    self.selectionChanged:unsubscribe()
    self.selectionColorsChanged:unsubscribe()
end

ColorPropertiesList.render = function(self)
    local listElements = {}
    local minCellWidth = 0

    local properties = self.state.propertyData.Properties
    local duplicateProperties = self.state.propertyData.Duplicated
    local sortedProperties = self.state.propertyData.Sorted

    for i = 1, #sortedProperties do
        local className, propertyName = sortedProperties[i][1], sortedProperties[i][2]
        local propNameTextSize, classNameTextSize = getCellTextSizes(propertyName, "(" .. className .. ")", duplicateProperties[propertyName])

        local cellWidth = LIST_ITEM_LEFT_PADDING +
            propNameTextSize.X +
            Style.Constants.MinorElementPadding +
            classNameTextSize.X +
            Style.Constants.MajorElementPadding +
            COLOR_TYPE_ICON_SIZE +
            Style.Constants.MinorElementPadding +
            Style.Constants.ColorSequencePreviewWidth +
            Style.Constants.MinorElementPadding

        minCellWidth = (cellWidth > minCellWidth) and cellWidth or minCellWidth
    end

    for i = 1, #sortedProperties do
        local className, propertyName = sortedProperties[i][1], sortedProperties[i][2]
        local propertyInfo = properties[className][propertyName]

        local compositeName = className .. "/" .. propertyName
        local promptTitle = className .. "." .. propertyName

        local valueType = propertyInfo.ValueType.Name
        local isColorSequence = (valueType == "ColorSequence")

        listElements[compositeName] = Roact.createElement(ColorPropertyListItem, {
            Size = UDim2.new(1, 0, 0, Style.Constants.LargeButtonHeight),
            LayoutOrder = i,

            className = className,
            propertyName = propertyName,
            custom = propertyInfo.Custom,
            colorType = ((className == "DataModelMesh") and (propertyName == "VertexColor")) and "Color3" or valueType,

            showClassName = duplicateProperties[propertyName],
            selected = (self.state.editingProperty == compositeName),
            disabled = self.state.editColorPromise and (self.state.editingProperty ~= compositeName),
            
            color = self.commonPropertyValues:map(function(values)
                return values[className] and values[className][propertyName] or nil
            end),

            promptForEdit = function()
                if (API.IsColorEditorOpen()) then return end

                if (self.state.editColorPromise) then
                    self.state.editColorPromise:cancel()
                end

                local rejected = false
                local commonPropertyValues = self.commonPropertyValues:getValue()

                local editValuePromptOptions = {
                    PromptTitle = promptTitle,
                }
        
                if (isColorSequence) then
                    editValuePromptOptions.GradientType = "Gradient"
                    editValuePromptOptions.InitialGradient = commonPropertyValues[className] and commonPropertyValues[className][propertyName] or nil
        
                    editValuePromptOptions.OnGradientChanged = function(intermediate)
                        SelectionManager.SetSelectionProperty(className, propertyName, intermediate, false)
                    end
                else
                    editValuePromptOptions.ColorType = "Color"
                    editValuePromptOptions.InitialColor = commonPropertyValues[className] and commonPropertyValues[className][propertyName] or nil
        
                    editValuePromptOptions.OnColorChanged = function(intermediate)
                        SelectionManager.SetSelectionProperty(className, propertyName, intermediate, false)
                    end
                end

                local editColorPromise = isColorSequence and
                    API.PromptForGradient(editValuePromptOptions)
                or
                    API.PromptForColor(editValuePromptOptions)
                
                editColorPromise:andThen(function(newColor)
                    SelectionManager.SetSelectionProperty(className, propertyName, newColor, true)
                end, function(err)
                    rejected = true

                    if (err == PluginEnums.PromptError.PromptCancelled) then
                        SelectionManager.RestoreSelectionColorPropertyFromSnapshot(className, propertyName, self.state.originalPropertyValues)
                    end
                end):finally(function()
                    if (not self.unmounting) then
                        self:setState({
                            editColorPromise = Roact.None,
                            editingProperty = Roact.None,
                            originalPropertyValues = Roact.None,
                        })
                    end
                end)

                -- prevent conflict if the Promise is immediately rejected
                if (not rejected) then
                    self:setState({
                        editColorPromise = editColorPromise,
                        editingProperty = compositeName,
                        originalPropertyValues = SelectionManager.GenerateSelectionColorPropertyValueSnapshot(className, propertyName)
                    })
                end
            end,
        })
    end

    listElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateListLength(obj.AbsoluteContentSize.Y)
        end,

        preset = 1,
    })

    return (#sortedProperties > 0) and
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

            Text = uiTranslations["NoSelectionColorProperties_Message"],
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextWrapped = true,
        }, {
            UIPadding = Roact.createElement(StandardUIPadding, { Style.Constants.PagePadding })
        })
end

---

ColorPropertyListItem = ConnectTheme(ColorPropertyListItem)
return ColorPropertiesList