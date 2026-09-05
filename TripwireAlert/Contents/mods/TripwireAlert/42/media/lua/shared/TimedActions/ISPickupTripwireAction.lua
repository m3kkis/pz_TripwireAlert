require "TimedActions/ISBaseTimedAction"

ISPickupTripwireAction = ISBaseTimedAction:derive("ISPickupTripwireAction")

function ISPickupTripwireAction:isValid()
    if not TripwireAlert.isTileValid(self.object) then
        return false
    end
    if self.object:getModData().broken and not TripwireAlert.findWire(self.character) then
        return false
    end
    return true
end

function ISPickupTripwireAction:update()
    self.character:faceThisObject(self.object)
end

function ISPickupTripwireAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    self:setOverrideHandModels(nil, nil)
end

function ISPickupTripwireAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISPickupTripwireAction:perform()
    ISBaseTimedAction.perform(self)
end

function ISPickupTripwireAction:complete()
    if not TripwireAlert.isTileValid(self.object) then
        return false
    end
    if self.object:getModData().broken and not TripwireAlert.consumeWire(self.character) then
        return false
    end
    TripwireAlert.removeGroup(self.object, self.character)
    return true
end

function ISPickupTripwireAction:getDuration()
    return TripwireAlert.getActionTime(self.character)
end

function ISPickupTripwireAction:new(character, object)
    local o = ISBaseTimedAction.new(self, character)
    o.object = object
    o.maxTime = o:getDuration()
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end
