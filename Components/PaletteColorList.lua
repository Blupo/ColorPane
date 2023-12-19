local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local ColorEditorInputSignals = require(PluginModules:FindFirstChild("EditorInputSignals")).ColorEditor
local RepeatingCallback = require(PluginModules:FindFirstChild("RepeatingCallback"))
local Style = require(PluginModules:FindFirstChild("Style"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local ConnectTheme = require(Components:FindFirstChild("ConnectTheme"))
local TextInput = require(Components:FindFirstChild("TextInput"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardScrollingFrame = StandardComponents.ScrollingFrame
local StandardTextLabel = StandardComponents.TextLabel
local StandardUIListLayout = StandardComponents.UIListLayout
local StandardUIPadding = StandardComponents.UIPadding

---

local KEY_CODE_DELTAS = {
    [Enum.KeyCode.Up] = -1,
    [Enum.KeyCode.Down] = 1,
}

--[[
    props

        AnchorPoint?
        Position?
        Size?

        colors: array<{
            name: string?,
            color: Color3
        }>

        readOnly: boolean?
        selected: number?

        onColorSelected: (number) -> nil
        onColorSet: (number) -> nil
        onColorRemoved: () -> nil
        onColorNameChanged: (string) -> nil
        onColorMovedUp: () -> nil
        onColorMovedDown: () -> nil

    store props
    
        theme: StudioTheme
]]

local PaletteColorList = Roact.PureComponent:extend("PaletteColorList")

PaletteColorList.init = function(self)
    self.listLength, self.updateListLength = Roact.createBinding(0)
    self.keyInputRepeaters = {}

    for keyCode, delta in pairs(KEY_CODE_DELTAS) do
        local repeater = RepeatingCallback.new(function()
            local colors = self.props.colors
            local selected = self.props.selected
            if (not selected) then return end

            local nextSelected = selected + delta
            if (not colors[nextSelected]) then return end

            self.props.onColorSelected(nextSelected)
        end, 0.25, 0.1)

        self.keyInputRepeaters[keyCode] = repeater
    end
end

PaletteColorList.didMount = function(self)
    self.keyDown = ColorEditorInputSignals.InputBegan.Event:subscribe(function(input: InputObject)
        if (input.UserInputType ~= Enum.UserInputType.Keyboard) then return end

        local inputRepeater = self.keyInputRepeaters[input.KeyCode]
        if (not inputRepeater) then return end

        for _, repeater in pairs(self.keyInputRepeaters) do
            repeater:stop()
        end

        inputRepeater:start()
    end)

    self.keyUp = ColorEditorInputSignals.InputEnded.Event:subscribe(function(input: InputObject)
        if (input.UserInputType ~= Enum.UserInputType.Keyboard) then return end

        local inputRepeater = self.keyInputRepeaters[input.KeyCode]
        if (not inputRepeater) then return end

        inputRepeater:stop()
    end)
end

PaletteColorList.willUnmount = function(self)
    for _, repeater in pairs(self.keyInputRepeaters) do
        repeater:destroy()
    end

    self.keyInputRepeaters = nil
    self.keyDown:unsubscribe()
    self.keyUp:unsubscribe()
end

PaletteColorList.render = function(self)
    local theme = self.props.theme
    local colors = self.props.colors

    local isReadOnly = self.props.readOnly
    local selected = self.props.selected

    local listElements = {}

    for i = 1, #colors do
        local color = colors[i]
        local isSelected = (selected == i)

        local listItemHeight

        if (isSelected) then
            listItemHeight = (Style.Constants.StandardButtonHeight * 2) + (Style.Constants.MinorElementPadding * 3)
        else
            listItemHeight = (Style.Constants.StandardButtonHeight * 1) + (Style.Constants.MinorElementPadding * 2)
        end

        table.insert(listElements, Roact.createElement("TextButton", {
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, listItemHeight),

            Text = "",
            TextTransparency = 1,

            BackgroundColor3 = isSelected and
                theme:GetColor(Enum.StudioStyleGuideColor.TableItem, Enum.StudioStyleGuideModifier.Selected)
            or theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame),

            [Roact.Event.MouseEnter] = function(obj)
                if (isSelected) then return end

                obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.TableItem, Enum.StudioStyleGuideModifier.Hover)
            end,

            [Roact.Event.MouseLeave] = function(obj)
                if (isSelected) then return end

                obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)
            end,

            [Roact.Event.Activated] = function()
                if (isSelected) then return end

                self.props.onColorSelected(i)
            end
        }, {
            UIPadding = Roact.createElement(StandardUIPadding, {Style.Constants.MinorElementPadding}),

            ColorIndicator = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, 0),

                displayType = "color",
                color = color.color,

                onActivated = function()
                    self.props.onColorSet(i)
                    self.props.onColorSelected(i)
                end,
            }),

            ColorName = (isSelected) and
                Roact.createElement(TextInput, {
                    AnchorPoint = Vector2.new(0, 0),
                    Position = UDim2.new(0, Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding, 0, 0),
                    Size = UDim2.new(1, -(Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding), 0, Style.Constants.StandardButtonHeight),

                    Text = color.name,
                    TextXAlignment = Enum.TextXAlignment.Left,

                    disabled = isReadOnly,
                    onSubmit = self.props.onColorNameChanged,
                })
            or
                Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0, 0),
                    Position = UDim2.new(0, Style.Constants.StandardButtonHeight + Style.Constants.SpaciousElementPadding + 1, 0, 0),
                    Size = UDim2.new(1, -(Style.Constants.StandardButtonHeight + Style.Constants.SpaciousElementPadding + 1), 1, 0),
                    Text = color.name,

                    TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText, isSelected and Enum.StudioStyleGuideModifier.Selected or nil),
                }),

            ColorActions = (isSelected) and
                Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding, 1, 0),
                    Size = UDim2.new(1, -(Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding), 0, Style.Constants.StandardButtonHeight),

                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, {
                    UIListLayout = Roact.createElement(StandardUIListLayout, {
                        Padding = UDim.new(0, Style.Constants.MinorElementPadding),
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Left,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    }),

                    RemoveColorButton = (not isReadOnly) and
                        Roact.createElement(Button, {
                            LayoutOrder = 1,
            
                            displayType = "image",
                            image = Style.Images.DeleteButtonIcon,

                            onActivated = self.props.onColorRemoved,
                        })
                    or nil,
        
                    MoveUpButton = (not isReadOnly) and
                        Roact.createElement(Button, {
                            LayoutOrder = 2,
            
                            displayType = "image",
                            image = Style.Images.MoveUpButtonIcon,
                            disabled = (selected == 1),
                                    
                            onActivated = self.props.onColorMovedUp,
                        })
                    or nil,
        
                    MoveDownButton = (not isReadOnly) and
                        Roact.createElement(Button, {
                            LayoutOrder = 3,
            
                            displayType = "image",
                            image = Style.Images.MoveDownButtonIcon,
                            disabled = (selected == #colors),

                            onActivated = self.props.onColorMovedDown,
                        })
                    or nil,

                    SetColorButton = Roact.createElement(Button, {
                        LayoutOrder = 4,
                        Size = Style.UDim2.DialogButtonSize,
        
                        displayType = "text",
                        text = "Set Color",

                        onActivated = function()
                            self.props.onColorSet(i)
                        end,
                    })
                })
            or nil,
        }))
    end

    listElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateListLength(obj.AbsoluteContentSize.Y)
        end,

        preset = 1,
    })

    return Roact.createElement(StandardScrollingFrame, {
        AnchorPoint = self.props.AnchorPoint,
        Position = self.props.Position,
        Size = self.props.Size,
        BackgroundTransparency = 0,
        BorderSizePixel = 1,

        CanvasSize = self.listLength:map(function(listLength)
            return UDim2.new(0, 0, 0, listLength)
        end),
    }, listElements)
end

---

return ConnectTheme(PaletteColorList)