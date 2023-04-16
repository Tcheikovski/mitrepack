local util = require "mitrepack.util"

---@class mitrepack.event
local M = {
    EMITTER_IDS = 0,
    EMITTER_PREFIX = 'emitter_',
}

---@alias mitrepack.event.Handler fun(...): nil

---@class mitrepack.event.Emitter : mitrepack.Class
---@field protected id number
---@field protected handlers dictionnary<array<mitrepack.event.Handler>>
local Emitter = util.class.create()

function Emitter:create()
    ---@type mitrepack.event.Emitter
    local emitter = self:new()

    M.EMITTER_IDS = M.EMITTER_IDS + 1
    emitter.id = M.EMITTER_IDS
    emitter.handlers = {}

    return emitter
end

---@param event string
---@param handler mitrepack.event.Handler
function Emitter:addHandler(event, handler)
    local customEvent = M.EMITTER_PREFIX .. event
    self.handlers[customEvent] = self.handlers[customEvent] or {}
    table.insert(self.handlers[customEvent], function(...)
        handler(...)
    end)
end

---@param event event
---@param handler mitrepack.event.Handler
function Emitter:addRawHandler(event, handler)
    self.handlers[event] = self.handlers[event] or {}
    table.insert(self.handlers[event], function(...)
        handler(...)
    end)
end

---@param event string
---@param ... any
function Emitter:dispatch(event, ...)
    local customEvent = M.EMITTER_PREFIX .. event
    os.queueEvent(customEvent, self.id, ...)
end

---@param event string
---@return ...
function Emitter:await(event)
    if util.string.startsWith(event, M.EMITTER_PREFIX) then
        while true do
            local e = { os.pullEvent(event) }
            if e[2] == self.id then
                return table.unpack(e, 3)
            end
        end
    else
        return os.pullEvent(event)
    end
end

function Emitter:listen()
    local events = util.table.keys(self.handlers)
    local eventHandlers = util.table.map(events, function(ev)
        return function()
            while true do
                local payload = { self:await(ev) }
                local handlers = util.table.map(self.handlers[ev], function(handler)
                    return function() handler(table.unpack(payload)) end
                end)

                parallel.waitForAll(table.unpack(handlers))
            end
        end
    end)

    parallel.waitForAny(table.unpack(eventHandlers))
end

M.Emitter = Emitter

return M
