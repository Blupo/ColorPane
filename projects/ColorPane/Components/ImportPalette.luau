-- A page for importing palettes

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local StudioService = game:GetService("StudioService")

---

local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local Style = require(CommonModules.Style)
local Translator = require(CommonModules.Translator)

local CommonIncludes = Common.Includes
local Promise = require(CommonIncludes.Promise)
local Roact = require(CommonIncludes.RoactRodux.Roact)
local RoactRodux = require(CommonIncludes.RoactRodux.RoactRodux)

local CommonComponents = Common.Components
local Button = require(CommonComponents.Button)
local RadioButtonGroup = require(CommonComponents.RadioButtonGroup)
local TextInput = require(CommonComponents.TextInput)

local StandardComponents = CommonComponents.StandardComponents
local StandardScrollingFrame = require(StandardComponents.ScrollingFrame)
local StandardTextLabel = require(StandardComponents.TextLabel)
local StandardUIListLayout = require(StandardComponents.UIListLayout)
local StandardUIPadding = require(StandardComponents.UIPadding)

local Modules = root.Modules
local Enums = require(Modules.Enums)
local Util = require(Modules.Util)

---

local HTTP_TIMEOUT = 10

local importTypes = { "ModuleScript", "StringValue", "File", "URL" }

local importOptions = {
    "ModuleScript",
    "StringValue",
    Translator.FormatByKey("JSONFile_ImportType"),
    Translator.FormatByKey("URL_ImportType"),
}

local uiTranslations = Translator.GenerateTranslationTable({
    "JSONFile_ImportType",
    "URL_ImportType",
    "URL_InputText",

    "RetrieveURL_ButtonText",
    "UseSelection_ButtonText",
    "SelectAFile_ButtonText",
    "Import_ButtonText",
    "Cancel_ButtonText",

    "WaitingForImport_Message",
    "EmptySelection_Message",
    "MultipleSelections_Message",
    "PaletteNameOK_Message",
})

local statusIcons = {
    ok = Style.Images.ResultOkIcon,
    notOk = Style.Images.ResultNotOkIcon,
    wait = Style.Images.ResultWaitingIcon,
}

local statusColorGenerators = {
    ok = function()
        return Color3.fromRGB(0, 170, 0)
    end,

    notOk = function(theme)
        return theme:GetColor(Enum.StudioStyleGuideColor.ErrorText)
    end,
}

--[[
local importStatusMessages = {
    NoObjectSelected = "At least one object should be selected",
    MultipleObjectsSelected = "Only one object should be selected",
    NotAnX = "The selected object is not a %s",
    ValidPalette = "The %s contains a valid palette",
    NonConformantPalette = "Palette format check failed: %s",
}
]]

---

