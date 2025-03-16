--[[
Linked Placeable Specialization (Weezls Mod Lib for FS22) - Enables the possibility to have multiple placeables to be placed at once

Author:     w33zl (github.com/w33zl)

COPYRIGHT:
You may redistribute the script, in original or modified state. All I request in return is that you leave this header intact and let me (the author, w33zl) know that you have used the script. Contact me on Facebook let me know in which mod you used the script.

I will also kindly ask you to, if possible, share your creations freely to the community, together we will create better mods and we all benefit of an open and sharing community!
]]

assert(Log, "The dependency 'Log' from WeezlsModLibrary was not found! Please add '<sourceFile filename=\"scripts/ModLib/LogHelper.lua\" />' to your <extraSourceFiles> section in modDesc.xml")

LinkedPlaceable = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	MOD_DIRECTORY = g_currentModDirectory,
	MOD_NAME = g_currentModName,
    SPEC_NAME = ("spec_%s.linkedPlaceable"):format(g_currentModName) --HACK: Is this the proper way of doing this?

}

function LinkedPlaceable.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", LinkedPlaceable)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", LinkedPlaceable)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", LinkedPlaceable)
	-- SpecializationUtil.registerEventListener(placeableType, "onOwnerChanged", LinkedPlaceable)
end

function LinkedPlaceable.registerXMLPaths(schema, basePath)
    Log:debug("LinkedPlaceable.registerXMLPaths")
    
	schema:setXMLSpecializationType("LinkedPlaceables")
	schema:register(XMLValueType.STRING, basePath .. ".linkedPlaceables.linkedPlaceable(?)#filename", "TODO:")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#positionOffset", "Translation")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotationOffset", "Rotation")

	schema:setXMLSpecializationType()
end

function LinkedPlaceable:onLoad(savegame)
    
    Log:debug("LinkedPlaceable:onLoad")
    Log:var("isLoadedFromSavegame", self.isLoadedFromSavegame)
    Log:var("currentSavegameId", self.currentSavegameId)
    

    self.spec_LinkedPlaceable = self[LinkedPlaceable.SPEC_NAME] -- First init of spec variable

	local spec = self.spec_LinkedPlaceable

	spec.linkedPlaceables = spec.linkedPlaceables or {}


    --TODO: read actual values from XML
	self.xmlFile:iterate("placeable.linkedPlaceables.linkedPlaceable", function (_, key)
		local linkedPlaceableFilename = self.xmlFile:getValue(key .. "#filename", nil)

        local childPlaceable = {
            filename = linkedPlaceableFilename,
        }

        childPlaceable.positionOffset = self.xmlFile:getVector(key .. "#positionOffset", {
            2,
            0,
            0,
        }, 3)

	-- 	local text = self.xmlFile:getValue(key .. "#text", nil)

	-- 	if text ~= nil then
	-- 		text = g_i18n:convertText(text, self.customEnvironment)

	-- 		hotspot:setName(text)
	-- 	end

		table.insert(spec.linkedPlaceables, childPlaceable)
	end)
end

function LinkedPlaceable:onDelete()
    Log:debug("Cleanup started")
	local spec = self[LinkedPlaceable.SPEC_NAME]

    -- self.loadingPlaceable
    --:delete()

    -- for i = 1, #spec.linkedPlaceables do
    --     local childPlaceable = spec.linkedPlaceables[i]

    --     if childPlaceable.loadingPlaceable ~= nil then
    --         -- childPlaceable.loadingPlaceable:delete()
    --         Log:debug("Marking placeable for deletion")
    --         g_currentMission:addPlaceableToDelete(childPlaceable.loadingPlaceable)
    --     end
    -- end

    

    spec.linkedPlaceables = nil

    -- self.spec_LinkedPlaceable = nil

	g_messageCenter:unsubscribeAll(self)

    Log:debug("Cleanup completed")
end

function table.clone(org)
    return {table.unpack(org)}
  end

function LinkedPlaceable:onPostFinalizePlacement()
    Log:debug("Placing linked placeable (parent)")
    -- Log:table("self", self, 1)

    Log:var("isLoadingFromSavegameXML", self.isLoadingFromSavegameXML)
    Log:var("isLoadedFromSavegame", self.isLoadedFromSavegame)
    Log:var("currentSavegameId", self.currentSavegameId)

    if self.isLoadedFromSavegame then -- No need to do anything on loading existing savegame, exit event
        Log:debug("Loaded placeable from save game, no need to add linked placeables")
        --NOTE: is this the proper way of doing this? Maybe we still need to do something on load? 
        return
    end

    --isLoadingFromSavegameXML
    --currentSavegameId

