require "TimedActions/ISBaseTimedAction"

ISDisarmTripwireAction = ISBaseTimedAction:derive("ISDisarmTripwireAction")

function ISDisarmTripwireAction:isValid()
    return TripwireAlert.isTileValid(self.object)
        and self.object:getModData().armed
        and not self.object:getModData().broken
end

function ISDisarmTripwireAction:update()
    self.character:faceThisObject(self.object)
end

function ISDisarmTripwireAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    self:setOverrideHandModels(nil, nil)
end

function ISDisarmTripwireAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISDisarmTripwireAction:perform()
    ISBaseTimedAction.perform(self)
end

function ISDisarmTripwireAction:complete()
    if not self:isValid() then
        return false
    end
    TripwireAlert.setGroupArmed(self.object, false)
    return true
end

function ISDisarmTripwireAction:getDuration()
    return TripwireAlert.getActionTime(self.character)
end

function ISDisarmTripwireAction:new(character, object)
    local o = ISBaseTimedAction.new(self, character)
    o.object = object
    o.maxTime = o:getDuration()
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end
