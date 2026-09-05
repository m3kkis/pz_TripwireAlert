TripwireAlert = TripwireAlert or {}
TripwireAlert.armed = TripwireAlert.armed or {}
TripwireAlert.watched = TripwireAlert.watched or {}
TripwireAlert.groups = TripwireAlert.groups or {}

TripwireAlert.MAX_LENGTH = 3

TripwireAlert.Sprites = {
    ewLeft = "media/textures/tripwire/tripwire_ew_0.png",
    ewMid = "media/textures/tripwire/tripwire_ew_1.png",
    ewRight = "media/textures/tripwire/tripwire_ew_2.png",
    nsNorth = "media/textures/tripwire/tripwire_ns_2.png",
    nsMid = "media/textures/tripwire/tripwire_ns_1.png",
    nsSouth = "media/textures/tripwire/tripwire_ns_0.png",
    ewSingle = "media/textures/tripwire/tripwire_ew_0.png",
    nsSingle = "media/textures/tripwire/tripwire_ns_0.png",
}

TripwireAlert.Overlays = {
    ewSingle = "media/textures/tripwire/tripwire_end_ew.png",
    nsSingle = "media/textures/tripwire/tripwire_end_ns.png",
}

TripwireAlert.BrokenSprites = {
    ewLeft = "media/textures/tripwire/tripwire_broken_ew_0.png",
    ewRight = "media/textures/tripwire/tripwire_broken_ew_2.png",
    nsNorth = "media/textures/tripwire/tripwire_broken_ns_2.png",
    nsSouth = "media/textures/tripwire/tripwire_broken_ns_0.png",
    ewSingle = "media/textures/tripwire/tripwire_broken_ew_0.png",
    nsSingle = "media/textures/tripwire/tripwire_broken_ns_0.png",
}

TripwireAlert.BrokenOverlays = {
    ewSingle = "media/textures/tripwire/tripwire_end_ew.png",
    nsSingle = "media/textures/tripwire/tripwire_end_ns.png",
}

function TripwireAlert.getTileRole(line, index)
    local pos = line[index]
    if not pos then
        return "ewLeft"
    end

    local minV = pos.north and line[1].y or line[1].x
    local maxV = minV
    for _, tile in ipairs(line) do
        local v = pos.north and tile.y or tile.x
        if v < minV then
            minV = v
        end
        if v > maxV then
            maxV = v
        end
    end

    local here = pos.north and pos.y or pos.x
    if pos.north then
        if minV ~= maxV then
            if here == minV then
                return "nsNorth"
            end
            if here == maxV then
                return "nsSouth"
            end
            return "nsMid"
        end
        return "nsSingle"
    end

    if minV ~= maxV then
        if here == minV then
            return "ewLeft"
        end
        if here == maxV then
            return "ewRight"
        end
        return "ewMid"
    end
    return "ewSingle"
end

function TripwireAlert.getTileSprite(line, index)
    return TripwireAlert.Sprites[TripwireAlert.getTileRole(line, index)]
end

function TripwireAlert.getOverlaySprite(role, broken)
    return TripwireAlert.Overlays[role]
end

local function readSandboxOption(name, default)
    local options = getSandboxOptions()
    if options then
        local option = options:getOptionByName(name)
        if option then
            local value = option:getValue()
            if value ~= nil then
                return value
            end
        end
    end
    return default
end

function TripwireAlert.getSandbox()
    return {
        soundRadius = readSandboxOption("TripwireAlert.SoundRadius", 40),
        playerTrip = readSandboxOption("TripwireAlert.PlayerTrip", true) == true,
        attractZombies = readSandboxOption("TripwireAlert.AttractZombies", true) == true,
        armTime = readSandboxOption("TripwireAlert.ArmTime", 3),
    }
end

function TripwireAlert.getActionTime(character)
    if character and character:isTimedActionInstant() then
        return 1
    end
    return (TripwireAlert.getSandbox().armTime or 3) * 50
end

function TripwireAlert.squareKey(x, y, z)
    return x .. "," .. y .. "," .. z
end

function TripwireAlert.isAuthority()
    return not isClient()
end

function TripwireAlert.encodeLayout(layout)
    local parts = {}
    for i, tile in ipairs(layout or {}) do
        parts[i] = string.format("%d,%d,%d,%s,%s", tile.x, tile.y, tile.z, tile.north and "1" or "0", tile.spriteRole or "ewSingle")
    end
    return table.concat(parts, ";")
end

