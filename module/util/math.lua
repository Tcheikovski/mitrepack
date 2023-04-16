---@class mitrepack.util.math
local M = {}

---@param min number
---@param max number
---@param value number
---@param clamp? boolean
---@return number
function M.lerp(min, max, value, clamp)
    local result = min + (max - min) * value
    if not clamp then return result end
    return math.min(math.max(result, min), max)
end

---@param value number
---@param inMin number
---@param inMax number
---@param outMin number
---@param outMax number
---@param clamp ?boolean
---@return number
function M.mapRange(value, inMin, inMax, outMin, outMax, clamp)
    local valueScaled = (value - inMin) / (inMax - inMin)
    return M.lerp(outMin, outMax, valueScaled, clamp)
end

---@param value number
---@param decimalPlaces number
---@return number
function M.round(value, decimalPlaces)
    local factor = 10 ^ decimalPlaces
    return math.floor(value * factor + 0.5) / factor
end

return M
