require "TimedActions/ISBaseTimedAction"

ISArmTripwireAction = ISBaseTimedAction:derive("ISArmTripwireAction")

function ISArmTripwireAction:isValid()
    return TripwireAlert.isTileValid(self.object)
        and not self.object:getModData().armed
        and not self.object:getModData().broken
end

function ISArmTripwireAction:update()
    self.character:faceThisObject(self.object)
end

function ISArmTripwireAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    self:setOverrideHandModels(nil, nil)
end

function ISArmTripwireAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISArmTripwireAction:perform()
    ISBaseTimedAction.perform(self)
end

function ISArmTripwireAction:complete()
    if not self:isValid() then
        return false
    end
    TripwireAlert.setGroupArmed(self.object, true)
    return true
end

function ISArmTripwireAction:getDuration()
    return TripwireAlert.getActionTime(self.character)
end

function ISArmTripwireAction:new(character, object)
    local o = ISBaseTimedAction.new(self, character)
    o.object = object
    o.maxTime = o:getDuration()
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end
