local util = require "mitrepack.util"

---@class mitrepack.contraption.AdvancedMotor
---@field private electricMotor electric_motor
---@field private digitalAdapter digital_adapter
---@field private rotationalSpeedControllerSide string
---@field private stressometerSide string
local AdvancedMotor = {}

---@param electricMotorName string
---@param digitalAdapterName string
---@param rotationalSpeedControllerSide string
---@param stressometerSide string
---@return mitrepack.contraption.AdvancedMotor
function AdvancedMotor:new(electricMotorName, digitalAdapterName, rotationalSpeedControllerSide, stressometerSide)
    ---@type mitrepack.contraption.AdvancedMotor
    local advancedMotor = {}

    setmetatable(advancedMotor, self)
    self.__index = self


    advancedMotor.electricMotor = util.peripheral.find("electric_motor", electricMotorName)
    advancedMotor.digitalAdapter = util.peripheral.find("digital_adapter", digitalAdapterName)
    advancedMotor.rotationalSpeedControllerSide = rotationalSpeedControllerSide
    advancedMotor.stressometerSide = stressometerSide

    return advancedMotor
end

---@return electric_motor # The electric_motor wrapped peripheral
function AdvancedMotor:getMotor()
    return self.electricMotor
end

---@return digital_adapter # The digital_adapter wrapped peripheral
---@return string # The rotational speed controller side
---@return string # The stressometer side
function AdvancedMotor:getAdapter()
    return self.digitalAdapter, self.rotationalSpeedControllerSide, self.stressometerSide
end

---@return number
function AdvancedMotor:getInputSpeed()
    return self.electricMotor.getSpeed()
end

---@param rpm number
function AdvancedMotor:setInputSpeed(rpm)
    return self.electricMotor.setSpeed(rpm)
end

---@return number
function AdvancedMotor:getOutputSpeed()
    return self.digitalAdapter.getTargetSpeed(self.rotationalSpeedControllerSide)
end

---@param rpm number
function AdvancedMotor:setOutputSpeed(rpm)
    return self.digitalAdapter.setTargetSpeed(self.rotationalSpeedControllerSide, rpm)
end

---@return number
function AdvancedMotor:getEnergyConsumption()
    return self.electricMotor.getEnergyConsumption()
end

---@return number
function AdvancedMotor:getKineticStress()
    return self.digitalAdapter.getKineticStress(self.stressometerSide)
end

---@return number
function AdvancedMotor:getKineticCapacity()
    return self.digitalAdapter.getKineticCapacity(self.stressometerSide)
end

---@return number|nil
function AdvancedMotor:getKineticImpact()
    local kineticStress = self:getKineticStress()
    local outputSpeed = self:getOutputSpeed()

    if outputSpeed == 0 then
        return nil
    elseif kineticStress == 0 then
        return 0
    else
        return math.abs(kineticStress) / math.abs(outputSpeed)
    end
end

---@return number
function AdvancedMotor:getSpeed()
    return self:getOutputSpeed()
end

---@param rpm number
function AdvancedMotor:setSpeed(rpm)
    rpm = math.max(math.min(rpm, 256), -256)
    if rpm == 0 then
        self:setOutputSpeed(0)
        self:setInputSpeed(0)
    else
        local impact = self:getKineticImpact()
        if not impact then
            self:setInputSpeed(256)
            self:setOutputSpeed(rpm)
            self:setSpeed(rpm)
        elseif impact == 0 then
            self:setInputSpeed(1)
            self:setOutputSpeed(rpm)
        else
            local targetRpm = math.ceil((impact * math.abs(rpm) / self.electricMotor.getStressCapacity()))
            if rpm > self:getOutputSpeed() then
                -- If increasing speed, increase motor speed first to avoid overstress
                self:setInputSpeed(targetRpm)
                self:setOutputSpeed(rpm)
            else
                -- If decreasing speed, decrease motor speed last to avoid overstress
                self:setOutputSpeed(rpm)
                self:setInputSpeed(targetRpm)
            end
        end
    end
end

---@return number|nil
function AdvancedMotor:getKineticOptimization()
    if self:getKineticCapacity() == 0 then return nil end
    return math.floor((self:getKineticStress() / self:getKineticCapacity()) * 100)
end

---@return number|nil
function AdvancedMotor:getMaxSpeed()
    local impact = self:getKineticImpact()
    if not impact then return nil end
    if impact == 0 then return 256 end
    local maxCapacity = self.electricMotor.getStressCapacity() * 256
    return math.min(math.floor(maxCapacity / impact), 256)
end

return AdvancedMotor
