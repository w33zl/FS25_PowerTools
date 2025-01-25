SpawnObjectEvent = {}
local SpawnObjectEvent_mt = Class(SpawnObjectEvent, Event)

InitEventClass(SpawnObjectEvent, "SpawnObjectEvent")

-- CreateSawdustEvent = {}
-- CreateSawdustEvent_mt = Class(CreateSawdustEvent, Event)

-- InitEventClass(CreateSawdustEvent, "CreateSawdustEvent")


local function spawnPallet(fillTypeIndex, amount, worldX, worldZ, player)
	if fillTypeIndex == nil then
		Log:error("No fillType given")
        return
    end

    local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
    -- local fillType = g_fillTypeManager:getFillTypeByName(string.upper(palletFillTypeName))

    if fillType == nil or fillType.palletFilename == nil then
        Log:error("Invalid pallet fillType #%d.", fillTypeIndex)
        return
        
    end

    player = player or g_localPlayer

    if player == nil then
        Log:error("No player found")
        return
    end

    local farmId = player.farmId

    if (farmId == FarmManager.SPECTATOR_FARM_ID or not farmId) then
        Log:error("No farmId found")
        return
    end
    local x, y, z = player:getPosition()
    local dirX, dirZ = player:getCurrentFacingDirection()
    local positionX = tonumber(worldX) or (x + dirX * 3)
    local positionZ = tonumber(worldZ) or (z + dirZ * 3)
    local yOffset = Platform.gameplay.hasDynamicPallets and 0.2 or 0
    local rcFlags = CollisionFlag.STATIC_OBJECT + CollisionFlag.TERRAIN + CollisionFlag.TERRAIN_DELTA + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE
    local matchedObject, _, objY, _, _ = RaycastUtil.raycastClosest(positionX, y + 26, positionZ, 0, -1, 0, 40, rcFlags)
    if matchedObject == nil then
        objY = getTerrainHeightAtWorldPos(g_terrainNode, positionX, y, positionZ)
    end
    local loadingData = VehicleLoadingData.new()
    loadingData:setFilename(fillType.palletFilename)
    loadingData:setPosition(positionX, objY + yOffset, positionZ)
    loadingData:setPropertyState(VehiclePropertyState.OWNED)
    loadingData:setOwnerFarmId(farmId)

    local function onFinishedLoading(_, vehicles, state, _) 
        if state ~= VehicleLoadingState.OK then
            Log:error("Failed to load pallet")
            return
        end
        local vehicle = vehicles[1]
        local fillDelta = tonumber(amount) or math.huge
        local actualAmount = 0
        for _, fillUnit in ipairs(vehicle:getFillUnits()) do
            if vehicle:getFillUnitSupportsFillType(fillUnit.fillUnitIndex, fillType.index) then
                actualAmount = actualAmount + vehicle:addFillUnitFillLevel(1, fillUnit.fillUnitIndex, fillDelta, fillType.index, ToolType.UNDEFINED, nil)
                fillDelta = fillDelta - actualAmount
                if fillDelta <= 0 then
                    break
                end
            end
        end
        Log:info("Loaded pallet with %dl of %s", actualAmount, fillType.title)
    end

    loadingData:load(onFinishedLoading)
end

function SpawnObjectEvent.emptyNew()
	return Event.new(SpawnObjectEvent_mt)
end

function SpawnObjectEvent.new(fillTypeId, amount, worldX, worldZ)
	local newEvent = SpawnObjectEvent.emptyNew()

	newEvent.fillTypeId = fillTypeId
	newEvent.amount = amount or -1
	newEvent.worldX = worldX
	newEvent.worldZ = worldZ
	
	return newEvent
end

function SpawnObjectEvent.readStream(self, streamId, connection)
	Log:debug("readStream")
	-- Log:var("g_server", g_server)
	if connection:getIsServer() then
		Log:debug("Response from server")
		local fillTypeId = streamReadInt32(streamId)
		local amount = streamReadInt32(streamId)
	else
		Log:debug("Response from client")
		local fillTypeId = streamReadInt32(streamId)
		local amount = streamReadInt32(streamId)

        if amount == -1 then
            amount = math.huge
        end

		local player = connection and g_currentMission:getPlayerByConnection(connection)
		spawnPallet(fillTypeId, amount, worldX, worldZ, player)
	end
	-- self:run(connection)
end

function SpawnObjectEvent.writeStream(self, streamId, connection)
	Log:debug("writeStream")
	if connection:getIsServer() then
		Log:debug("Sending from client")
		streamWriteInt32(streamId, self.fillTypeId)
		streamWriteInt32(streamId, self.amount)
	else
		Log:debug("Sending from server")
		streamWriteInt32(streamId, self.fillTypeId)
		streamWriteInt32(streamId, self.amount)
	end
end

-- function SpawnObjectEvent:send()
-- 	Log:debug("send")
-- 	local obj = {}
-- 	Server.broadcastEvent(g_server, SpawnObjectEvent.new(), nil, nil, obj, false)  -- event, sendLocal, ignoreConnection, ghostObject, force
-- end

function SpawnObjectEvent.spawnPallet(fillTypeId, amount, worldX, worldZ)
	if g_server == nil then
		-- Send event
		g_client:getServerConnection():sendEvent(SpawnObjectEvent.new(fillTypeId, amount, worldX, worldZ))
	else
		-- Fire directly
		spawnPallet(fillTypeId, amount, worldX, worldZ)
	end
end

-- function SpawnObjectEvent.sendEvent()
-- 	Log:debug("sendEvent")
-- 	local obj = {}
-- 	Server.broadcastEvent(g_server, SpawnObjectEvent.new(), nil, nil, obj, false)  -- event, sendLocal, ignoreConnection, ghostObject, force
-- end

-- function SpawnObjectEvent.run(self, connection)
-- 	Log:debug("run")
-- 	Log:var("connection", connection)
-- 	Log:var("isServer", connection.isServer)
-- 	Log:var("streamId ", connection.streamId)
-- 	Log:var("local", connection.localConnection)
-- 	Log:var("g_server", g_server)
-- 	Log:var("g_client", g_client)
-- 	-- if not connection:getIsServer() then
-- 	-- 	Log:debug("Execute!")
-- 	-- end
-- end

