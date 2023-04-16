local Window = require "mitrepack.display.window"
local util = require "mitrepack.util"
local event = require "mitrepack.event"

---@alias mitrepack.display.UI.state dictionnary<any>
---@alias mitrepack.display.UI.event
---| 'ui_started'
---| 'ui_update'
---| 'gui_draw'
---| 'gui_touch'

---@alias mitrepack.display.UI.factory<T> fun(state: mitrepack.display.UI.state, rootState: mitrepack.display.UI.state): T
---@alias mitrepack.display.GUI.canvas mitrepack.display.Screen | mitrepack.display.Window

---@class mitrepack.display.UI : mitrepack.event.Emitter, mitrepack.Class
---@field package parent mitrepack.display.UI | nil
---@field package rootState mitrepack.display.UI.state
---@field package state mitrepack.display.UI.state
---@field package uis array<mitrepack.display.UI>
---@field package dispatch fun(self: self, event: mitrepack.display.UI.event, ...): nil
local UI = util.class.create(event.Emitter)

---@package
---@param parent? mitrepack.display.UI
---@return mitrepack.display.UI
function UI:create(parent)
    local ui = event.Emitter.create(self) --[[@as mitrepack.display.UI]]

    ui.parent = parent
    ui.rootState = parent and parent.rootState or {}
    ui.state = {}
    ui.uis = {}

    ui:onStarted(function()
        ui:update()
    end)

    ui:onUpdate(function()
        for _, cui in ipairs(ui.uis) do
            cui:update()
        end
    end)

    return ui
end

function UI:start()
    local childHandles = util.table.map(self.uis, function(ui)
        return function() ui:start() end
    end)

    parallel.waitForAny(function()
        self:listen()
    end, function()
        self:dispatch('ui_started')
        while true do
            self:await('ui_update')
        end
    end, table.unpack(childHandles))
end

function UI:update()
    self:dispatch("ui_update")
end

---@param cb fun(state: mitrepack.display.UI.state, rootState: mitrepack.display.UI.state): nil
function UI:onStarted(cb)
    self:addHandler("ui_started", function()
        cb(self.state, self.rootState)
    end)
end

---@param cb fun(state: mitrepack.display.UI.state, rootState: mitrepack.display.UI.state): nil
function UI:onUpdate(cb)
    self:addHandler("ui_update", function()
        cb(self.state, self.rootState)
    end)
end

---@package
---@generic T
---@param hint `T`
---@param value T|mitrepack.display.UI.factory<T>
---@return T
function UI:getValue(hint, value)
    return util.factory.getValue(value, self.state, self.rootState)
end

---@package
---@param ui mitrepack.display.UI
function UI:addChild(ui)
    table.insert(self.uis, ui)
end

---@class mitrepack.display.GUI : mitrepack.display.UI, mitrepack.Class
---@field package canvas mitrepack.display.GUI.canvas
local GUI = util.class.create(UI)

---@package
---@param canvas mitrepack.display.GUI.canvas
---@param parent? mitrepack.display.UI
---@param backgroundColor? number
---@param textColor? number
---@return mitrepack.display.GUI
function GUI:create(canvas, parent, backgroundColor, textColor)
    local gui = UI.create(self, parent) --[[@as mitrepack.display.GUI]]

    gui.canvas = canvas

    canvas:defineBackgroundColor(backgroundColor or canvas.backgroundColor)
    canvas:defineTextColor(textColor or canvas.textColor)

    gui:onUpdate(function()
        gui:draw()
    end)

    gui:onDraw(function()
        for _, cui in ipairs(gui.uis) do
            ---@cast cui mitrepack.display.GUI
            if cui.draw then cui:draw() end
        end
    end)

    if canvas:isMonitor() then
        gui:addRawHandler("monitor_touch", function(_, monitorName, mx, my)
            if monitorName == canvas:getName() and canvas:contains(mx, my) then
                local rx, ry = mx - canvas.x + 1, my - canvas.y + 1
                gui:touch(rx, ry)
            end
        end)
    end

    return gui
end

function GUI:draw()
    self.canvas:clear()
    self:dispatch("gui_draw")
end

---@param rx number
---@param ry number
function GUI:touch(rx, ry)
    self:dispatch("gui_touch", rx, ry)
end

---@param cb fun(canvas: mitrepack.display.GUI.canvas, state: mitrepack.display.UI.state, rootState: mitrepack.display.UI.state): nil
function GUI:onDraw(cb)
    self:addHandler("gui_draw", function()
        cb(self.canvas, self.state, self.rootState)
    end)
end

---@param cb fun(state: mitrepack.display.UI.state, rootState: mitrepack.display.UI.state, mx: number, my: number)
function GUI:onClick(cb)
    self:addHandler('gui_touch', function(mx, my)
        cb(self.state, self.rootState, mx, my)
    end)
end

---@param x integer
---@param y integer
---@param width integer
---@param height integer
---@param backgroundColor? integer
---@param textColor? integer
---@return mitrepack.display.GUI
function GUI:pannel(x, y, width, height, backgroundColor, textColor)
    local win = Window:create(self.canvas, x, y, width, height, backgroundColor, textColor)
    local pannel = GUI:create(win, self)
    self:addChild(pannel)

    return pannel
end