function TripwireAlert.decodeLayout(encoded)
    local layout = {}
    if not encoded or encoded == "" then
        return layout
    end
    for entry in string.gmatch(encoded, "[^;]+") do
        local x, y, z, north, role = string.match(entry, "^(%-?%d+),(%-?%d+),(%-?%d+),([01]),([%w]+)$")
        if x then
            table.insert(layout, {
                x = tonumber(x),
                y = tonumber(y),
                z = tonumber(z),
                north = north == "1",
                spriteRole = role,
            })
        end
    end
    return layout
end

function TripwireAlert.isTileValid(obj)
    return obj ~= nil and obj.getModData and obj:getSquare() ~= nil and obj:getModData().isTripwire == true
end

function TripwireAlert.syncTile(obj)
    if obj and obj.transmitModData then
        obj:transmitModData()
    end
end

function TripwireAlert.removeItem(character, item)
    if not character or not item then
        return false
    end
    if item.getID then
        local resolved = character:getInventory():getItemById(item:getID())
        if resolved then
            item = resolved
        end
    end
    character:removeFromHands(item)
    local container = item:getContainer()
    if not container then
        return false
    end
    container:Remove(item)
    sendRemoveItemFromContainer(container, item)
    return true
end

function TripwireAlert.addKit(character)
    if not character then
        return nil
    end
    local item = character:getInventory():AddItem("TripwireAlert.TripwireKit")
    sendAddItemToContainer(character:getInventory(), item)
    return item
end

function TripwireAlert.playBell(square)
    if not square then
        return
    end
    if isServer() then
        playServerSound("TripwireBell", square)
    else
        square:playSound("TripwireBell", true)
    end
end

function TripwireAlert.newId()
    TripwireAlert._nextId = (TripwireAlert._nextId or 0) + 1
    return tostring(getTimestampMs()) .. "-" .. tostring(ZombRand(1000000)) .. "-" .. tostring(TripwireAlert._nextId)
end

function TripwireAlert.getTripwireOnSquare(square)
    if not square then
        return nil
    end
    local specials = square:getSpecialObjects()
    if not specials then
        return nil
    end
    for i = 0, specials:size() - 1 do
        local obj = specials:get(i)
        local md = obj and obj:getModData()
        if md and md.isTripwire then
            return obj
        end
    end
    return nil
end

function TripwireAlert.createTile(x, y, z, north, spriteRole, tripwireId, lineTiles, building)
    local cell = getWorld():getCell()
    local square = cell:getGridSquare(x, y, z)
    if not square then
        return nil
    end
    local sprite = TripwireAlert.Sprites[spriteRole]
    if not sprite then
        return nil
    end

    local info = building or {}
    local obj = IsoThumpable.new(cell, square, sprite, north, info)
    if buildUtil and building then
        buildUtil.setInfo(obj, building)
    end
    obj:setName("Tripwire")
    obj:setCanPassThrough(true)
    obj:setBlockAllTheSquare(false)
    obj:setIsThumpable(false)

    local md = obj:getModData()
    md.isTripwire = true
    md.armed = true
    md.broken = false
    md.tripwireId = tripwireId
    md.spriteRole = spriteRole
    md.lineTiles = lineTiles

    TripwireAlert.setOverlay(obj, spriteRole, false)
    square:AddSpecialObject(obj)
    obj:transmitCompleteItemToClients()
    TripwireAlert.rememberTile(obj)
    TripwireAlert.register(obj, 2500)
    return obj
end

function TripwireAlert.placeLine(character, kit, layout)
    if not character or not kit or not layout or #layout < 1 then
        return false
    end
    if kit.getID then
        local resolved = character:getInventory():getItemById(kit:getID())
        if resolved then
            kit = resolved
        end
    end
    if not character:getInventory():contains(kit) then
        return false
    end
    for _, tile in ipairs(layout) do
        local square = getCell():getGridSquare(tile.x, tile.y, tile.z)
        if not square or not square:has(IsoFlagType.solidfloor) or TripwireAlert.getTripwireOnSquare(square) then
            return false
        end
    end
    local tripwireId = TripwireAlert.newId()
    for _, tile in ipairs(layout) do
        TripwireAlert.createTile(tile.x, tile.y, tile.z, tile.north, tile.spriteRole, tripwireId, layout, nil)
    end
    return TripwireAlert.removeItem(character, kit)
end

function TripwireAlert.findWire(character)
    if not character then
        return nil
    end
    return character:getInventory():getFirstTypeRecurse("Base.Wire")
end

function TripwireAlert.consumeWire(character)
    return TripwireAlert.removeItem(character, TripwireAlert.findWire(character))
end