--     2023-12-16 15:14 self:: savegame :: table: 0x01db045ba700
-- 2023-12-16 15:14 self::     xmlFile :: table: 0x01dac2298b80
-- 2023-12-16 15:14 self::     key :: placeables.placeable(33)

    -- isLoadedFromSavegame

    -- Log:debug("LinkedPlaceable:onPostFinalizePlacement")
    local spec = self[LinkedPlaceable.SPEC_NAME]

    local function Position(vector3)
        return {
            x = vector3[1],
            y = vector3[2],
            z = vector3[3],
        }
    end

    local function AddPosition(position1, position2)
        return {
            x = position1.x + position2.x,
            y = position1.y + position2.y,
            z = position1.z + position2.z,
        }
    end

    local function addVectorToPosition(position, vector)
        return {
            x = position.x + vector[1],
            y = position.y + vector[2],
            z = position.z + vector[3],
        }
    end


    local farmId = FarmManager.SINGLEPLAYER_FARM_ID --HACK: fix this

    for i = 1, #spec.linkedPlaceables do
        local childPlaceable = spec.linkedPlaceables[i]
        local filename = Utils.getFilename( childPlaceable.filename, LinkedPlaceable.MOD_DIRECTORY)
        local positionOffset = Position(childPlaceable.positionOffset) -- Convert Vector3[x, y, z] to Position{x, y, z}
        local newPosition = AddPosition(self.position, positionOffset)
        --TODO: add support for more settings like price, rotation etc

        -- Log:var("filename", filename)
        Log:table("positionOffset", positionOffset)
        Log:table("newPosition", newPosition)

        --TODO: need to check if placing same type as current to avoid endless loop? Seems like it might not be necessary
        
        local loadingPlaceable = PlaceableUtil.loadPlaceable(filename, newPosition, self.rotation, farmId, nil, LinkedPlaceable.loadedPlaceable, self, { childPlaceable = childPlaceable})
        --                                   PlaceableUtil.loadPlaceable(placeablesToLoad[1], position,                     rotation,                   AccessHandler.EVERYONE, nil, callback, nil, {})

        childPlaceable.loadingPlaceable = loadingPlaceable --TODO: maybe store reference for later use=?

        if loadingPlaceable == nil then
            Log:warning("Unknown return value when trying to add linked placeable")
            Log:debug("No response from 'PlaceableUtil.loadPlaceable', something is probably wrong with adding the placeable")
        else
            Log:table("loadingPlaceable", loadingPlaceable, 2)
        end


    end
end

function LinkedPlaceable:loadedPlaceable(placeable, loadingState, args)
    local spec = self[LinkedPlaceable.SPEC_NAME]
	-- Log:debug("LinkedPlaceable:loadedPlaceable")

    -- Log:var("placeable", placeable) 
    -- Log:var("loadingState", loadingState) 
    -- Log:var("args", args)

    -- Log:table("placeable", placeable) 
    -- -- Log:table("loadingState", loadingState) 
    Log:table("args", args)

    
    Log:debug("Finalizing linked placeable")

    local placeableFilename = (placeable ~= nil and placeable.configFileName ~= nil and placeable.configFileName) or "--UNKNOWN--"
    Log:var("Placeable filename", placeableFilename)

    Log:var("Loading State", loadingState)
    Log:var("placeable.isActive", placeable.isActive)
    
    -- Log:table("g_currentMission", g_currentMission, 1)
    -- Log:table("g_currentMission.placeables:after", g_currentMission.placeables)

    if loadingState == Placeable.LOADING_STATE_ERROR then
        Logging.error("Could not load placeable '%s'", placeable.configFileName)
    else
        Logging.info("Loaded placeable '%s'", placeable.configFileName)
        placeable:finalizePlacement()
        -- placeable:register()
    end

    -- g_currentMission.placeableSystem:addPlaceable(self)
	-- g_currentMission:addOwnedItem(self)

    -- if placeable ~= nil then
    --     placeable:delete()
    -- end

	if loadingState == Placeable.LOADING_STATE_ERROR then
		Logging.warning("Failed to load placeable")

		if placeable ~= nil then
			placeable:delete()
		end

		return
	end

	if placeable == nil then
		Logging.warning("Failed to load placeable")

		return
	end

    local farmId = placeable.farmlandId
    local propertyState = placeable.propertyState

    Log:var("Player FarmID", g_currentMission.player ~= nil and g_currentMission.player.farmId)
    Log:var("Placeable FarmID", farmId)
    Log:var("Placeable Property State", propertyState)

	-- placeable:setPropertyState(Placeable.PROPERTY_STATE_PLACED)
    -- placeable:setPropertyState(Placeable.PROPERTY_STATE_OWNED) --TODO: needed?
	-- placeable:setOwnerFarmId(g_currentMission.player.farmId) --TODO: needed?

	-- if placeable.setColor ~= nil then
	-- 	placeable:setColor(self.colorIndex)
	-- end

    

    --TODO: insert actual placeable into a collection?
    -- self.placeable = placeable
end


-- function LinkedPlaceable:onOwnerChanged()
-- 	local spec = self.spec_LinkedPlaceable
-- end

local runOnce = true

-- Placeable.delete = Utils.overwrittenFunction(Placeable.delete, 
--     function(self, superFunc, ...)
--         -- Log:debug("Placeable:delete")

--         if runOnce then
--             printCallstack()
--             runOnce = false
--         end

--         Log:debug("Placeable:delete: %s", self.configFileName)

--         -- Log:var("g_currentMission.placeableSystem.isReloadRunning", g_currentMission.placeableSystem.isReloadRunning)

--         -- Log:var("isDeleting", self.isDeleting)
--         -- Log:var("isDeleted", self.isDeleted)
--         -- Log:var("canBeDeleted", self.canBeDeleted)
--         -- Log:var("farmlandId", self.farmlandId)
--         -- Log:var("loadingState", self.loadingState)
--         -- Log:var("propertyState", self.propertyState)

--         -- Log:var("id", self.id)
--         -- Log:var("configFileName", self.configFileName)
--         -- Log:var("typeName", self.typeName)
--         -- Log:var("customEnvironment", self.customEnvironment)
--         -- Log:var("loadingState", self.loadingState)
--         -- Log:var("propertyState", self.propertyState)
--         superFunc(self, ...)

--     end
-- )
