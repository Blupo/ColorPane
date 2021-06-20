local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local StudioService = game:GetService("StudioService")

---

local root = script.Parent.Parent

local PluginModules = root:FindFirstChild("PluginModules")
local PluginEnums = require(PluginModules:FindFirstChild("PluginEnums"))
local PaletteUtils = require(PluginModules:FindFirstChild("PaletteUtils"))
local Style = require(PluginModules:FindFirstChild("Style"))
local Util = require(PluginModules:FindFirstChild("Util"))

local includes = root:FindFirstChild("includes")
local Promise = require(includes:FindFirstChild("Promise"))
local Roact = require(includes:FindFirstChild("Roact"))
local RoactRodux = require(includes:FindFirstChild("RoactRodux"))

local Components = root:FindFirstChild("Components")
local Button = require(Components:FindFirstChild("Button"))
local Padding = require(Components:FindFirstChild("Padding"))
local RadioButtonGroup = require(Components:FindFirstChild("RadioButtonGroup"))
local TextInput = require(Components:FindFirstChild("TextInput"))

---

local HTTP_TIMEOUT = 10

local importTypeIndexKeys = {
    [1] = "ModuleScript",
    [2] = "StringValue",
    [3] = "File",
    [4] = "URL",
}

local statusIcons = {
    ok = Style.StatusGoodImage,
    notOk = Style.StatusBadImage,
    wait = Style.StatusWaitingImage,
}

local statusColorGenerators = {
    ok = function()
        return Color3.fromRGB(0, 170, 0)
    end,

    notOk = function(theme)
        return theme:GetColor(Enum.StudioStyleGuideColor.ErrorText)
    end,
}

local importStatusMessages = {
    NoObjectSelected = "At least one object should be selected",
    MultipleObjectsSelected = "Only one object should be selected",
    NotAnX = "The selected object is not a %s",
    ValidPalette = "The %s contains a valid palette"
}

---

--[[
    props

        onPromptClosed: (boolean) -> nil
]]

local ImportPalette = Roact.PureComponent:extend("ImportPalette")

ImportPalette.init = function(self)
    self.statusIcon = Roact.createRef()
    self.listLength, self.updateListLength = Roact.createBinding(0)

    self.importSuccessHandler = function(message)
        return function(palette)
            if (palette) then
                self:setState({
                    palette = palette,
                    paletteName = palette.name,
                    
                    status = "ok",
                    statusMessage = message
                })
            else
                self:setState({
                    status = Roact.None,
                    statusMessage = Roact.None,
                })
            end
        end
    end

    self.importErrorHandler = function(error)
        if (Promise.Error.is(error)) then
            error = error.error
        end

        self:setState({
            status = "notOk",
            statusMessage = error,
        })
    end
end

ImportPalette.didMount = function(self)
    self.rotator = RunService.Heartbeat:Connect(function()
        local statusIcon = self.statusIcon:getValue()
        if (not statusIcon) then return end

        if (self.state.status == "wait") then
            statusIcon.Rotation = (statusIcon.Rotation + 1) % 360  
        else
            statusIcon.Rotation = 0
        end
    end)
end

ImportPalette.willUnmount = function(self)
    self.rotator:Disconnect()

    if (self.webImportPromise) then
        self.webImportPromise:cancel()
        self.webImportPromise = nil
    end
end

