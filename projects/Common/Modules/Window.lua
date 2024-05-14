--!strict
-- Provides an interface for working with DockWidgetPluginGuis

local RunService: RunService = game:GetService("RunService")

---

local Common = script.Parent.Parent
local Includes = Common.Includes

local RoactRoduxFolder = Includes.RoactRodux
local Roact = require(RoactRoduxFolder.Roact)
local RoactRodux = require(RoactRoduxFolder.RoactRodux)
local Rodux = require(RoactRoduxFolder.Rodux)

local Signal = require(Includes.Signal)

local Modules = Common.Modules
local PluginProvider = require(Modules.PluginProvider)

---

type Element = typeof(Roact.createElement())
type Store = typeof(Rodux.Store.new())

type WindowImpl = {
    __index: WindowImpl,

    --[[
        Creates a new Window

        @param id The window ID
        @param widgetInfo The window info
        @return A new window
    ]]
    new: (id: string, widgetInfo: DockWidgetPluginGuiInfo) -> Window,

    --[[
        Unmounts the currently-mounted element on the window and closes it

        @param self The window to unmount from
        @param resetTitle (Optional) Reset the plugin gui title
    ]]
    unmount: (Window, boolean?) -> (),

    --[[
        Mounts an element to the window and opens it

        @param self The window to mount to
        @param title The title of the window
        @param element The Roact element to mount to the window
        @param store The Rodux store to provide to Roact
    ]]
    mount: (Window, string, Element, Store) -> (),

    --[[
        Enables mouse tracking for this window.
        No effect if mouse track is already enabled.

        @param self The window to track
    ]]
    enableMouseTracking: (Window) -> (),

    --[[
        Disables mouse tracking for this window.
        No effect if mouse tracking isn't already enabled.

        @param self The window stop stop tracking
    ]]
    disableMouseTracking: (Window) -> (),

    --[[
        Opens the window (makes it visible)

        @param self The window to open
    ]]
    open: (Window) -> (),

    --[[
        Closes the window (make is invisible)

        @param self The window to close
    ]]
    close: (Window) -> (),

    --[[
        Destroys the window.

        No further operations should be done on the Window, as indicated by its `destroyed` field.

        @param self The window to destroy
    ]]
    destroy: (Window) -> (),

    --[[
        Returns if the window has a mounted element

        @param self The window to check
        @return If the window has a mounted element (`true`) or not (`false`)
    ]]
    isMounted: (Window) -> boolean,

    --[[
        Returns if the window is open (visible)

        @param self The window to check
        @return If the window is open (`true`) or not (`false`)
    ]]
    isOpen: (Window) -> boolean,
}

export type Window = typeof(setmetatable(
    {}::{
        __tree: any,
        __window: DockWidgetPluginGui,
        __mousePositionPoll: RBXScriptConnection,
        __lastMousePosition: Vector2,
        __fireMousePositionChanged: Signal.FireSignal<Vector2>,

        --[[
            Marks if the window has been destroyed.
        ]]
        destroyed: boolean,

        --[[
            A signal that fires when the window is opened without having a mounted element
        ]]
        openedWithoutMounting: Signal.Signal<nil>,

        --[[
            A signal that fires when the window is closed without unmounting its element
        ]]
        closedWithoutUnmounting: Signal.Signal<nil>,

        --[[
            A signal that fires when the the mouse position changes,
            and mouse tracking has been enabled for the window
        ]]
        mousePositionChanged: Signal.Signal<Vector2>,
    },

    {}::WindowImpl
))

---

local plugin: Plugin = PluginProvider()

local Window: WindowImpl = {}::WindowImpl
Window.__index = Window

Window.new = function(id: string, widgetInfo: DockWidgetPluginGuiInfo): Window
    local window: DockWidgetPluginGui = plugin:CreateDockWidgetPluginGui(id, widgetInfo)
    local openedWithoutMounting: Signal.Signal<nil>, fireOpenedWithoutMounting: Signal.FireSignal<nil> = Signal.createSignal()
    local closedWithoutUnmounting: Signal.Signal<nil>, fireClosedWithoutUnmounting: Signal.FireSignal<nil> = Signal.createSignal()
    local mousePositionChanged: Signal.Signal<Vector2>, fireMousePositionChanged: Signal.FireSignal<Vector2> = Signal.createSignal()
    
    local self = {
        __tree = nil,
        __window = window,
        __mousePositionPoll = RunService.Heartbeat:Connect(function() end),
        __lastMousePosition = Vector2.new(math.huge, math.huge),
        __fireMousePositionChanged = fireMousePositionChanged,

        destroyed = false,
        openedWithoutMounting = openedWithoutMounting,
        closedWithoutUnmounting = closedWithoutUnmounting,
        mousePositionChanged = mousePositionChanged,
    }

    window:GetPropertyChangedSignal("Enabled"):Connect(function()
        local enabled: boolean = window.Enabled

        if (enabled and (not self.__tree)) then
            fireOpenedWithoutMounting()
        elseif ((not enabled) and self.__tree) then
            fireClosedWithoutUnmounting()
        end
    end)

    window.Name = id
    window.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.__mousePositionPoll:Disconnect()
    return setmetatable(self, Window)
end

Window.unmount = function(self: Window, resetTitle: boolean?)
    if ((self.destroyed) or (not self.__tree)) then return end

    Roact.unmount(self.__tree)
    self.__tree = nil

    local window: DockWidgetPluginGui = self.__window
    window.Enabled = false
    
    if (resetTitle) then
        window.Title = ""
    end
end

Window.mount = function(self: Window, title: string, component: Element, store: Store)
    if ((self.destroyed) or (self.__tree)) then return end

    local window: DockWidgetPluginGui = self.__window

    self.__tree = Roact.mount(Roact.createElement(RoactRodux.StoreProvider, {
        store = store
    }, {
        App = component
    }), window)

    window.Title = title
    window.Enabled = true
end

Window.enableMouseTracking = function(self: Window)
    if ((self.destroyed) or (self.__mousePositionPoll.Connected)) then return end

    self.__mousePositionPoll = RunService.Heartbeat:Connect(function()
        local position: Vector2 = self.__window:GetRelativeMousePosition()
        if (position == self.__lastMousePosition) then return end

        self.__lastMousePosition = position
        self.__fireMousePositionChanged(position)
    end)
end

Window.disableMouseTracking = function(self: Window)
    if ((self.destroyed) or (not self.__mousePositionPoll.Connected)) then return end

    self.__mousePositionPoll:Disconnect()
end

Window.open = function(self: Window)
    if (self.destroyed) then return end
    self.__window.Enabled = true
end

Window.close = function(self: Window)
    if (self.destroyed) then return end
    self.__window.Enabled = false
end

Window.destroy = function(self: Window)
    if (self.destroyed) then return end

    if (self.__tree) then
        self:unmount()
    end

    self.__mousePositionPoll:Disconnect()
    self.__window:Destroy()
    self.destroyed = true
end

Window.isMounted = function(self: Window): boolean
    if (self.destroyed) then
        return false
    else
        return if (self.__tree) then true else false
    end
end

Window.isOpen = function(self: Window): boolean
    if (self.destroyed) then
        return false
    else
        return self.__window.Enabled
    end
end

---

return Window