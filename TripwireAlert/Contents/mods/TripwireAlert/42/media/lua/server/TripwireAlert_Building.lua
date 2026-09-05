local function defineTripwireBO()
    if rawget(_G, "TripwireBO") or not ISBuildingObject then
        return
    end

    TripwireBO = ISBuildingObject:derive("TripwireBO")

    function TripwireBO:create(x, y, z, north, sprite)
    end

    function TripwireBO:tryBuild(x, y, z)
        local square = getCell():getGridSquare(x, y, z)
        if not self:isValid(square) then
            return
        end

        if not self.startX then
            self.startX = x
            self.startY = y
            self.startZ = z
            self.lastNorth = nil
            return
        end

        local line = TripwireAlert.filterPlaceableLine(TripwireAlert.getLineSquares(self.startX, self.startY, self.startZ, x, y))
        if #line < 1 then
            return
        end
        if #line == 1 then
            line[1].north = self.lastNorth
            if line[1].north == nil then
                line[1].north = self.nSprite == 2 or self.nSprite == 4
            end
        end

        local squares = {}
        local layout = {}
        for i, pos in ipairs(line) do
            local tileSquare = getCell():getGridSquare(pos.x, pos.y, pos.z)
            if tileSquare then
                table.insert(squares, tileSquare)
            end
            table.insert(layout, {
                x = pos.x,
                y = pos.y,
                z = pos.z,
                north = pos.north == true,
                spriteRole = TripwireAlert.getTileRole(line, i),
            })
        end

        if #squares < 1 or not luautils.walkAdjSquares(self.character, squares, true) then
            return
        end

        ISTimedActionQueue.add(ISPlaceTripwireAction:new(self.character, self.kit, layout))
        getCell():setDrag(nil, self.player)
        self.startX = nil
        self.startY = nil
        self.startZ = nil
        self.endX = nil
        self.endY = nil
        self.endZ = nil
        self.lastNorth = nil
    end

    function TripwireBO:render(x, y, z, square)
        local x1 = self.startX or x
        local y1 = self.startY or y
        local z1 = self.startZ or z
        local line = TripwireAlert.getLineSquares(x1, y1, z1, x, y)
        if #line > 1 then
            self.lastNorth = line[1].north == true
        end
        if #line == 1 then
            if self.lastNorth ~= nil then
                line[1].north = self.lastNorth
            else
                line[1].north = self.nSprite == 2 or self.nSprite == 4
            end
        end
        if not self._ghosts then
            self._ghosts = {}
        end
        for i, pos in ipairs(line) do
            local role = TripwireAlert.getTileRole(line, i)
            local spriteName = TripwireAlert.Sprites[role]
            local ghost = self._ghosts[spriteName]
            if not ghost then
                ghost = IsoSprite.new()
                ghost:LoadSingleTexture(spriteName)
                self._ghosts[spriteName] = ghost
            end
            local tileSquare = getCell():getGridSquare(pos.x, pos.y, pos.z)
            local valid = self:isValid(tileSquare)
            if valid then
                ghost:RenderGhostTile(pos.x, pos.y, pos.z)
            else
                ghost:RenderGhostTileRed(pos.x, pos.y, pos.z)
            end
            local overlayName = TripwireAlert.getOverlaySprite(role, false)
            if overlayName then
                local overlayGhost = self._ghosts[overlayName]
                if not overlayGhost then
                    overlayGhost = IsoSprite.new()
                    overlayGhost:LoadSingleTexture(overlayName)
                    self._ghosts[overlayName] = overlayGhost
                end
                if valid then
                    overlayGhost:RenderGhostTile(pos.x, pos.y, pos.z)
                else
                    overlayGhost:RenderGhostTileRed(pos.x, pos.y, pos.z)
                end
            end
        end
    end

    function TripwireBO:isValid(square)
        if not square then
            return false
        end
        if not square:has(IsoFlagType.solidfloor) then
            return false
        end
        if TripwireAlert.getTripwireOnSquare(square) then
            return false
        end
        if not self.character:getInventory():contains(self.kit) then
            return false
        end
        return true
    end

    function TripwireBO:deactivate()
        self.startX = nil
        self.startY = nil
        self.startZ = nil
        self.endX = nil
        self.endY = nil
        self.endZ = nil
        self.lastNorth = nil
    end

    function TripwireBO:new(player, kit)
        local o = {}
        setmetatable(o, self)
        self.__index = self
        o:init()
        o:setSprite(TripwireAlert.Sprites.ewLeft)
        o:setNorthSprite(TripwireAlert.Sprites.nsNorth)
        o.name = "Tripwire"
        o.character = player
        o.player = player:getPlayerNum()
        o.kit = kit
        o.noNeedHammer = true
        o.skipBuildAction = true
        o.dragNilAfterPlace = true
        o.actionAnim = "Loot"
        return o
    end
end

defineTripwireBO()
Events.OnInitWorld.Add(defineTripwireBO)
Events.OnGameStart.Add(defineTripwireBO)
