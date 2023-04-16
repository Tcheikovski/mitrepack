---@class mitrepack.util.factory
local M = {}

---@param value any
---@param ... any
---@return any
function M.getValue(value, ...)
    if type(value) == 'function' then
        return value(...)
    else
        return value
    end
end

return M
