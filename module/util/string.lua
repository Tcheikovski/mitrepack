---@class mitrepack.util.string
local M = {}

---@param str string
---@param prefix string
---@return boolean
function M.startsWith(str, prefix)
    return str:sub(1, #prefix) == prefix
end

---@param str string
---@param suffix string
---@return boolean
function M.endsWith(str, suffix)
    return suffix == "" or str:sub(- #suffix) == suffix
end

return M
