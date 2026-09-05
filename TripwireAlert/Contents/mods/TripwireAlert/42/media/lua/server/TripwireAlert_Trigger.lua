local function triggerTripwire(square, mover)
    local obj = TripwireAlert.getTripwireOnSquare(square)
    if not obj or obj:getModData().broken then
        return
    end

    if obj:getModData().armed then
        local settings = TripwireAlert.getSandbox()
        TripwireAlert.playBell(square)
        if settings.attractZombies then
            addSound(obj, square:getX(), square:getY(), square:getZ(), settings.soundRadius, settings.soundRadius)
        end
    end

    TripwireAlert.breakGroup(obj)
end

local function canBreak(mover)
    if instanceof(mover, "IsoZombie") then
        return true
    end
    if instanceof(mover, "IsoAnimal") then
        return true
    end
    if instanceof(mover, "BaseVehicle") then
        return true
    end
    if instanceof(mover, "IsoPlayer") then
        return TripwireAlert.getSandbox().playerTrip
    end
    return false
end

local tick = 0
local function onTick()
    if not TripwireAlert.isAuthority() then
        return
    end

    local cell = getCell()
    if not cell then
        return
    end

    tick = tick + 1
    if tick % 15 ~= 0 then
        return
    end

    local snapshot = {}
    for key, data in pairs(TripwireAlert.watched) do
        if data and data.x then
            snapshot[#snapshot + 1] = data
        end
    end

    for i = 1, #snapshot do
        local data = snapshot[i]
        if not data.ignoreUntil or getTimestampMs() >= data.ignoreUntil then
            local square = cell:getGridSquare(data.x, data.y, data.z)
            if square then
                local vehicle = square:getVehicleContainer()
                if vehicle and canBreak(vehicle) then
                    triggerTripwire(square, vehicle)
                else
                    local movers = square:getMovingObjects()
                    if movers then
                        for j = 0, movers:size() - 1 do
                            local mover = movers:get(j)
                            if canBreak(mover) then
                                triggerTripwire(square, mover)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end

local function onLoadSquare(square)
    if not square or not getCell() then
        return
    end
    local obj = TripwireAlert.getTripwireOnSquare(square)
    if not obj then
        return
    end
    TripwireAlert.rememberTile(obj)
    local md = obj:getModData()
    if md.broken then
        TripwireAlert.applyVisual(obj, md.spriteRole, true)
        return
    end
    if md.spriteRole == "ewSingle" or md.spriteRole == "nsSingle" then
        TripwireAlert.setOverlay(obj, md.spriteRole, false)
    end
    if not TripwireAlert.isAuthority() then
        return
    end
    if md.armed then
        TripwireAlert.register(obj, 0)
    else
        TripwireAlert.watch(obj, 0)
    end
end

Events.OnTick.Add(onTick)
Events.LoadGridsquare.Add(onLoadSquare)