---@param text string
---@param x number
---@param y number
---@param px? number
---@param py? number
---@param backgroundColor? number
---@param textColor? number
function GUI:button(text, x, y, px, py, backgroundColor, textColor)
    local width = text:len() + (px or 1) * 2
    local height = 1 + (py or 1) * 2

    local but = self:pannel(x, y, width, height, backgroundColor, textColor)
    but:text(text, 1 + (py or 0), 1 + (px or 0))

    return but
end

---@class mitrepack.display.GUI.TextStyle
---@field align mitrepack.display.TextAlignment | mitrepack.display.UI.factory<mitrepack.display.TextAlignment> | nil
---@field color integer | mitrepack.display.UI.factory<integer> | nil
---@field background integer | mitrepack.display.UI.factory<integer> | nil

---@param text string|mitrepack.display.UI.factory<string>
---@param line integer|mitrepack.display.UI.factory<integer>
---@param margin? integer|mitrepack.display.UI.factory<integer>
---@param style? mitrepack.display.GUI.TextStyle
function GUI:text(text, line, margin, style)
    style = style or {}
    local align = style.align or "left"
    local color = style.color or self.canvas.textColor
    local background = style.background or self.canvas.backgroundColor

    self:onDraw(function(canvas)
        local textOutput = self:getValue('string', text)
        local lineOutput = self:getValue('integer', line)
        local marginOutput = self:getValue('integer', margin or 1)
        local alignOutput = self:getValue('mitrepack.display.TextAlignment', align)
        local textColorOutput = self:getValue('integer', color)
        local backgroundColorOutput = self:getValue('integer', background)
        canvas:text(textOutput, lineOutput, marginOutput, alignOutput, textColorOutput, backgroundColorOutput)
    end)
end

---@class mitrepack.display.GUI.FieldStyle
---@field background integer | mitrepack.display.UI.factory<integer> | nil
---@field labelColor integer | mitrepack.display.UI.factory<integer> | nil
---@field textColor integer | mitrepack.display.UI.factory<integer> | nil

---@param label string|mitrepack.display.UI.factory<string>
---@param text string|mitrepack.display.UI.factory<string>
---@param line integer|mitrepack.display.UI.factory<integer>
---@param style? mitrepack.display.GUI.FieldStyle
---@param labelMargin? integer|mitrepack.display.UI.factory<integer>
---@param textMargin? integer|mitrepack.display.UI.factory<integer>
---@return self
function GUI:field(label, text, line, style, labelMargin, textMargin)
    style = style or {}
    self:text(label, line, labelMargin, { align = "left", background = style.background, color = style.labelColor })
    self:text(text, line, textMargin or labelMargin,
        { align = "right", background = style.background, color = style.textColor })

    return self
end

---@param x integer|mitrepack.display.UI.factory<integer>
---@param y integer|mitrepack.display.UI.factory<integer>
---@param width integer|mitrepack.display.UI.factory<integer>
---@param height integer|mitrepack.display.UI.factory<integer>
---@param color integer|mitrepack.display.UI.factory<integer>
function GUI:box(x, y, width, height, color)
    self:onDraw(function(canvas)
        local xOutput = self:getValue("integer", x)
        local yOutput = self:getValue("integer", y)
        local widthOutput = self:getValue("integer", width)
        local heightOutput = self:getValue("integer", height)
        local colorOutput = self:getValue("integer", color)

        if widthOutput > 0 and heightOutput > 0 then
            canvas:box(xOutput, yOutput, widthOutput, heightOutput, colorOutput, true)
        end
    end)
end

---@alias mitrepack.display.UI.Direction 'horizontal'|'vertical'

---@param min number|mitrepack.display.UI.factory<number>
---@param max number|mitrepack.display.UI.factory<number>
---@param value number|mitrepack.display.UI.factory<number>
---@param x integer|mitrepack.display.UI.factory<integer>
---@param y integer|mitrepack.display.UI.factory<integer>
---@param width integer|mitrepack.display.UI.factory<integer>
---@param height integer|mitrepack.display.UI.factory<integer>
---@param direction mitrepack.display.UI.Direction|mitrepack.display.UI.factory<mitrepack.display.UI.Direction>
---@param gaugeColor integer|mitrepack.display.UI.factory<integer>
---@param backgroundColor integer|mitrepack.display.UI.factory<integer>
function GUI:gauge(min, max, value, x, y, width, height, direction, gaugeColor, backgroundColor)
    local function getSize()
        local dir = self:getValue("mitrepack.display.UI.Direction", direction)
        local val = self:getValue('number', value)
        local inMin = self:getValue('number', min)
        local inMax = self:getValue('number', max)
        local w = self:getValue('number', width)
        local h = self:getValue('number', height)

        if dir == 'horizontal' then
            w = util.math.mapRange(val, inMin, inMax, 0, w, true)
        elseif dir == 'vertical' then
            h = util.math.mapRange(val, inMin, inMax, 0, h, true)
        end

        return { width = w, height = h }
    end

    self:box(x, y, width, height, backgroundColor)
    self:box(x, y, function() return getSize().width end, function() return getSize().height end, gaugeColor)
end

---@param screen mitrepack.display.Screen
---@return mitrepack.display.GUI
function GUI.fromScreen(screen)
    return GUI:create(screen)
end

return GUI
