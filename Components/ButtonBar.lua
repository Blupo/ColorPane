local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local Style = require(PluginModules:FindFirstChild("Style"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local Roact = require(includes:FindFirstChild("Roact"))

local Components = root:FindFirstChild("Components")
local ConnectTheme = require(Components:FindFirstChild("ConnectTheme"))

local StandardComponents = require(Components:FindFirstChild("StandardComponents"))
local StandardTextLabel = StandardComponents.TextLabel
local StandardUICorner = StandardComponents.UICorner
local StandardUIListLayout = StandardComponents.UIListLayout

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

local merge = Util.mergeTable

local buttonTypes = {
    image = "ImageButton",
    text = "TextButton"
}

local getTextButtonProps = function(text, textColor)
    return {
        Font = Style.StandardFont,
        TextSize = Style.StandardTextSize,
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

        local buttonProps = {
            Size = self.props.vertical and
                UDim2.new(1, -2, 1 / numButtons, ((i == 1) or (i == numButtons)) and -1 or 0)
            or UDim2.new(1 / numButtons, ((i == 1) or (i == numButtons)) and -1 or 0, 1, -2),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            LayoutOrder = self.props.customLayout and buttonInfo.order or i,
            AutoButtonColor = false,
    
            BackgroundColor3 = theme:GetColor(
                Enum.StudioStyleGuideColor.Button,
                (selected == i) and Enum.StudioStyleGuideModifier.Selected or nil
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
            buttonProps = merge(buttonProps, getImageButtonProps(buttonInfo.image, displayColor))
        elseif (displayType == "text") then
            buttonProps = merge(buttonProps, getTextButtonProps(buttonInfo.name, displayColor))
        end

        buttonElements[buttonInfo.name] = Roact.createElement(buttonTypes[displayType], buttonProps)
    end

    buttonElements.UICorner = Roact.createElement(StandardUICorner)
    buttonElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        FillDirection = self.props.vertical and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal,
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
        TitleLabel = (self.props.title and (not self.props.vertical)) and
            Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, Style.StandardTextSize),

                Font = Style.StandardFont,
                Text = self.props.title .. ": " .. self.props.buttons[selected].name,
            })
        or nil,

        Buttons = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            Size = self.props.vertical and
                UDim2.new(1, 0, 1, 0)
            or UDim2.new(1, 0, 1, self.props.title and -(Style.StandardTextSize + Style.MinorElementPadding) or 0),

            BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ButtonBorder)
        }, buttonElements)
    })
end

return ConnectTheme(ButtonBar)