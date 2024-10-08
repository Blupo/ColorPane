-- A palette page for using Picular to generate color palettes

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

---

local root = script.Parent.Parent
local Common = root.Common

local CommonModules = Common.Modules
local Style = require(CommonModules.Style)
local Translator = require(CommonModules.Translator)

local CommonIncludes = Common.Includes
local Color = require(CommonIncludes.Color).Color
local Promise = require(CommonIncludes.Promise)
local Roact = require(CommonIncludes.RoactRodux.Roact)
local RoactRodux = require(CommonIncludes.RoactRodux.RoactRodux)

local CommonComponents = Common.Components
local Button = require(CommonComponents.Button)
local TextInput = require(CommonComponents.TextInput)

local StandardComponents = CommonComponents.StandardComponents
local StandardTextLabel = require(StandardComponents.TextLabel)
local StandardUIPadding = require(StandardComponents.UIPadding)

local Modules = root.Modules
local Enums = require(Modules.Enums)
local Util = require(Modules.Util)

local Components = root.Components
local ButtonBar = require(Components.ButtonBar)
local ColorGrids = require(Components.ColorGrids)
local SimpleList = require(Components.SimpleList)

---

local QUERY_URL = "https://backend.picular.co/api/search?query="

local uiTranslations = Translator.GenerateTranslationTable({
    "SearchHistory_Label",
    "ColorList_Label",
    "Searchbar_Prompt",
    "Clear_ButtonText",
})

local contentSize = UDim2.new(
    1, -2,
    1, -(
        (Style.Constants.StandardInputHeight * 2) +
        (Style.Constants.MinorElementPadding * 2) +
        2
    )
)

---

--[[
    store props
        theme: StudioTheme
        searchHistory: array<string>

        setColor: (Color) -> nil
        setSearchHistory: (array<string>) -> nil
]]

local PicularPalette = Roact.PureComponent:extend("PicularPalette")

PicularPalette.init = function(self)
    self.statusIcon = Roact.createRef()

    self.getPalette = function(searchTerm: string)
        local newPalette
        local lastFetchError
        local urlEncodedSearchTerm = HttpService:UrlEncode(searchTerm)

        self:setState({
            waitForFetch = true,
            lastFetchError = Roact.None,
            searchTerm = searchTerm,
            contentView = "ColorGrid",
        })

        local getPalettePromise = Promise.new(function(resolve, reject)
            local success, result = pcall(function()
                return HttpService:RequestAsync({
                    Url = QUERY_URL .. urlEncodedSearchTerm,
                    Method = "GET",
                })
            end)

            if (success) then
                local responseSuccess = result.Success

                if (responseSuccess) then
                    resolve(HttpService:JSONDecode(result.Body))
                else
                    reject(result.StatusMessage)
                end
            else
                reject(result)
            end
        end)

        self.getPalettePromise = getPalettePromise

        getPalettePromise:andThen(function(palette)
            newPalette = {}

            for i = 1, #palette.colors do
                local color = palette.colors[i]

                table.insert(newPalette, Color.fromHex(color.color):toColor3())
            end
        end, function(error)
            lastFetchError = Translator.FormatByKey("PicularPaletteFetchFailure_Message", { tostring(error) })
        end):finally(function()
            local newSearchHistory = Util.table.deepCopy(self.props.searchHistory)
            local searchTermIndex = table.find(newSearchHistory, searchTerm)

            if (searchTermIndex) then
                table.remove(newSearchHistory, searchTermIndex)
            end
            
            table.insert(newSearchHistory, 1, searchTerm)
            self.props.setSearchHistory(newSearchHistory)

            self:setState({
                waitForFetch = false,
                lastFetchError = lastFetchError or Roact.None,

                palette = newPalette or {},
            })
        end)
    end

    self:setState({
        waitForFetch = false,
        showHistory = false,

        searchTerm = "",
        contentView = "ColorGrid",

        palette = {},
    })
end

PicularPalette.didMount = function(self)
    self.rotator = RunService.Heartbeat:Connect(function(step)
        local statusIcon = self.statusIcon:getValue()
        if (not statusIcon) then return end

        if (self.state.waitForFetch) then
            statusIcon.Rotation = (statusIcon.Rotation + (step * 60)) % 360  
        else
            statusIcon.Rotation = 0
        end
    end)
end

PicularPalette.willUnmount = function(self)
    if (self.getPalettePromise) then
        self.getPalettePromise:cancel()
        self.getPalettePromise = nil
    end

    self.rotator:Disconnect()
    self.rotator = nil
end

