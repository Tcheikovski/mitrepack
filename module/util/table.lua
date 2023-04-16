---@class array<T>: { [integer]: T }
---@class dictionnary<T>: { [string]: T }

---@class mitrepack.util.table
local M = {}

---@param tab table<integer|string>
---@return number
function M.length(tab)
    local count = 0
    for _ in pairs(tab) do
        count = count + 1
    end

    return count
end

---@generic T
---@param tab { [integer]: T }
---@param value T
---@return boolean
function M.includes(tab, value)
    for _, v in ipairs(tab) do
        if v == value then
            return true
        end
    end

    return false
end

---@generic T, U
---@param tab1 { [integer]: T }
---@param tab2 { [integer]: U }
---@return { [integer]: T | U }
function M.concat(tab1, tab2)
    local out = {}

    for _, v in ipairs(tab1) do
        table.insert(out, v)
    end

    for _, v in ipairs(tab2) do
        table.insert(out, v)
    end

    return out
end

---@generic T
---@param tab { [integer]: T }
---@param cb fun(value: T, tab: { [integer]: T }): boolean
---@return { [integer]: T }
function M.filter(tab, cb)
    local out = {}

    for _, v in ipairs(tab) do
        if cb(v, tab) then
            out[#out + 1] = v
        end
    end

    return out
end

---@generic T, U
---@param tab { [integer]: T }
---@param cb fun(value: T, i: integer, tab: { [integer]: T }): U
---@return { [integer]: U }
function M.map(tab, cb)
    local out = {}

    for i, v in ipairs(tab) do
        table.insert(out, cb(v, i, tab))
    end

    return out
end

---@generic T
---@param tab { [integer]: T }
---@param cb fun(value: T, tab: { [integer]: T }): boolean
---@return T|nil
---@return number|nil
function M.find(tab, cb)
    for i, v in ipairs(tab) do
        if cb(v, tab) then
            return v, i
        end
    end
end

---@generic T
---@param tab { [integer]: T }
---@param cb fun(value: T, tab: { [integer]: T }): boolean
---@return boolean
function M.some(tab, cb)
    for _, v in ipairs(tab) do
        if cb(v, tab) then
            return true
        end
    end

    return false
end

---@generic T
---@param tab { [integer]: T }
---@param cb fun(value: T, tab: { [integer]: T }): boolean
---@return boolean
function M.every(tab, cb)
    for _, v in ipairs(tab) do
        if cb(v, tab) then
            return false
        end
    end

    return true
end

---@generic T
---@param tab { [string]: T }
---@return { [integer]: string }
function M.keys(tab)
    local keys = {}

    for key in pairs(tab) do
        table.insert(keys, key)
    end

    return keys
end

---@generic T
---@param tab { [string]: T }
---@return { [integer]: T }
function M.values(tab)
    local values = {}

    for _, value in pairs(tab) do
        table.insert(values, value)
    end

    return values
end

---@generic T
---@param tab { [string]: T }
---@return { [integer]: string } keys
---@return { [integer]: T } values
function M.entries(tab)
    local keys = {}
    local values = {}

    for key, value in pairs(tab) do
        table.insert(keys, key)
        table.insert(values, value)
    end

    return keys, values
end

---@generic T:{ [string|number]: any }
---@param tab T
---@return T
function M.clone(tab)
    local out = {}
    for key, value in pairs(tab) do
        out[key] = value
    end

    return out
end

---@generic T:{ [string|number]: any }
---@param tab T
---@return T
function M.cloneDeep(tab)
    local out = {}
    for key, value in pairs(tab) do
        if type(value) == "table" then
            out[key] = M.cloneDeep(value)
        else
            out[key] = value
        end
    end

    setmetatable(out, getmetatable(tab))
    return out
end

return M
