local KIT_TYPE = "TripwireAlert.TripwireKit"

local function getClickedItem(items)
    local entry = items[1]
    if not entry then
        return nil
    end
    if instanceof(entry, "InventoryItem") then
        return entry
    end
    return entry.items[1]
end

local function onPlaceTripwire(item, playerNum)
    if not TripwireBO then
        return
    end
    local player = getSpecificPlayer(playerNum)
    local cursor = TripwireBO:new(player, item)
    getCell():setDrag(cursor, playerNum)
end

local function onFillInventoryMenu(playerNum, context, items)
    local item = getClickedItem(items)
    if not item or item:getFullType() ~= KIT_TYPE then
        return
    end

    context:addOption(getText("ContextMenu_TripwireAlert_Place"), item, onPlaceTripwire, playerNum)
    context:removeOptionByName(getText("ContextMenu_PlaceItemOnGround"))
end

local function findTripwire(worldobjects)
    for _, obj in ipairs(worldobjects) do
        if obj and obj.getModData and obj:getModData().isTripwire then
            return obj
        end
    end

    local first = worldobjects[1]
    if not first or not first.getSquare then
        return nil
    end

    local square = first:getSquare()
    if not square then
        return nil
    end

    local specials = square:getSpecialObjects()
    for i = 0, specials:size() - 1 do
        local obj = specials:get(i)
        if obj:getModData().isTripwire then
            return obj
        end
    end
    return nil
end

local function onArmTripwire(worldobjects, object, player)
    if luautils.walkAdj(player, object:getSquare()) then
        ISTimedActionQueue.add(ISArmTripwireAction:new(player, object))
    end
end

local function onDisarmTripwire(worldobjects, object, player)
    if luautils.walkAdj(player, object:getSquare()) then
        ISTimedActionQueue.add(ISDisarmTripwireAction:new(player, object))
    end
end

local function onPickupTripwire(worldobjects, object, player)
    if luautils.walkAdj(player, object:getSquare()) then
        ISTimedActionQueue.add(ISPickupTripwireAction:new(player, object))
    end
end

local function onRepairTripwire(worldobjects, object, player)
    if luautils.walkAdj(player, object:getSquare()) then
        ISTimedActionQueue.add(ISRepairTripwireAction:new(player, object))
    end
end

local function onFillWorldMenu(playerNum, context, worldobjects, test)
    local object = findTripwire(worldobjects)
    if not object then
        return
    end

    local player = getSpecificPlayer(playerNum)
    local md = object:getModData()
    if md.broken then
        local option = context:addOption(getText("ContextMenu_TripwireAlert_Repair"), worldobjects, onRepairTripwire, object, player)
        if not TripwireAlert.findWire(player) then
            option.notAvailable = true
            local tooltip = ISWorldObjectContextMenu.addToolTip()
            tooltip.description = getText("ContextMenu_TripwireAlert_NeedWire")
            option.toolTip = tooltip
        end
    elseif md.armed then
        context:addOption(getText("ContextMenu_TripwireAlert_Disarm"), worldobjects, onDisarmTripwire, object, player)
    else
        context:addOption(getText("ContextMenu_TripwireAlert_Arm"), worldobjects, onArmTripwire, object, player)
    end
    local pickup = context:addOption(getText("ContextMenu_TripwireAlert_Pickup"), worldobjects, onPickupTripwire, object, player)
    if md.broken then
        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText("ContextMenu_TripwireAlert_NeedWire")
        pickup.toolTip = tooltip
        if not TripwireAlert.findWire(player) then
            pickup.notAvailable = true
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryMenu)
Events.OnFillWorldObjectContextMenu.Add(onFillWorldMenu)