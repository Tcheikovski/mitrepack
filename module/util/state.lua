local class = require "mitrepack.util.class"

---@class mitrepack.State<T> : mitrepack.Class, { get: fun(self: self): T|nil; set: fun(self: self, v: T): nil }
---@field private path string
local State = class.create()

---@generic T
---@param name string
---@param defaultValue? T
---@return mitrepack.State<T>
function State:create(name, defaultValue)
    local state = self:new() --[[@as mitrepack.State]]
    local path = "/.mitrepack/" .. name .. ".state"
    state.path = path

    if not fs.isDir('/.mitrepack') then
        fs.makeDir("/.mitrepack")

        if not fs.exists(state.path) and defaultValue then
            state:set(defaultValue)
        end
    end

    return state
end

---@return any|nil
function State:get()
    if not fs.exists(self.path) then return nil end
    local file = fs.open(self.path, "r") --[[@as ReadHandle]]
    local text = file.readAll() --[[@as string]]
    file.close()

    return textutils.unserialise(text)
end

---@param data any
function State:set(data)
    local file = fs.open(self.path, "w") --[[@as WriteHandle]]
    local text = textutils.serialise(data)
    file.write(text)
    file.close()
end

return State
