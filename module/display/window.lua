local util = require "mitrepack.util"
local Screen = require "mitrepack.display.screen"

---@class mitrepack.display.Window : mitrepack.display.Screen
---@field protected redirect window.Window
---@field protected parent mitrepack.display.Screen | mitrepack.display.Window
local Window = util.class.create(Screen)

---@param parent mitrepack.display.Screen | mitrepack.display.Window
---@param x number
---@param y number
---@param width number
---@param height number
---@param backgroundColor? number
---@param textColor? number
---@param visible? boolean
---@return mitrepack.display.Window
function Window:create(parent, x, y, width, height, backgroundColor, textColor, visible)
    local w = window.create(parent.redirect, x, y, width, height, visible)
    local win = Screen.create(self, w, backgroundColor, textColor) --[[@as mitrepack.display.Window]]

    win.parent = parent
    win.x = parent.x + x - 1
    win.y = parent.y + y - 1

    return win
end

function Window:isTerminal()
    return self.parent:isTerminal()
end

function Window:isMonitor()
    return self.parent:isMonitor()
end

function Window:getName()
    return self.parent:getName()
end

return Window
