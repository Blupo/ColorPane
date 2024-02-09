local root = script.Parent.Parent
local Common = root.Common

local CommonPluginModules = Common.PluginModules
local Style = require(CommonPluginModules.Style)

local CommonIncludes = Common.Includes
local Color = require(CommonIncludes.Color).Color
local Roact = require(CommonIncludes.RoactRodux.Roact)
local RoactRodux = require(CommonIncludes.RoactRodux.RoactRodux)

local CommonComponents = Common.Components
local StandardComponents = require(CommonComponents.StandardComponents)

local PluginModules = root.PluginModules
local PluginEnums = require(PluginModules.PluginEnums)
local Util = require(PluginModules.Util)

local Components = root.Components
local Slider = require(Components.Slider)

local StandardUIListLayout = StandardComponents.UIListLayout

---

--[[
    props

        colorSpace: string
        editorKey: string

        componentKeys: array<string>
        componentRanges: dictionary<string, {number, number}>
        componentDisplayRanges: dictionary<string, {number, number}>?
        componentLabels: dictionary<string, string>
        componentUnitLabels: dictionary<string, string>

        componentSliderGradientGenerators: dictionary<string, (dictionary<string, number>) -> ColorSequence>
        sliderMarkerColorGenerators: dictionary<string, (dictionary<string, number>, StudioTheme) -> Color3>?

    store props

        theme: StudioTheme
        color: Color
        editor: string

        setColor: (Color, string) -> nil
]]

local SliderPage = Roact.PureComponent:extend("SliderPage")

SliderPage.init = function(self, initProps)
    local componentKeys = initProps.componentKeys
    local components = { initProps.color:to(initProps.colorSpace) }
    local componentDictionary = {}

    for i = 1, #componentKeys do
        componentDictionary[componentKeys[i]] = components[i]
    end

    self.componentValueToNormal = function(component, value)
        local componentRanges = self.props.componentRanges[component]
        local min, max = componentRanges[1], componentRanges[2]

        return Util.inverseLerp(min, max, value)
    end

    self.componentNormalToValue = function(component, normal)
        local componentRanges = self.props.componentRanges[component]
        local min, max = componentRanges[1], componentRanges[2]

        return Util.lerp(min, max, normal)
    end

    self.componentNormalToDisplay = function(component, normal)
        local componentDisplayRanges = self.props.componentDisplayRanges

        if (not (componentDisplayRanges and componentDisplayRanges[component])) then
            componentDisplayRanges = self.props.componentRanges
        end

        local displayRange = componentDisplayRanges[component]
        local min, max = displayRange[1], displayRange[2]

        return Util.lerp(min, max, normal)
    end

    self.componentNormalToTextFactory = function(component)
        return function(normal)
            return tostring(math.floor(self.componentNormalToDisplay(component, normal)))
        end
    end

    self.componentTextToNormalFactory = function(component)
        return function(text)
            local value = tonumber(text)
            if (not value) then return end
            
            local normal = self.componentValueToNormal(component, value)
            return math.clamp(normal, 0, 1)
        end
    end

    self:setState({
        components = componentDictionary
    })
end

SliderPage.getDerivedStateFromProps = function(props, state)
    if (props.editor == props.editorKey) then return end
    
    if (state.captureFocus) then
        return {
            captureFocus = Roact.None,
        }
    end

    local components = { props.color:to(props.colorSpace) }

    local changed = false
    local newComponentsDictionary = {}

    for i = 1, #components do
        local newComponent = components[i]
        local componentKey = props.componentKeys[i]
        
        if (componentKey == "H") then
            newComponentsDictionary[componentKey] = (newComponent ~= newComponent) and 0 or newComponent
        else
            newComponentsDictionary[componentKey] = newComponent
        end

        if (newComponent ~= state[componentKey]) then
            changed = true
        end
    end

    return changed and {
        components = newComponentsDictionary
    } or nil
end

SliderPage.didUpdate = function(self, prevProps)
    local colorSpace = self.props.colorSpace
    if (colorSpace == prevProps.colorSpace) then return end

    local componentKeys = self.props.componentKeys
    local components = { self.props.color:to(colorSpace) }
    local componentDictionary = {}

    for i = 1, #componentKeys do
        componentDictionary[componentKeys[i]] = components[i]
    end

    self:setState({
        components = componentDictionary
    })
end

SliderPage.render = function(self)
    local theme = self.props.theme
    local colorSpace = self.props.colorSpace
    local editorKey = self.props.editorKey
    local editor = self.props.editor

    local componentKeys = self.props.componentKeys
    local componentLabels = self.props.componentLabels
    local componentUnitLabels = self.props.componentUnitLabels

    local componentSliderGradientGenerators = self.props.componentSliderGradientGenerators
    local sliderMarkerColorGenerators = self.props.sliderMarkerColorGenerators

    local components = self.state.components
    local elements = {}
    local componentsArray = {}

    -- check that the components match
    for i = 1, #componentKeys do
        if (not components[componentKeys[i]]) then
            return
        end
    end

    for i = 1, #componentKeys do
        componentsArray[i] = components[componentKeys[i]]
    end

    for i = 1, #componentKeys do
        local componentKey = componentKeys[i]
        local sliderMarkerColorGenerator = sliderMarkerColorGenerators and sliderMarkerColorGenerators[componentKey] or nil

        elements[componentKey] = Roact.createElement(Slider, {
            LayoutOrder = i,

            sliderLabel = componentLabels[componentKey],
            unitLabel = componentUnitLabels[componentKey],

            value = self.componentValueToNormal(componentKey, components[componentKey]),
            valueToText = self.componentNormalToTextFactory(componentKey),
            textToValue = self.componentTextToNormalFactory(componentKey),

            sliderGradient = componentSliderGradientGenerators[componentKey](components),

            markerColor = sliderMarkerColorGenerator and sliderMarkerColorGenerator(components, theme) or
                Color.from(colorSpace, table.unpack(componentsArray)):bestContrastingColor(
                    Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)),
                    Color.fromColor3(theme:GetColor(Enum.StudioStyleGuideColor.ColorPickerFrame)):invert()
                ):toColor3(),

            valueChanged = function(normal)
                local newComponent = self.componentNormalToValue(componentKey, normal)
                local newComponents = {}
                local newComponentsArray = {}

                for j = 1, #componentKeys do
                    local newComponentKey = componentKeys[j]

                    if (newComponentKey == componentKey) then
                        newComponents[newComponentKey] = newComponent
                        newComponentsArray[j] = newComponent
                    else
                        newComponents[newComponentKey] = components[newComponentKey]
                        newComponentsArray[j] = components[newComponentKey]
                    end
                end

                self:setState({
                    captureFocus = (editor ~= editorKey) and true or nil,
                    components = newComponents,
                })

                self.props.setColor(Color.from(colorSpace, table.unpack(newComponentsArray)), editorKey)
            end
        })
    end

    elements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        Padding = UDim.new(0, Style.Constants.MajorElementPadding),
        
        preset = 1,
    })

    return Roact.createFragment(elements)
end

---

return RoactRodux.connect(function(state)
    return {
        theme = state.theme,
        color = state.colorEditor.color,
        editor = state.colorEditor.authoritativeEditor,
    }
end, function(dispatch)
    return {
        setColor = function(newColor, editor)
            dispatch({
                type = PluginEnums.StoreActionType.ColorEditor_SetColor,
                color = newColor,
                editor = editor
            })
        end
    }
end)(SliderPage)