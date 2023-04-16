local e = require "cc.expect"
local util = require "mitrepack.util"

---@class mitrepack.display.Screen : mitrepack.Class
---@field protected redirect term.Redirect
---@field x number
---@field y number
---@field width number
---@field height number
---@field backgroundColor number
---@field textColor number
local Screen = util.class.create()

---@param redirect term.Redirect
---@param backgroundColor? number
---@param textColor? number
---@return mitrepack.display.Screen
function Screen:create(redirect, backgroundColor, textColor)
    ---@type mitrepack.display.Screen
    local screen = self:new()

    screen.redirect = redirect

    screen.x, screen.y = 1, 1
    screen.width, screen.height = redirect.getSize()

    screen:defineBackgroundColor(backgroundColor or colors.black)
    screen:defineTextColor(textColor or colors.white)

    screen.redirect.setCursorPos(1, 1)
    screen.redirect.setCursorBlink(false)
    screen.redirect.clear()

    return screen
end

---@return boolean
function Screen:isMonitor()
    local mt = getmetatable(self.redirect)
    if not mt then return false end
    return mt.type == 'monitor'
end

---@return boolean
function Screen:isTerminal()
    return not self:isMonitor()
end

---@return string
function Screen:getName()
    local mt = getmetatable(self.redirect)
    return mt and mt.name or ''
end

---@param x integer
---@param y integer
---@return boolean
function Screen:contains(x, y)
    local x1, x2 = self.x, self.x + self.width - 1
    local y1, y2 = self.y, self.y + self.height - 1
    return x >= x1 and x <= x2 and y >= y1 and y <= y2
end

---@param backgroundColor number
function Screen:defineBackgroundColor(backgroundColor)
    self.backgroundColor = backgroundColor
    self.redirect.setBackgroundColor(backgroundColor)
end

---@param textColor number
function Screen:defineTextColor(textColor)
    self.textColor = textColor
    self.redirect.setTextColor(textColor)
end

function Screen:clear()
    self.redirect.clear()
end

---@param text string
---@param line number
---@param margin? number
---@param align? mitrepack.display.TextAlignment
---@param textColor? number
---@param backgroundColor? number
function Screen:text(text, line, margin, align, textColor, backgroundColor)
    text = e.expect(1, text, "string")
    line = e.expect(2, line, "number")
    margin = e.expect(3, margin, "number", "nil") or 1
    align = e.expect(4, align, "string", "nil") or "left"
    textColor = e.expect(5, textColor, "number", "nil") or self.textColor
    backgroundColor = e.expect(6, backgroundColor, "number", "nil") or self.backgroundColor

    local x, y = margin, line
    if align ~= "left" then
        local offset = self.width - text:len()
        if align == "center" then
            x = offset / 2 + x
        elseif align == "right" then
            x = offset - x + 2
        end
    end

    local restore = self:saveState()

    self.redirect.setTextColor(textColor)
    self.redirect.setBackgroundColor(backgroundColor)
    self.redirect.setCursorPos(x, y)
    self.redirect.write(text)

    restore()
end

---@param x number
---@param y number
---@param width number
---@param height number
---@param color number
---@param filled? boolean
function Screen:box(x, y, width, height, color, filled)
    local args = { x, y, x + width - 1, y + height - 1, color }

    local restore = self:saveState()

    if filled == true then
        paintutils.drawFilledBox(table.unpack(args))
    else
        paintutils.drawBox(table.unpack(args))
    end

    restore()
end

---@param x number
---@param y number
---@param image table
function Screen:image(x, y, image)
    local restore = self:saveState()

    paintutils.drawImage(image, x, y)

    restore()
end

---@param x number
---@param y number
---@param replaceChar? string
---@param history? table<string>
---@param completeFn? fun(partial: string): table<string>|nil
---@param default? string
function Screen:prompt(x, y, replaceChar, history, completeFn, default)
    local restore = self:saveState()

    self.redirect.setCursorPos(x, y)
    local value = read(replaceChar, history, completeFn, default)

    restore()

    return value
end

---@private
function Screen:saveState()
    local r = self.redirect
    local x, y = r.getCursorPos()
    local blink = r.getCursorBlink()
    local backgroundColor = r.getBackgroundColor()
    local textColor = r.getTextColor()
    local origin = term.redirect(r)

    return function()
        r.setCursorPos(x, y)
        r.setCursorBlink(blink)
        r.setBackgroundColor(backgroundColor)
        r.setTextColor(textColor)
        term.redirect(origin)
    end
end

---@param terminal? term.Redirect
---@param backgroundColor? number
---@param textColor? number
function Screen.fromTerminal(terminal, backgroundColor, textColor)
    terminal = terminal or term.current()
    return Screen:create(terminal, backgroundColor, textColor)
end

---@param monitor? monitor|string
---@param scale? number
---@param backgroundColor? number
---@param textColor? number
function Screen.fromMonitor(monitor, scale, backgroundColor, textColor)
    if not monitor then
        monitor = util.peripheral.find("monitor")
    elseif type(monitor) == "string" then
        monitor = util.peripheral.find("monitor", monitor)
    end

    if scale then
        monitor.setTextScale(scale)
    end

    return Screen:create(monitor, backgroundColor, textColor)
end

return Screen