function TripwireAlert.rememberTile(obj)
    local square = obj:getSquare()
    if not square then
        return nil
    end
    local md = obj:getModData()
    if not md.tripwireId then
        md.tripwireId = TripwireAlert.squareKey(square:getX(), square:getY(), square:getZ())
    end
    local id = md.tripwireId
    local pos = { x = square:getX(), y = square:getY(), z = square:getZ() }
    local group = TripwireAlert.groups[id]
    if not group then
        group = {}
        TripwireAlert.groups[id] = group
    end
    for _, existing in ipairs(group) do
        if existing.x == pos.x and existing.y == pos.y and existing.z == pos.z then
            return id
        end
    end
    table.insert(group, pos)
    return id
end

function TripwireAlert.getGroupObjects(obj)
    local result = {}
    local seen = {}
    local function add(tile)
        if not tile then
            return
        end
        local square = tile:getSquare()
        if not square then
            return
        end
        local key = TripwireAlert.squareKey(square:getX(), square:getY(), square:getZ())
        if seen[key] then
            return
        end
        seen[key] = true
        table.insert(result, tile)
    end

    add(obj)
    if not obj then
        return result
    end

    local md = obj:getModData()
    local function addPositions(positions)
        if not positions then
            return
        end
        for _, pos in ipairs(positions) do
            local square = getCell():getGridSquare(pos.x, pos.y, pos.z)
            add(TripwireAlert.getTripwireOnSquare(square))
        end
    end

    addPositions(md.lineTiles)
    addPositions(md.tripwireId and TripwireAlert.groups[md.tripwireId])
    return result
end

function TripwireAlert.watch(obj, graceMs)
    local square = obj:getSquare()
    if not square then
        return
    end
    TripwireAlert.rememberTile(obj)
    local key = TripwireAlert.squareKey(square:getX(), square:getY(), square:getZ())
    local ignoreUntil = 0
    if graceMs and graceMs > 0 then
        ignoreUntil = getTimestampMs() + graceMs
    end
    TripwireAlert.watched[key] = {
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
        tripwireId = obj:getModData().tripwireId,
        ignoreUntil = ignoreUntil,
    }
end

function TripwireAlert.unwatch(obj)
    local square = obj:getSquare()
    if not square then
        return
    end
    local key = TripwireAlert.squareKey(square:getX(), square:getY(), square:getZ())
    TripwireAlert.watched[key] = nil
    TripwireAlert.armed[key] = nil
end

function TripwireAlert.register(obj, graceMs)
    TripwireAlert.watch(obj, graceMs)
    local square = obj:getSquare()
    if not square then
        return
    end
    local key = TripwireAlert.squareKey(square:getX(), square:getY(), square:getZ())
    local ignoreUntil = 0
    if graceMs and graceMs > 0 then
        ignoreUntil = getTimestampMs() + graceMs
    end
    TripwireAlert.armed[key] = {
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
        tripwireId = obj:getModData().tripwireId,
        ignoreUntil = ignoreUntil,
    }
    obj:getModData().armed = true
end

function TripwireAlert.unregister(obj)
    local square = obj:getSquare()
    if not square then
        return
    end
    local key = TripwireAlert.squareKey(square:getX(), square:getY(), square:getZ())
    TripwireAlert.armed[key] = nil
    obj:getModData().armed = false
end

function TripwireAlert.setGroupArmed(obj, armed)
    for _, tile in ipairs(TripwireAlert.getGroupObjects(obj)) do
        if tile:getModData().broken then
            return
        end
    end
    for _, tile in ipairs(TripwireAlert.getGroupObjects(obj)) do
        if armed then
            tile:getModData().armed = true
            TripwireAlert.register(tile, 2500)
        else
            TripwireAlert.unregister(tile)
            TripwireAlert.watch(tile, 2500)
        end
        TripwireAlert.syncTile(tile)
    end
end

function TripwireAlert.applySprite(obj, spriteName)
    if not obj or not spriteName then
        return
    end
    obj:setSpriteFromName(spriteName)
    if not isClient() then
        obj:transmitUpdatedSpriteToClients()
    end
end

function TripwireAlert.setOverlay(obj, role, broken)
    if not obj then
        return
    end
    local overlay = TripwireAlert.getOverlaySprite(role, broken)
    if overlay then
        obj:setOverlaySprite(overlay, 1, 1, 1, 1)
    else
        obj:setOverlaySprite(nil)
    end
end