ImportPalette.render = function(self)
    local theme = self.props.theme

    local status = self.state.status
    local importType = self.state.importType
    local importPage

    local palettes = self.props.palettes
    local palette = self.state.palette
    local paletteName = self.state.paletteName
    local newPaletteName = paletteName and PaletteUtils.getNewPaletteName(palettes, paletteName) or nil

    if (importType == "ModuleScript") then
        importPage = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, (Style.StandardTextSize * 3) + Style.StandardButtonSize + (Style.MinorElementPadding * 2)),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 3,
        }, {
            Instructions = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, 0, 0, Style.StandardTextSize),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = "Select a ModuleScript from the Explorer",
                Font = Style.StandardFont,
                TextSize = Style.StandardTextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextStrokeTransparency = 1,

                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
            }),

            ConfirmButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, Style.StandardTextSize + Style.MinorElementPadding),
                Size = UDim2.new(0, 80, 0, Style.StandardButtonSize),
                
                displayType = "text",
                text = "Use Selection",

                onActivated = function()
                    self:setState({
                        palette = Roact.None,
                    })

                    Promise.new(function(resolve, reject)
                        local selection = Selection:Get()

                        if (#selection > 1) then
                            reject(importStatusMessages.MultipleObjectsSelected)
                            return
                        elseif (#selection < 1) then
                            reject(importStatusMessages.NoObjectSelected)
                            return
                        end

                        local object = selection[1]

                        if (not object:IsA("ModuleScript")) then
                            reject(string.format(importStatusMessages.NotAnX, "ModuleScript"))
                            return
                        end

                        local newPalette = require(selection[1])
                        
                        if (type(newPalette) == "string") then
                            newPalette = HttpService:JSONDecode(newPalette)
                        end

                        local isValid, message = PaletteUtils.validate(newPalette)

                        if (isValid) then
                            resolve(newPalette)
                        else
                            reject(message)
                        end
                    end):andThen(
                        self.importSuccessHandler(string.format(importStatusMessages.ValidPalette, "ModuleScript")),
                        self.importErrorHandler
                    )
                end,
            }),

            StatusIcon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(0, Style.StandardButtonSize, 0, Style.StandardButtonSize),
                Position = UDim2.new(0, 80 + Style.MinorElementPadding, 0, Style.StandardTextSize + Style.MinorElementPadding),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = status and statusIcons[status] or "",
                ImageColor3 = statusColorGenerators[status] and statusColorGenerators[status](theme) or theme:GetColor(Enum.StudioStyleGuideColor.MainText),

                [Roact.Ref] = self.statusIcon,
            }),

            StatusText = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, 0, 0, Style.StandardTextSize * 2),
                Position = UDim2.new(0, 0, 0, Style.StandardTextSize + Style.StandardButtonSize + (Style.MinorElementPadding * 2)),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = self.state.statusMessage or "Waiting for import...",
                Font = Style.StandardFont,
                TextSize = Style.StandardTextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextStrokeTransparency = 1,
                TextWrapped = true,

                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
            }),
        })
    elseif (importType == "StringValue") then
        importPage = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, (Style.StandardTextSize * 3) + Style.StandardButtonSize + (Style.MinorElementPadding * 2)),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 3,
        }, {
            Instructions = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, 0, 0, Style.StandardTextSize),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = "Select a StringValue from the Explorer",
                Font = Style.StandardFont,
                TextSize = Style.StandardTextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextStrokeTransparency = 1,

                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
            }),

            ConfirmButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, Style.StandardTextSize + Style.MinorElementPadding),
                Size = UDim2.new(0, 80, 0, Style.StandardButtonSize),
                
                displayType = "text",
                text = "Use Selection",

                onActivated = function()
                    self:setState({
                        palette = Roact.None,
                    })

                    Promise.new(function(resolve, reject)
                        local selection = Selection:Get()

                        if (#selection > 1) then
                            reject(importStatusMessages.MultipleObjectsSelected)
                            return
                        elseif (#selection < 1) then
                            reject(importStatusMessages.NoObjectSelected)
                            return
                        end

                        local object = selection[1]

                        if (not object:IsA("StringValue")) then
                            reject(string.format(importStatusMessages.NotAnX, "StringValue"))
                            return
                        end

                        local newPalette = HttpService:JSONDecode(object.Value)
                        local isValid, message = PaletteUtils.validate(newPalette)

                        if (isValid) then
                            resolve(newPalette)
                        else
                            reject(message)
                        end
                    end):andThen(
                        self.importSuccessHandler(string.format(importStatusMessages.ValidPalette, "StringValue")),
                        self.importErrorHandler
                    )
                end,
            }),

            StatusIcon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(0, Style.StandardButtonSize, 0, Style.StandardButtonSize),
                Position = UDim2.new(0, 80 + Style.MinorElementPadding, 0, Style.StandardTextSize + Style.MinorElementPadding),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = status and statusIcons[status] or "",
                ImageColor3 = statusColorGenerators[status] and statusColorGenerators[status](theme) or theme:GetColor(Enum.StudioStyleGuideColor.MainText),

                [Roact.Ref] = self.statusIcon,
            }),

            StatusText = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, 0, 0, Style.StandardTextSize * 2),
                Position = UDim2.new(0, 0, 0, Style.StandardTextSize + Style.StandardButtonSize + (Style.MinorElementPadding * 2)),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = self.state.statusMessage or "Waiting for import...",
                Font = Style.StandardFont,
                TextSize = Style.StandardTextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextStrokeTransparency = 1,
                TextWrapped = true,

                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
            }),
        })
    elseif (importType == "File") then
        importPage = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, Style.StandardButtonSize + Style.MinorElementPadding + (Style.StandardTextSize * 2)),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 3,
        }, {
            ImportButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, Style.DialogButtonWidth, 0, Style.StandardButtonSize),
                
                disabled = (status == "wait"),
                displayType = "text",
                text = "Select a File",

                onActivated = function()
                    self:setState({
                        palette = Roact.None,
                        status = "wait",
                    })

                    local file

                    Promise.new(function(resolve, reject)
                        file = StudioService:PromptImportFile({"json"})
                        
                        if (not file) then
                            resolve()
                            return
                        end
                        
                        local newPalette = HttpService:JSONDecode(file:GetBinaryContents())
                        local isValid, message = PaletteUtils.validate(newPalette)

                        if (isValid) then
                            resolve(newPalette)
                        else
                            reject(message)
                        end
                    end):andThen(
                        self.importSuccessHandler(string.format(importStatusMessages.ValidPalette, "file")),
                        self.importErrorHandler
                    ):finally(function()
                        if (file) then
                            file:Destroy()
                            file = nil
                        end
                    end)
                end,
            }),

            StatusIcon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(0, Style.StandardButtonSize, 0, Style.StandardButtonSize),
                Position = UDim2.new(0, Style.DialogButtonWidth + Style.MinorElementPadding, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = status and statusIcons[status] or "",
                ImageColor3 = statusColorGenerators[status] and statusColorGenerators[status](theme) or theme:GetColor(Enum.StudioStyleGuideColor.MainText),

                [Roact.Ref] = self.statusIcon,
            }),

            StatusText = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, 0, 0, Style.StandardTextSize * 2),
                Position = UDim2.new(0, 0, 0, Style.StandardButtonSize + Style.MinorElementPadding),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = self.state.statusMessage or "Waiting for import...",
                Font = Style.StandardFont,
                TextSize = Style.StandardTextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextStrokeTransparency = 1,
                TextWrapped = true,

                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
            }),
        })
    elseif (importType == "URL") then
        importPage = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, Style.StandardInputHeight + Style.StandardButtonSize + (Style.StandardTextSize * 2) + (Style.MinorElementPadding * 2)),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 3,
        }, {
            URLInput = Roact.createElement(TextInput, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, Style.StandardInputHeight),

                Text = self.state.importURL or "",
                PlaceholderText = "Type or paste a URL here",

                onTextChanged = function(newText)
                    self:setState({
                        importURL = newText
                    })
                end,
            }),

            RetrieveURLButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, Style.StandardInputHeight + Style.MinorElementPadding),
                Size = UDim2.new(0, 80, 0, Style.StandardButtonSize),
                
                disabled = (status == "wait"),
                displayType = "text",
                text = "Retrieve URL",

                onActivated = function()
                    local url = self.state.importURL
                    if (not url) or (url == "") then return end

                    if (self.webImportPromise) then
                        self.webImportPromise:cancel()
                        self.webImportPromise = nil
                    end

                    self:setState({
                        palette = Roact.None,
                        status = "wait"
                    })

                    local promise = Promise.new(function(resolve, reject)
                        local response = HttpService:RequestAsync({
                            Url = url,
                            Method = "GET"
                        })

                        if (not response.Success) then
                            reject(response.StatusMessage)
                            return
                        else
                            local newPalette = HttpService:JSONDecode(response.Body)
                            local isValid, message = PaletteUtils.validate(newPalette)

                            if (isValid) then
                                resolve(newPalette)
                            else
                                reject(message)
                            end
                        end
                    end):timeout(HTTP_TIMEOUT)
                    
                    promise:andThen(
                        self.importSuccessHandler(string.format(importStatusMessages.ValidPalette, "URL")),
                        self.importErrorHandler
                    ):finally(function()
                        self.webImportPromise = nil
                    end)

                    self.webImportPromise = promise
                end,
            }),

            StatusIcon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(0, Style.StandardButtonSize, 0, Style.StandardButtonSize),
                Position = UDim2.new(0, 80 + Style.MinorElementPadding, 0, Style.StandardInputHeight + Style.MinorElementPadding),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = status and statusIcons[status] or "",
                ImageColor3 = statusColorGenerators[status] and statusColorGenerators[status](theme) or theme:GetColor(Enum.StudioStyleGuideColor.MainText),

                [Roact.Ref] = self.statusIcon,
            }),

            StatusText = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, 0, 0, Style.StandardTextSize * 2),
                Position = UDim2.new(0, 0, 0, Style.StandardInputHeight + Style.StandardButtonSize + (Style.MinorElementPadding * 2)),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = self.state.statusMessage or "Waiting for import...",
                Font = Style.StandardFont,
                TextSize = Style.StandardTextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextStrokeTransparency = 1,
                TextWrapped = true,

                TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
            }),
        })
    end

    return Roact.createFragment({
        Dialog = Roact.createElement("ScrollingFrame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.new(1, 0, 1, -(Style.StandardButtonSize + Style.SpaciousElementPadding)),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            CanvasSize = self.listLength:map(function(length)
                return UDim2.new(0, 0, 0, length)
            end),

            TopImage = Style.ScrollbarImage,
            MidImage = Style.ScrollbarImage,
            BottomImage = Style.ScrollbarImage,
            HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
            VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
            VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right,
            ScrollBarThickness = Style.ScrollbarThickness,
            ClipsDescendants = true,

            ScrollBarImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ScrollBar),
        }, {
            UIPadding = Roact.createElement(Padding, { 0, 0, 0, Style.SpaciousElementPadding }),

            UIListLayout = Roact.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Top,

                Padding = UDim.new(0, Style.SpaciousElementPadding),

                [Roact.Change.AbsoluteContentSize] = function(obj)
                    self.updateListLength(obj.AbsoluteContentSize.Y)
                end,
            }),
            
            ImportType = Roact.createElement(RadioButtonGroup, {
                Size = UDim2.new(1, 0, 0, (Style.StandardButtonSize * 4) + (Style.MinorElementPadding * 3)),
                LayoutOrder = 1,
    
                options = { "ModuleScript", "StringValue", "JSON File", "URL" },

                onSelected = function(i)
                    self:setState({
                        importType = importTypeIndexKeys[i],

                        importURL = Roact.None,
                        palette = Roact.None,

                        status = Roact.None,
                        statusMessage = Roact.None,
                    })

                    if (self.webImportPromise) then
                        self.webImportPromise:cancel()
                        self.webImportPromise = nil
                    end
                end,
            }),

            Separator1 = self.state.importType and
                Roact.createElement("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    LayoutOrder = 2,

                    BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Separator)
                })
            or nil,

            ImportPage = self.state.importType and
                importPage
            or nil,

            Separator2 = self.state.palette and
                Roact.createElement("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    LayoutOrder = 4,

                    BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Separator)
                })
            or nil,

            Naming = self.state.palette and
                Roact.createElement("Frame", {
                    Size = UDim2.new(1, 0, 0, Style.StandardInputHeight + Style.StandardTextSize + Style.MinorElementPadding),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    LayoutOrder = 5,
                }, {
                    NameInput = Roact.createElement(TextInput, {
                        AnchorPoint = Vector2.new(0, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        Size = UDim2.new(1, 0, 0, Style.StandardInputHeight),
            
                        Text = self.state.paletteName,
                        TextSize = Style.StandardTextSize,
            
                        canClear = false,

                        onTextChanged = function(newText)
                            self:setState({
                                paletteName = newText
                            })
                        end,
                    }),
            
                    NameIsOKLabel = Roact.createElement("TextLabel", {
                        AnchorPoint = Vector2.new(0, 0),
                        Position = UDim2.new(0, 0, 0, Style.StandardInputHeight + Style.MinorElementPadding),
                        Size = UDim2.new(1, 0, 0, Style.StandardTextSize),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
            
                        Font = Style.StandardFont,
                        TextSize = Style.StandardTextSize,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        Text = (paletteName ~= newPaletteName) and ("The palette will be renamed to '" .. newPaletteName .. "'") or "The palette name is OK",
            
                        TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
                    }),
                })
            or nil,
        }),

        Buttons = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, 0, 1, 0),
            Size = UDim2.new(0, Style.DialogButtonWidth * 2 + Style.SpaciousElementPadding, 0, Style.StandardButtonSize),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            UIListLayout = Roact.createElement("UIListLayout", {
                Padding = UDim.new(0, Style.SpaciousElementPadding),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            }),

            CancelButton = Roact.createElement(Button, {
                Size = UDim2.new(0, Style.DialogButtonWidth, 0, Style.StandardButtonSize),
                LayoutOrder = 0,

                displayType = "text",
                text = "Cancel",

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton, Enum.StudioStyleGuideModifier.Hover),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonText),

                onActivated = function()
                    self.props.onPromptClosed(false)
                end
            }),

            ImportButton = Roact.createElement(Button, {
                Size = UDim2.new(0, Style.DialogButtonWidth, 0, Style.StandardButtonSize),
                LayoutOrder = 1,

                disabled = (not (palette and newPaletteName)),
                displayType = "text",
                text = "Import",

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton, Enum.StudioStyleGuideModifier.Hover),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText),

                onActivated = function()
                    palette = Util.copy(palette)
                    palette.name = newPaletteName

                    -- convert tables to colors
                    local colors = palette.colors

                    for i = 1, #colors do
                        local color = colors[i].color
                        
                        colors[i].color = Color3.new(color[1], color[2], color[3])
                    end

                    self.props.addPalette(palette)
                    self.props.onPromptClosed(true)
                end
            }),
        })
    })
end

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,
        palettes = state.colorEditor.palettes,
    }
end, function(dispatch)
    return {
        addPalette = function(palette)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_AddPalette,
                palette = palette,
            })
        end,
    }
end)(ImportPalette)