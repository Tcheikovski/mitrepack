local util = require "mitrepack.util"
local event = require "mitrepack.event"

---@class mitrepack.contraption.Toggle : mitrepack.event.Emitter
---@field protected state mitrepack.State<boolean>
---@field protected motor electric_motor
---@field protected speed integer
local Toggle = util.class.create(event.Emitter)

---@param motorName string
---@param speed integer
---@return mitrepack.contraption.Toggle
function Toggle:create(motorName, speed)
    local toggle = event.Emitter.create(self) --[[@as mitrepack.contraption.Toggle]]
    local name = 'toggle_' .. tostring(toggle.id)

    toggle.state = util.state:create(name, false)
    toggle.motor = util.peripheral.find("electric_motor", motorName)
    toggle.speed = math.min(math.abs(speed), 256)

    return toggle
end

---@return boolean
function Toggle:isOpened()
    return self.state:get() == true
end

---@return boolean
function Toggle:isClosed()
    return self.state:get() ~= true
end

function Toggle:open()
    if self:isOpened() then return end

    os.sleep(self:getOpenTimeout())

    self.motor.stop()
    self.state:set(true)
    self:dispatch('toggle_opened')
end

function Toggle:close()
    if self:isClosed() then return end

    os.sleep(self:getCloseTimeout())

    self.motor.stop()
    self.state:set(false)
    self:dispatch('toggle_closed')
end

function Toggle:toggle()
    if self:isOpened() then
        self:close()
    else
        self:open()
    end
end

---@param cb fun(): nil
function Toggle:onOpened(cb)
    self:addHandler('toggle_opened', function()
        cb()
    end)
end

---@param cb fun(): nil
function Toggle:onClosed(cb)
    self:addHandler('toggle_closed', function()
        cb()
    end)
end

---@protected
function Toggle:getOpenTimeout()
    return 1
end

---@protected
function Toggle:getCloseTimeout()
    return 1
end

---@class mitrepack.contraption.Slide : mitrepack.contraption.Toggle
---@field protected distance integer
local Slide = util.class.create(Toggle)

---@param motorName string
---@param speed integer
---@param distance integer
---@return mitrepack.contraption.Slide
function Slide:create(motorName, speed, distance)
    local slide = Toggle.create(Slide, motorName, speed) --[[@as mitrepack.contraption.Slide]]
    slide.distance = distance

    return slide
end

---@protected
function Slide:getOpenTimeout()
    return self.motor.translate(self.distance, self.speed)
end

---@protected
function Slide:getCloseTimeout()
    return self.motor.translate(self.distance, -self.speed)
end

---@class mitrepack.contraption.Pivot : mitrepack.contraption.Toggle
---@field protected angle integer
local Pivot = util.class.create(Toggle)

---@param motorName string
---@param speed integer
---@param angle integer
---@return mitrepack.contraption.Pivot
function Pivot:create(motorName, speed, angle)
    local pivot = Toggle.create(Pivot, motorName, speed) --[[@as mitrepack.contraption.Pivot]]
    pivot.angle = angle

    return pivot
end

---@protected
function Pivot:getOpenTimeout()
    return self.motor.rotate(self.angle, self.speed)
end

---@protected
function Pivot:getCloseTimeout()
    return self.motor.rotate(self.angle, -self.speed)
end

return {
    Slide = Slide,
    Pivot = Pivot,
}
