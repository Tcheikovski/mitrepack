---@class mitrepack.util.class
local M = {}

---@class mitrepack.Class
---@field new fun(): table

---@param super? mitrepack.Class
---@return mitrepack.Class
function M.create(super)
    local class = {}

    function class:new()
        local instance = {}
        setmetatable(instance, { __index = self })
        return instance
    end

    if super then
        setmetatable(class, { __index = super })
    end

    return class
end

return M