--[[
    props
        onPromptClosed: (boolean) -> nil
    
    store props
        theme: StudioTheme
        palettes: array<Palette>

        addPalette: (Palette) -> nil
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
    self.rotator = RunService.Heartbeat:Connect(function(step)
        local statusIcon = self.statusIcon:getValue()
        if (not statusIcon) then return end

        if (self.state.status == "wait") then
            statusIcon.Rotation = (statusIcon.Rotation + (step * 60)) % 360  
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
    local newPaletteName = if paletteName then Util.palette.getNewItemName(palettes, paletteName) else nil

    if (importType == "ModuleScript") then
        importPage = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, (Style.Constants.StandardTextSize * 3) + Style.Constants.StandardButtonHeight + (Style.Constants.MinorElementPadding * 2)),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 3,
        }, {
            Instructions = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
                Position = UDim2.new(0, 0, 0, 0),
                Text = Translator.FormatByKey("SelectObject_Prompt", { "ModuleScript" }),
            }),

            ConfirmButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, Style.Constants.StandardTextSize + Style.Constants.MinorElementPadding),
                Size = UDim2.new(0, 80, 0, Style.Constants.StandardButtonHeight),
                
                displayType = "text",
                text = uiTranslations["UseSelection_ButtonText"],

                onActivated = function()
                    self:setState({
                        palette = Roact.None,
                    })

                    Promise.new(function(resolve, reject)
                        local selection = Selection:Get()

                        if (#selection > 1) then
                            reject(uiTranslations["MultipleSelections_Message"])
                            return
                        elseif (#selection < 1) then
                            reject(uiTranslations["EmptySelection_Message"])
                            return
                        end

                        local object = selection[1]

                        if (not object:IsA("ModuleScript")) then
                            reject(Translator.FormatByKey("InvalidSelection_Message", { "ModuleScript" }))
                            return
                        end

                        local newPalette = require(selection[1])
                        
                        if (type(newPalette) == "string") then
                            newPalette = HttpService:JSONDecode(newPalette)
                        end

                        local isValid, message = Util.palette.validate(newPalette)

                        if (isValid) then
                            resolve(newPalette)
                        else
                            reject(Translator.FormatByKey("NonConformantPalette_Message", { message }))
                        end
                    end):andThen(
                        self.importSuccessHandler(Translator.FormatByKey("ValidImport_Message", { "ModuleScript" })),
                        self.importErrorHandler
                    )
                end,
            }),

            StatusIcon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = Style.UDim2.StandardButtonSize,
                Position = UDim2.new(0, 80 + Style.Constants.MinorElementPadding, 0, Style.Constants.StandardTextSize + Style.Constants.MinorElementPadding),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = if status then statusIcons[status] else "",

                ImageColor3 = if statusColorGenerators[status] then
                    statusColorGenerators[status](theme)
                else theme:GetColor(Enum.StudioStyleGuideColor.MainText),

                [Roact.Ref] = self.statusIcon,
            }),

            StatusText = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize * 2),
                Position = UDim2.new(0, 0, 0, Style.Constants.StandardTextSize + Style.Constants.StandardButtonHeight + (Style.Constants.MinorElementPadding * 2)),

                Text = self.state.statusMessage or uiTranslations["WaitingForImport_Message"],
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
            }),
        })
    elseif (importType == "StringValue") then
        importPage = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, (Style.Constants.StandardTextSize * 3) + Style.Constants.StandardButtonHeight + (Style.Constants.MinorElementPadding * 2)),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 3,
        }, {
            Instructions = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
                Position = UDim2.new(0, 0, 0, 0),
                Text = Translator.FormatByKey("SelectObject_Prompt", { "StringValue" }),
            }),

            ConfirmButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, Style.Constants.StandardTextSize + Style.Constants.MinorElementPadding),
                Size = UDim2.new(0, 80, 0, Style.Constants.StandardButtonHeight),
                
                displayType = "text",
                text = uiTranslations["UseSelection_ButtonText"],

                onActivated = function()
                    self:setState({
                        palette = Roact.None,
                    })

                    Promise.new(function(resolve, reject)
                        local selection = Selection:Get()

                        if (#selection > 1) then
                            reject(uiTranslations["MultipleSelections_Message"])
                            return
                        elseif (#selection < 1) then
                            reject(uiTranslations["EmptySelection_Message"])
                            return
                        end

                        local object = selection[1]

                        if (not object:IsA("StringValue")) then
                            reject(Translator.FormatByKey("InvalidSelection_Message", { "StringValue" }))
                            return
                        end

                        local newPalette = HttpService:JSONDecode(object.Value)
                        local isValid, message = Util.palette.validate(newPalette)

                        if (isValid) then
                            resolve(newPalette)
                        else
                            reject(Translator.FormatByKey("NonConformantPalette_Message", { message }))
                        end
                    end):andThen(
                        self.importSuccessHandler(Translator.FormatByKey("ValidImport_Message", { "StringValue" })),
                        self.importErrorHandler
                    )
                end,
            }),

            StatusIcon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = Style.UDim2.StandardButtonSize,
                Position = UDim2.new(0, 80 + Style.Constants.MinorElementPadding, 0, Style.Constants.StandardTextSize + Style.Constants.MinorElementPadding),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = if status then statusIcons[status] else "",

                ImageColor3 = if statusColorGenerators[status] then
                    statusColorGenerators[status](theme)
                else theme:GetColor(Enum.StudioStyleGuideColor.MainText),

                [Roact.Ref] = self.statusIcon,
            }),

            StatusText = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize * 2),
                Position = UDim2.new(0, 0, 0, Style.Constants.StandardTextSize + Style.Constants.StandardButtonHeight + (Style.Constants.MinorElementPadding * 2)),

                Text = self.state.statusMessage or uiTranslations["WaitingForImport_Message"],
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
            }),
        })
    elseif (importType == "File") then
        importPage = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding + (Style.Constants.StandardTextSize * 2)),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 3,
        }, {
            ImportButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, 0),
                Size = Style.UDim2.DialogButtonSize,
                
                disabled = (status == "wait"),
                displayType = "text",
                text = uiTranslations["SelectAFile_ButtonText"],

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
                        local isValid, message = Util.palette.validate(newPalette)

                        if (isValid) then
                            resolve(newPalette)
                        else
                            reject(Translator.FormatByKey("NonConformantPalette_Message", { message }))
                        end
                    end):andThen(
                        self.importSuccessHandler(Translator.FormatByKey("ValidImport_Message", { "file" })),
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
                Size = Style.UDim2.StandardButtonSize,
                Position = UDim2.new(0, Style.Constants.DialogButtonWidth + Style.Constants.MinorElementPadding, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = if status then statusIcons[status] else "",

                ImageColor3 = if statusColorGenerators[status] then
                    statusColorGenerators[status](theme)
                else theme:GetColor(Enum.StudioStyleGuideColor.MainText),

                [Roact.Ref] = self.statusIcon,
            }),

            StatusText = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize * 2),
                Position = UDim2.new(0, 0, 0, Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding),

                Text = self.state.statusMessage or uiTranslations["WaitingForImport_Message"],
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
            }),
        })
    elseif (importType == "URL") then
        importPage = Roact.createElement("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 3,
            
            Size = UDim2.new(
                1, 0, 0, Style.Constants.StandardInputHeight +
                    Style.Constants.StandardButtonHeight +
                    Style.Constants.StandardTextSize * 2 +
                    Style.Constants.MinorElementPadding * 2
            ),
        }, {
            URLInput = Roact.createElement(TextInput, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardInputHeight),

                Text = self.state.importURL or "",
                PlaceholderText = uiTranslations["URL_InputText"],

                onSubmit = function(newText)
                    self:setState({
                        importURL = newText
                    })
                end,

                canSubmitEmptyString = true,
                selectTextOnFocus = true,
            }),

            RetrieveURLButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, Style.Constants.StandardInputHeight + Style.Constants.MinorElementPadding),
                Size = UDim2.new(0, 80, 0, Style.Constants.StandardButtonHeight),
                
                disabled = (status == "wait"),
                displayType = "text",
                text = uiTranslations["RetrieveURL_ButtonText"],

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
                            reject(response.StatusCode .. " " .. response.StatusMessage)
                            return
                        else
                            local newPalette = HttpService:JSONDecode(response.Body)
                            local isValid, message = Util.palette.validate(newPalette)

                            if (isValid) then
                                resolve(newPalette)
                            else
                                reject(Translator.FormatByKey("NonConformantPalette_Message", { message }))
                            end
                        end
                    end):timeout(HTTP_TIMEOUT)
                    
                    promise:andThen(
                        self.importSuccessHandler(Translator.FormatByKey("ValidImport_Message", { "URL" })),
                        self.importErrorHandler
                    ):finally(function()
                        self.webImportPromise = nil
                    end)

                    self.webImportPromise = promise
                end,
            }),

            StatusIcon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = Style.UDim2.StandardButtonSize,
                Position = UDim2.new(0, 80 + Style.Constants.MinorElementPadding, 0, Style.Constants.StandardInputHeight + Style.Constants.MinorElementPadding),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = if status then statusIcons[status] else "",

                ImageColor3 = if statusColorGenerators[status] then
                    statusColorGenerators[status](theme)
                else theme:GetColor(Enum.StudioStyleGuideColor.MainText),

                [Roact.Ref] = self.statusIcon,
            }),

            StatusText = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize * 2),
                Position = UDim2.new(0, 0, 0, Style.Constants.StandardInputHeight + Style.Constants.StandardButtonHeight + (Style.Constants.MinorElementPadding * 2)),

                Text = self.state.statusMessage or uiTranslations["WaitingForImport_Message"],
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
            }),
        })
    end

    return Roact.createFragment({
        Dialog = Roact.createElement(StandardScrollingFrame, {
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.new(1, 0, 1, -(Style.Constants.StandardButtonHeight + Style.Constants.SpaciousElementPadding)),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            CanvasSize = self.listLength:map(function(length)
                return UDim2.new(0, 0, 0, length)
            end),
        }, {
            UIPadding = Roact.createElement(StandardUIPadding, {
                paddings = {0, 0, 0, Style.Constants.SpaciousElementPadding}
            }),

            UIListLayout = Roact.createElement(StandardUIListLayout, {
                Padding = UDim.new(0, Style.Constants.SpaciousElementPadding),

                [Roact.Change.AbsoluteContentSize] = function(obj)
                    self.updateListLength(obj.AbsoluteContentSize.Y)
                end,

                preset = 1,
            }),
            
            ImportType = Roact.createElement(RadioButtonGroup, {
                Size = UDim2.new(1, 0, 0, (Style.Constants.StandardButtonHeight * 4) + (Style.Constants.MinorElementPadding * 3)),
                LayoutOrder = 1,
    
                selected = table.find(importTypes, importType),
                options = importOptions,

                onSelected = function(i)
                    self:setState({
                        importType = importTypes[i],

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

            Separator1 = if self.state.importType then
                Roact.createElement("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    LayoutOrder = 2,

                    BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Separator)
                })
            else nil,

            ImportPage = if self.state.importType then importPage else nil,

            Separator2 = if self.state.palette then
                Roact.createElement("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    LayoutOrder = 4,

                    BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Separator)
                })
            else nil,

            Naming = if self.state.palette then
                Roact.createElement("Frame", {
                    Size = UDim2.new(1, 0, 0, Style.Constants.StandardInputHeight + Style.Constants.StandardTextSize + Style.Constants.MinorElementPadding),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    LayoutOrder = 5,
                }, {
                    NameInput = Roact.createElement(TextInput, {
                        AnchorPoint = Vector2.new(0, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        Size = UDim2.new(1, 0, 0, Style.Constants.StandardInputHeight),
            
                        Text = self.state.paletteName,
                        TextSize = Style.Constants.StandardTextSize,

                        onSubmit = function(newText)
                            self:setState({
                                paletteName = newText
                            })
                        end,
                    }),
            
                    NameIsOKLabel = Roact.createElement(StandardTextLabel, {
                        AnchorPoint = Vector2.new(0, 0),
                        Position = UDim2.new(0, 0, 0, Style.Constants.StandardInputHeight + Style.Constants.MinorElementPadding),
                        Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),

                        Text = if (paletteName ~= newPaletteName) then
                            Translator.FormatByKey("PaletteRename_Message", { newPaletteName })
                        else uiTranslations["PaletteNameOK_Message"],
                    }),
                })
            else nil,
        }),

        Buttons = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, 0, 1, 0),
            Size = UDim2.new(0, Style.Constants.DialogButtonWidth * 2 + Style.Constants.SpaciousElementPadding, 0, Style.Constants.StandardButtonHeight),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            UIListLayout = Roact.createElement(StandardUIListLayout, {
                Padding = UDim.new(0, Style.Constants.SpaciousElementPadding),
                
                preset = 2,
            }),

            CancelButton = Roact.createElement(Button, {
                Size = Style.UDim2.DialogButtonSize,
                LayoutOrder = 0,

                displayType = "text",
                text = uiTranslations["Cancel_ButtonText"],

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButton, Enum.StudioStyleGuideModifier.Hover),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonText),

                onActivated = function()
                    self.props.onPromptClosed(false)
                end
            }),

            ImportButton = Roact.createElement(Button, {
                Size = Style.UDim2.DialogButtonSize,
                LayoutOrder = 1,

                disabled = (not (palette and newPaletteName)),
                displayType = "text",
                text = uiTranslations["Import_ButtonText"],

                backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton),
                borderColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder),
                hoverColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton, Enum.StudioStyleGuideModifier.Hover),
                displayColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText),

                onActivated = function()
                    palette = Util.table.deepCopy(palette)
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
                type = Enums.StoreActionType.ColorEditor_AddPalette,
                palette = palette,
            })
        end,
    }
end)(ImportPalette)