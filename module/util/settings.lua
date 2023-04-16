---@class mitrepack.util.settings
local M = {}

---@generic T
---@param setting string
---@param parseFn fun(val: string): T
---@return T
function M.validateSetting(setting, parseFn)
    local value = settings.get(setting)
    if value ~= nil then
        return value
    end
    _G.term.clear()
    term.setCursorPos(1, 1)
    term.write("\"" .. setting .. "\":")
    term.setCursorPos(1, 2)
    value = read()
    if parseFn then value = parseFn(value) end
    settings.set(setting, value)
    settings.save()
    return value
end

return M
