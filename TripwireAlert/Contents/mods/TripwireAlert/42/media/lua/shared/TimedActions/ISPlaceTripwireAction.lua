require "TimedActions/ISBaseTimedAction"

ISPlaceTripwireAction = ISBaseTimedAction:derive("ISPlaceTripwireAction")

function ISPlaceTripwireAction:getLayout()
    if self.layout and #self.layout > 0 then
        return self.layout
    end
    if self.layoutStr then
        self.layout = TripwireAlert.decodeLayout(self.layoutStr)
    end
    return self.layout
end

function ISPlaceTripwireAction:isValid()
    local layout = self:getLayout()
    if not self.kit or not layout or #layout < 1 then
        return false
    end
    if isClient() then
        return self.character:getInventory():containsID(self.kit:getID())
    end
    return self.character:getInventory():contains(self.kit)
end

function ISPlaceTripwireAction:update()
    local layout = self:getLayout()
    local tile = layout and layout[1]
    if tile then
        self.character:faceLocation(tile.x, tile.y)
    end
end

function ISPlaceTripwireAction:start()
    if isClient() and self.kit then
        self.kit = self.character:getInventory():getItemById(self.kit:getID())
    end
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    self:setOverrideHandModels(nil, nil)
end

function ISPlaceTripwireAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISPlaceTripwireAction:perform()
    ISBaseTimedAction.perform(self)
end

function ISPlaceTripwireAction:complete()
    return TripwireAlert.placeLine(self.character, self.kit, self:getLayout())
end

function ISPlaceTripwireAction:getDuration()
    if self.character and self.character:isTimedActionInstant() then
        return 1
    end
    return 50
end

function ISPlaceTripwireAction:new(character, kit, layout)
    local o = ISBaseTimedAction.new(self, character)
    o.kit = kit
    o.layout = layout
    o.layoutStr = TripwireAlert.encodeLayout(layout)
    o.maxTime = o:getDuration()
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end