function TripwireAlert.applyVisual(obj, role, broken)
    if not obj or not role then
        return
    end
    local sprites = broken and TripwireAlert.BrokenSprites or TripwireAlert.Sprites
    local sprite = sprites[role]
    if sprite then
        obj:setSpriteFromName(sprite)
    end
    TripwireAlert.setOverlay(obj, role, broken)
    if not isClient() then
        obj:transmitUpdatedSpriteToClients()
    end
end

function TripwireAlert.breakGroup(obj)
    local tiles = TripwireAlert.getGroupObjects(obj)
    local id = obj:getModData().tripwireId
    local layout = obj:getModData().lineTiles
    if not layout then
        layout = {}
        for _, tile in ipairs(tiles) do
            local square = tile:getSquare()
            local md = tile:getModData()
            table.insert(layout, {
                x = square:getX(),
                y = square:getY(),
                z = square:getZ(),
                north = md.spriteRole == "nsNorth" or md.spriteRole == "nsMid" or md.spriteRole == "nsSouth",
                spriteRole = md.spriteRole,
            })
        end
    end
    local keep = {}
    for _, tile in ipairs(tiles) do
        local md = tile:getModData()
        TripwireAlert.unregister(tile)
        TripwireAlert.unwatch(tile)
        local role = md.spriteRole
        if role == "ewMid" or role == "nsMid" then
            local square = tile:getSquare()
            if square then
                square:transmitRemoveItemFromSquare(tile)
            end
        else
            md.broken = true
            md.lineTiles = layout
            TripwireAlert.applyVisual(tile, role, true)
            TripwireAlert.syncTile(tile)
            table.insert(keep, tile)
        end
    end
    if id then
        TripwireAlert.groups[id] = nil
        for _, tile in ipairs(keep) do
            TripwireAlert.rememberTile(tile)
        end
    end
end

function TripwireAlert.repairGroup(obj)
    local layout = obj:getModData().lineTiles
    local tripwireId = obj:getModData().tripwireId
    if layout then
        for _, tile in ipairs(layout) do
            local square = getCell():getGridSquare(tile.x, tile.y, tile.z)
            local existing = TripwireAlert.getTripwireOnSquare(square)
            if existing then
                local md = existing:getModData()
                md.broken = false
                md.armed = true
                md.spriteRole = tile.spriteRole
                md.lineTiles = layout
                md.tripwireId = tripwireId
                TripwireAlert.applyVisual(existing, tile.spriteRole, false)
                TripwireAlert.register(existing, 2500)
                TripwireAlert.syncTile(existing)
            else
                TripwireAlert.createTile(tile.x, tile.y, tile.z, tile.north, tile.spriteRole, tripwireId, layout, nil)
            end
        end
        return
    end

    for _, tile in ipairs(TripwireAlert.getGroupObjects(obj)) do
        local md = tile:getModData()
        md.broken = false
        md.armed = true
        TripwireAlert.applyVisual(tile, md.spriteRole, false)
        TripwireAlert.register(tile, 2500)
        TripwireAlert.syncTile(tile)
    end
end

function TripwireAlert.removeGroup(obj, character)
    for _, tile in ipairs(TripwireAlert.getGroupObjects(obj)) do
        TripwireAlert.unregister(tile)
        TripwireAlert.unwatch(tile)
        local square = tile:getSquare()
        if square then
            square:transmitRemoveItemFromSquare(tile)
        end
    end
    if character then
        TripwireAlert.addKit(character)
    end
end

function TripwireAlert.getLineSquares(x1, y1, z, x2, y2)
    local maxLen = TripwireAlert.MAX_LENGTH
    local dx = x2 - x1
    local dy = y2 - y1
    local tiles = {}
    if math.abs(dx) >= math.abs(dy) then
        local step = 1
        if dx < 0 then
            step = -1
        end
        local len = math.min(math.abs(dx) + 1, maxLen)
        for i = 0, len - 1 do
            table.insert(tiles, { x = x1 + (i * step), y = y1, z = z, north = false })
        end
    else
        local step = 1
        if dy < 0 then
            step = -1
        end
        local len = math.min(math.abs(dy) + 1, maxLen)
        for i = 0, len - 1 do
            table.insert(tiles, { x = x1, y = y1 + (i * step), z = z, north = true })
        end
    end
    return tiles
end

function TripwireAlert.filterPlaceableLine(line)
    local out = {}
    for _, pos in ipairs(line) do
        local square = getCell():getGridSquare(pos.x, pos.y, pos.z)
        if not square or not square:has(IsoFlagType.solidfloor) or TripwireAlert.getTripwireOnSquare(square) then
            break
        end
        table.insert(out, pos)
    end
    return out
end
