-- A button that can display multiple types of content

local root = script.Parent.Parent

local PluginModules = root.PluginModules
local Style = require(PluginModules.Style)

local Includes = root.Includes
local Cryo = require(Includes.Cryo)
local Roact = require(Includes.RoactRodux.Roact)

local Components = root.Components
local ConnectTheme = require(Components.ConnectTheme)
local StandardUICorner = require(Components.StandardComponents.UICorner)

---

local buttonTypes = {
    image = "ImageButton",
    text = "TextButton",
    color = "ImageButton",
    colorSequence = "ImageButton",
}

local getImageButtonProps = function(image, imageColor)
    return {
        Image = image,
        ScaleType = Enum.ScaleType.Fit,
        ImageColor3 = imageColor,
    }
end

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

local getColorButtonProps = function(color)
    return {
        BackgroundColor3 = color,
        Image = "",
        ImageTransparency = 1,
    }
end

local colorSequenceButtonProps = {
    BackgroundColor3 = Color3.new(1, 1, 1),
    Image = "",
    ImageTransparency = 1,
}

---

--[[
    props
        AnchorPoint?
        LayoutOrder?
        Position?
        Size?

        borderColor: Color3?
        backgroundColor: Color3?
        hoverColor: Color3?
        displayColor: Color3?

        disabledBackgroundColor: Color3?
        disabledDisplayColor: Color3?

        displayType: "image" | "text" | "color" | "colorSequence"
        image: Content?
        text: string?
        color: Color3? | ColorSequence?

        disabled: boolean?
        onActivated: () -> nil

    store props
        theme: StudioTheme
]]

local Button = Roact.PureComponent:extend("Button")

Button.render = function(self)
    local theme = self.props.theme
    local displayType = self.props.displayType

    local borderColor = self.props.borderColor or theme:GetColor(Enum.StudioStyleGuideColor.ButtonBorder)
    local backgroundColor
    local displayColor

    if (not self.props.disabled) then
        backgroundColor = self.props.backgroundColor or theme:GetColor(Enum.StudioStyleGuideColor.Button)
        displayColor = self.props.displayColor or theme:GetColor(Enum.StudioStyleGuideColor.ButtonText)
    else
        backgroundColor = self.props.disabledBackgroundColor or theme:GetColor(
            Enum.StudioStyleGuideColor.Button,
            Enum.StudioStyleGuideModifier.Disabled
        )

        displayColor = self.props.disabledDisplayColor or theme:GetColor(
            Enum.StudioStyleGuideColor.ButtonText,
            Enum.StudioStyleGuideModifier.Disabled
        )
    end

    local buttonProps: {[any]: any} = {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, -2, 1, -2),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AutoButtonColor = false,

        BackgroundColor3 = backgroundColor,

        [Roact.Event.Activated] = function()
            if (self.props.disabled) then return end

            self.props.onActivated()
        end
    }

    if (displayType == "image") then
        buttonProps = Cryo.Dictionary.join(buttonProps, getImageButtonProps(self.props.image, displayColor))
    elseif (displayType == "text") then
        buttonProps = Cryo.Dictionary.join(buttonProps, getTextButtonProps(self.props.text, displayColor))
    elseif (displayType == "color") then
        buttonProps = Cryo.Dictionary.join(buttonProps, getColorButtonProps(self.props.color))
    elseif (displayType == "colorSequence") then
        buttonProps = Cryo.Dictionary.join(buttonProps, colorSequenceButtonProps)
    end

    if ((not self.props.disabled) and ((displayType == "image") or (displayType == "text"))) then
        buttonProps[Roact.Event.MouseEnter] = function(obj)
            obj.BackgroundColor3 = self.props.hoverColor or theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
        end

        buttonProps[Roact.Event.MouseLeave] = function(obj)
            obj.BackgroundColor3 = backgroundColor
        end
    end

    return Roact.createElement("Frame", {
        AnchorPoint = self.props.AnchorPoint,
        Position = self.props.Position,
        Size = self.props.Size or Style.UDim2.StandardButtonSize,
        LayoutOrder = self.props.LayoutOrder,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = borderColor,
    }, {
        UICorner = Roact.createElement(StandardUICorner),

        Button = Roact.createElement(buttonTypes[self.props.displayType], buttonProps, {
            UICorner = Roact.createElement(StandardUICorner),

            UIGradient = if (displayType == "colorSequence") then
                Roact.createElement("UIGradient", {
                    Color = self.props.color,
                })
            else nil,
        })
    })
end

return ConnectTheme(Button)