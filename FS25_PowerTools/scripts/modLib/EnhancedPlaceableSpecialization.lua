--[[
Linked Placeable Specialization (Weezls Mod Lib for FS22) - Enables the possibility to have multiple placeables to be placed at once

Author:     w33zl (github.com/w33zl)

COPYRIGHT:
You may redistribute the script, in original or modified state. All I request in return is that you leave this header intact and let me (the author, w33zl) know that you have used the script. Contact me on Facebook let me know in which mod you used the script.

I will also kindly ask you to, if possible, share your creations freely to the community, together we will create better mods and we all benefit of an open and sharing community!
]]

assert(Log, "The dependency 'Log' from WeezlsModLibrary was not found! Please add '<sourceFile filename=\"scripts/modLib/LogHelper.lua\" />' to your <extraSourceFiles> section in modDesc.xml")

EnhancedPlaceable = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	MOD_DIRECTORY = g_currentModDirectory,
	MOD_NAME = g_currentModName,
    SPEC_NAME = ("spec_%s.EnhancedPlaceable"):format(g_currentModName)
}

function EnhancedPlaceable.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", EnhancedPlaceable)
	-- SpecializationUtil.registerEventListener(placeableType, "onDelete", EnhancedPlaceable)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", EnhancedPlaceable)
	-- SpecializationUtil.registerEventListener(placeableType, "onOwnerChanged", EnhancedPlaceable)
end

function EnhancedPlaceable.registerXMLPaths(schema, basePath)
    Log:debug("EnhancedPlaceable.registerXMLPaths")
    
	schema:setXMLSpecializationType("EnhancedPlaceables")
	schema:register(XMLValueType.STRING, basePath .. ".EnhancedPlaceables.EnhancedPlaceable(?)#filename", "TODO:")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#positionOffset", "Translation")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotationOffset", "Rotation")
    -- schema:register(XMLValueType.BOOL, basePath .. "#sellWithParent", "TODO:", false)
    -- schema:register(XMLValueType.INT, basePath .. "#price", "TODO:", 0)

	schema:setXMLSpecializationType()
end

function EnhancedPlaceable:onLoad(savegame)
    
    -- Log:debug("EnhancedPlaceable:onLoad")
    -- Log:var("isLoadedFromSavegame", self.isLoadedFromSavegame)
    -- Log:var("currentSavegameId", self.currentSavegameId)

	local spec = self[EnhancedPlaceable.SPEC_NAME]

	spec.EnhancedPlaceables = spec.EnhancedPlaceables or {}

    --TODO: read actual values from XML
	self.xmlFile:iterate("placeable.EnhancedPlaceables.EnhancedPlaceable", function (_, key)
		local EnhancedPlaceableFilename = self.xmlFile:getValue(key .. "#filename", nil)

        local childPlaceable = {
            filename = EnhancedPlaceableFilename,
        }

        childPlaceable.positionOffset = self.xmlFile:getVector(key .. "#positionOffset", {
            0,
            0,
            0,
        }, 3)

	-- 	local text = self.xmlFile:getValue(key .. "#text", nil)

	-- 	if text ~= nil then
	-- 		text = g_i18n:convertText(text, self.customEnvironment)

	-- 		hotspot:setName(text)
	-- 	end

		table.insert(spec.EnhancedPlaceables, childPlaceable)
	end)
end

-- function EnhancedPlaceable:onDelete()
--     Log:debug("Cleanup started")
-- 	local spec = self[EnhancedPlaceable.SPEC_NAME]

--     -- self.loadingPlaceable
--     --:delete()

--     -- for i = 1, #spec.EnhancedPlaceables do
--     --     local childPlaceable = spec.EnhancedPlaceables[i]

--     --     if childPlaceable.loadingPlaceable ~= nil then
--     --         -- childPlaceable.loadingPlaceable:delete()
--     --         Log:debug("Marking placeable for deletion")
--     --         g_currentMission:addPlaceableToDelete(childPlaceable.loadingPlaceable)
--     --     end
--     -- end

    

--     spec.EnhancedPlaceables = nil

--     -- self.spec_EnhancedPlaceable = nil

-- 	g_messageCenter:unsubscribeAll(self)

--     Log:debug("Cleanup completed")
-- end

