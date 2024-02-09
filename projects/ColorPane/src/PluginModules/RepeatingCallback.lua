--!strict

local HttpService: HttpService = game:GetService("HttpService")
local RunService: RunService = game:GetService("RunService")

---

local root = script.Parent.Parent
local Common = root.Common

local CommonPluginModules = Common.PluginModules
local PluginProvider = require(CommonPluginModules.PluginProvider)

local CommonIncludes = Common.Includes
local Promise = require(CommonIncludes.Promise)

local PluginModules = root.PluginModules
local Util = require(PluginModules.Util)

---

local plugin: Plugin? = PluginProvider()
assert(plugin, Util.makeBugMessage("Plugin object is missing"))

local ABSOLUTE_MIN_DELTA: number = 1/60
local DEFAULT_DELTA: number = 0.25

local repeaters = {}

---

local RepeatingCallback = {}

RepeatingCallback.new = function(callback: () -> nil, initialDelta: number?, optionalMinDelta: number?)
    local minDelta: number = optionalMinDelta or ABSOLUTE_MIN_DELTA
    minDelta = (minDelta >= ABSOLUTE_MIN_DELTA) and minDelta or ABSOLUTE_MIN_DELTA

    local delta: number = initialDelta or DEFAULT_DELTA
    delta = if (delta >= minDelta) then delta else minDelta

    local id: string = HttpService:GenerateGUID()

    local self = setmetatable({
        id = id,
        active = false,
        repeating = false,
        sustained = 0,
        lastRepeat = 0,

        initialDelta = delta,
        minDelta = minDelta,
        actualDelta = delta,

        callback = callback,
    }, { __index = RepeatingCallback })

    repeaters[id] = self
    return self
end

RepeatingCallback.start = function(self)
    self.active = true
    self.delayPromise = Promise.delay(0.5)
    
    self.delayPromise:andThen(function()
        if (not self.active) then return end

        self.repeating = true
    end):finally(function()
        self.delayPromise = nil
    end)

    self.callback()
end

RepeatingCallback.stop = function(self)
    if (not self.active) then return end

    if (self.delayPromise) then
        self.delayPromise:cancel()
    end

    self.active = false
    self.repeating = false
    self.sustained = 0
    self.actualDelta = self.initialDelta
end

RepeatingCallback.destroy = function(self)
    setmetatable(self, nil)
    repeaters[self.id] = nil
end

---

local repeaterEvent = RunService.Heartbeat:Connect(function(step)
    for _, repeater in pairs(repeaters) do
        if (repeater.repeating) then
            repeater.sustained = repeater.sustained + step

            -- invoke callback
            local now = os.clock()

            if ((now - repeater.lastRepeat) > repeater.actualDelta) then
                repeater.lastRepeat = now
                repeater.callback()
            end
            
            -- decrease delta
            local sustained = repeater.sustained
            local initialDelta = repeater.initialDelta
            
            if ((sustained > 1) and (sustained <= 5)) then
                repeater.actualDelta = math.max(initialDelta - (math.log(sustained + 1) * 0.5 * initialDelta), repeater.minDelta)
            end
        end
    end
end)

plugin.Unloading:Connect(function()
    repeaterEvent:Disconnect()
end)

return RepeatingCallback