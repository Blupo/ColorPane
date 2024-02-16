--!strict
-- Provides an interface for working with DockWidgetPluginGuis

local Common = script.Parent.Parent

local Includes = Common.Includes

local RoactRoduxFolder = Includes.RoactRodux
local Roact = require(RoactRoduxFolder.Roact)
local RoactRodux = require(RoactRoduxFolder.RoactRodux)
local Rodux = require(RoactRoduxFolder.Rodux)

local Signal = require(Includes.Signal)

local PluginModules = Common.PluginModules
local PluginProvider = require(PluginModules.PluginProvider)

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
        Opens the window
        @param self The window to open
    ]]
    open: (Window) -> (),

    --[[
        Closes the window
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
        Returns if the window is open
        @param self The window to check
        @return If the window is open (`true`) or not (`false`)
    ]]
    isOpen: (Window) -> boolean,
}

export type Window = typeof(setmetatable(
    {}::{
        __tree: any,
        __window: DockWidgetPluginGui,

        --[[
            Marks if the window has been destroyed.
        ]]
        destroyed: boolean,

        --[[
            An event that fires when the window is opened without having a mounted element
        ]]
        openedWithoutMounting: Signal.Signal<nil>,

        --[[
            An event that fires when the window is closed without unmounting its element
        ]]
        closedWithoutUnmounting: Signal.Signal<nil>,
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
    
    local self = {
        __tree = nil,
        __window = window,

        destroyed = false,
        openedWithoutMounting = openedWithoutMounting,
        closedWithoutUnmounting = closedWithoutUnmounting,
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