PicularPalette.render = function(self)
    local theme = self.props.theme

    local waitForFetch = self.state.waitForFetch
    local lastFetchError = self.state.lastFetchError
    local searchTerm = self.state.searchTerm

    local contentView = self.state.contentView
    local showHistory = (contentView == "SearchHistory")

    local searchHistory = self.props.searchHistory
    local palette = self.state.palette

    local mainContent
    local headerExtra
    local searchHistoryItems = {}

    -- main content
    if (contentView == "ColorGrid") then
        if (not lastFetchError) then
            mainContent = Roact.createElement(ColorGrids, {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, 0),
                Size = contentSize,

                named = false,
                colorLists = {palette},

                onColorSelected = function(i)
                    self.props.setColor(Color.fromColor3(palette[i]))
                end,
            })
        else
            mainContent = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, 0),
                Size = contentSize,
                BackgroundTransparency = 0,
                BorderSizePixel = 1,

                BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame),
                BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
            }, {
                ErrorText = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(1, 0, 1, 0),

                    Text = lastFetchError,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextWrapped = true,
                })
            })
        end
    elseif (showHistory) then
        for i = 1, #searchHistory do
            local oldSearchTerm = searchHistory[i]

            table.insert(searchHistoryItems, {
                name = oldSearchTerm,
                LayoutOrder = i,

                onActivated = function()
                    self.getPalette(oldSearchTerm)
                end,

                [Roact.Children] = {
                    UIPadding = Roact.createElement(StandardUIPadding, {
                        paddings = {0, Style.Constants.SpaciousElementPadding}
                    }),

                    RemoveButton = Roact.createElement("ImageButton", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, 0, 0.5, 0),
                        Size = UDim2.new(0, Style.Constants.StandardButtonHeight - 2, 0, Style.Constants.StandardButtonHeight - 2),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,

                        Image = Style.Images.DeleteButtonIcon,
                        ImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),

                        [Roact.Event.Activated] = function()
                            local newSearchHistory = Util.table.deepCopy(searchHistory)
                            table.remove(newSearchHistory, i)

                            self.props.setSearchHistory(newSearchHistory)
                        end,
                    })
                }
            })
        end

        mainContent = Roact.createElement(SimpleList, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = contentSize,
            TextSize = Style.Constants.StandardTextSize,

            itemHeight = Style.Constants.StandardButtonHeight,

            sections = {
                {
                    name = "",
                    items = searchHistoryItems,
                }
            },
        })
    end

    -- header extra
    if (contentView == "ColorGrid") then
        if (waitForFetch) then
            headerExtra = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -1, 0.5, 0),
                Size = UDim2.new(0, Style.Constants.StandardInputHeight - 2, 0, Style.Constants.StandardInputHeight - 2),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
    
                Image = Style.Images.ResultWaitingIcon,
                ImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
    
                [Roact.Ref] = self.statusIcon,
            })
        else
            headerExtra = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, Style.Constants.StandardInputHeight, 0, Style.Constants.StandardInputHeight),
    
                displayType = "image",
                disabled = (searchTerm == ""),
                image = Style.Images.ResultWaitingIcon,
    
                onActivated = function()
                    self.getPalette(searchTerm)
                end,
            })
        end
    elseif (showHistory) then
        headerExtra = Roact.createElement(Button, {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 46, 0, Style.Constants.StandardInputHeight),

            displayType = "text",
            disabled = (#searchHistory == 0),
            text = uiTranslations["Clear_ButtonText"],

            onActivated = function()
                self.props.setSearchHistory({})
            end,
        })
    end

    return Roact.createFragment({
        Tools = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardInputHeight),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            SearchBar = Roact.createElement(TextInput, {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(1, -((Style.Constants.StandardButtonHeight * 2) + Style.Constants.MinorElementPadding + 2), 1, 0),

                PlaceholderText = uiTranslations["Searchbar_Prompt"],
                Text = searchTerm,
                
                disabled = waitForFetch,
                canSubmitEmptyString = false,

                onSubmit = function(newText)
                    local newSearchTerm = string.lower(Util.escapeText(newText))
                    if (newSearchTerm == "") then return end

                    self.getPalette(newSearchTerm)
                end,
            }),

            ContentPicker = Roact.createElement(ButtonBar, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, (Style.Constants.StandardButtonHeight * 2) + 2, 1, 0),

                displayType = "image",
                selected = if (contentView == "ColorGrid") then 1 else 2,

                buttons = {
                    {
                        name = "ColorGrid",
                        image = Style.Images.GridViewButtonIcon,
                    },

                    {
                        name = "SearchHistory",
                        disabled = waitForFetch,
                        image = Style.Images.SearchHistoryButtonIcon,
                    }
                },

                onButtonActivated = function(i)
                    self:setState({
                        contentView = if (i == 1) then "ColorGrid" else "SearchHistory",
                    })
                end,
            }),
        }),

        Header = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, Style.Constants.StandardInputHeight + Style.Constants.MinorElementPadding),
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardInputHeight),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Label = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 1, 0),

                Text = uiTranslations[if showHistory then "SearchHistory_Label" else "ColorList_Label"],
            }),

            Extra = headerExtra,
        }),

        Main = mainContent,
    })
end

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,
        searchHistory = state.sessionData.picularSearchHistory,
    }
end, function(dispatch)
    return {
        setColor = function(newColor)
            dispatch({
                type = Enums.StoreActionType.ColorEditor_SetColor,
                color = newColor
            })
        end,

        setSearchHistory = function(newSearchHistory)
            dispatch({
                type = Enums.StoreActionType.UpdateSessionData,
                slice = {
                    picularSearchHistory = newSearchHistory
                }
            })
        end,
    }
end)(PicularPalette)