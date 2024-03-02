-- A container for multiple buttons, where one button is selected at a time

local Common = script.Parent.Parent.Common

local CommonPluginModules = Common.PluginModules
local Style = require(CommonPluginModules.Style)

local CommonIncludes = Common.Includes
local Cryo = require(CommonIncludes.Cryo)
local Roact = require(CommonIncludes.RoactRodux.Roact)

local CommonComponents = Common.Components
local ConnectTheme = require(CommonComponents.ConnectTheme)

local StandardComponents = CommonComponents.StandardComponents
local StandardTextLabel = require(StandardComponents.TextLabel)
local StandardUICorner = require(StandardComponents.UICorner)
local StandardUIListLayout = require(StandardComponents.UIListLayout)

---

--[[
    props
        AnchorPoint?
        Position?
        Size?
        LayoutOrder?

        title: string?
        vertical: boolean?
        selected: number?
        customLayout: boolean?

        displayType: "image" | "text"

        buttons: array<{
            name: string,
            text: string?,
            image: string?,

            disabled: boolean?,

            displayColor: Color3?,
            selctedDisplayColor: Color3?,
            disabledDisplayColor: Color3?
        }>

        onButtonActivated: (number) -> nil
    
    store props
        theme: StudioTheme
]]

local buttonTypes = {
    image = "ImageButton",
    text = "TextButton"
}

local getTextButtonProps = function(text, textColor)
    return {
        Font = Style.Fonts.Standard,
        TextSize = Style.Constants.StandardTextSize,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Text = text,
        TextColor3 = textColor,
    }
end

local getImageButtonProps = function(image, imageColor)
    return {
        Image = image,
        ScaleType = Enum.ScaleType.Fit,
        ImageColor3 = imageColor,
    }
end

---

local ButtonBar = Roact.PureComponent:extend("ButtonBar")

ButtonBar.render = function(self)
    local theme = self.props.theme
    local displayType = self.props.displayType
    local selected = self.props.selected

    local buttonElements = {}
    local numButtons = #self.props.buttons

    for i = 1, numButtons do
        local buttonInfo = self.props.buttons[i]

        local buttonProps: {[any]: any} = {
            Size = if self.props.vertical then
                UDim2.new(1, -2, 1 / numButtons, if ((i == 1) or (i == numButtons)) then -1 else 0)
            else UDim2.new(1 / numButtons, if ((i == 1) or (i == numButtons)) then -1 else 0, 1, -2),

            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            LayoutOrder = if self.props.customLayout then buttonInfo.order else i,
            AutoButtonColor = false,
    
            BackgroundColor3 = theme:GetColor(
                Enum.StudioStyleGuideColor.Button,
                if (selected == i) then Enum.StudioStyleGuideModifier.Selected else nil
            ),
    
            [Roact.Event.MouseEnter] = function(obj)
                if (buttonInfo.disabled) then return end
                if (selected == i) then return end
    
                obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
            end,
    
            [Roact.Event.MouseLeave] = function(obj)
                if (buttonInfo.disabled) then return end
                if (selected == i) then return end

                obj.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button)
            end,
    
            [Roact.Event.Activated] = function()
                if (buttonInfo.disabled) then return end
                if (selected == i) then return end
                
                self.props.onButtonActivated(i)
            end
        }

        local displayColor

        if (buttonInfo.disabled) then
            displayColor = buttonInfo.disabledDisplayColor or theme:GetColor(Enum.StudioStyleGuideColor.ButtonText, Enum.StudioStyleGuideModifier.Disabled)
        else
            if (selected == i) then
                displayColor = buttonInfo.selectedDisplayColor or theme:GetColor(
                    Enum.StudioStyleGuideColor.ButtonText,
                    Enum.StudioStyleGuideModifier.Selected
                )
            else
                displayColor = buttonInfo.displayColor or theme:GetColor(Enum.StudioStyleGuideColor.ButtonText)
            end
        end

        if (displayType == "image") then
            buttonProps = Cryo.Dictionary.join(buttonProps, getImageButtonProps(buttonInfo.image, displayColor))
        elseif (displayType == "text") then
            buttonProps = Cryo.Dictionary.join(buttonProps, getTextButtonProps(buttonInfo.name, displayColor))
        end

        buttonElements[buttonInfo.name] = Roact.createElement(buttonTypes[displayType], buttonProps)
    end

    buttonElements.UICorner = Roact.createElement(StandardUICorner)
    buttonElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        FillDirection = if self.props.vertical then Enum.FillDirection.Vertical else Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

    return Roact.createElement("Frame", {
        AnchorPoint = self.props.AnchorPoint,
        Size = self.props.Size,
        Position = self.props.Position,
        LayoutOrder = self.props.LayoutOrder,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        TitleLabel = if (self.props.title and (not self.props.vertical)) then
            Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),

                Font = Style.Fonts.Standard,
                Text = self.props.title .. ": " .. self.props.buttons[selected].name,
            })
        else nil,

        Buttons = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            Size = if self.props.vertical then
                UDim2.new(1, 0, 1, 0)
            else UDim2.new(1, 0, 1, if self.props.title then
                -(Style.Constants.StandardTextSize + Style.Constants.MinorElementPadding)
            else 0),

            BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ButtonBorder)
        }, buttonElements)
    })
end

return ConnectTheme(ButtonBar)