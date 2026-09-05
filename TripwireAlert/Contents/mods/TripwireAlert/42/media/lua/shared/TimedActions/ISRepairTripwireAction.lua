require "TimedActions/ISBaseTimedAction"

ISRepairTripwireAction = ISBaseTimedAction:derive("ISRepairTripwireAction")

function ISRepairTripwireAction:isValid()
    return TripwireAlert.isTileValid(self.object)
        and self.object:getModData().broken
        and TripwireAlert.findWire(self.character) ~= nil
end

function ISRepairTripwireAction:update()
    self.character:faceThisObject(self.object)
end

function ISRepairTripwireAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    self:setOverrideHandModels(nil, nil)
end

function ISRepairTripwireAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISRepairTripwireAction:perform()
    ISBaseTimedAction.perform(self)
end

function ISRepairTripwireAction:complete()
    if not TripwireAlert.isTileValid(self.object) or not self.object:getModData().broken then
        return false
    end
    if not TripwireAlert.consumeWire(self.character) then
        return false
    end
    TripwireAlert.repairGroup(self.object)
    return true
end

function ISRepairTripwireAction:getDuration()
    return TripwireAlert.getActionTime(self.character)
end

function ISRepairTripwireAction:new(character, object)
    local o = ISBaseTimedAction.new(self, character)
    o.object = object
    o.maxTime = o:getDuration()
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end
