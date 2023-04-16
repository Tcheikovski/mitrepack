local e = require "cc.expect"

---@class mitrepack.util.peripheral
local M = {}

---@generic T : cc.peripheral
---@param type `T`|cc.peripherals
---@param name? string
---@param level? integer
---@return T
function M.find(type, name, level)
    type = e.expect(1, type, "string")
    name = e.expect(2, name, "string", "nil")
    level = e.expect(3, level, "number", "nil") or 2

    if name then
        if not peripheral.isPresent(name) then
            error("\"" .. name .. "\" peripheral not attached.", level)
        end

        if not peripheral.hasType(name, type) then
            error("\"" .. name .. "\" peripheral is not a valid " .. type .. ".", level)
        end

        return peripheral.wrap(name)
    else
        local result = peripheral.find(type)

        if not result then
            error("No " .. type .. " peripheral attached on this computer.", level)
        end

        return result
    end
end

return M
