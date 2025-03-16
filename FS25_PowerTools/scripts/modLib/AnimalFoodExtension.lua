--[[

Animal Food Extesion (Weezls Mod Lib for FS22) - Allows customization of the animal food system

Author:     w33zl
Version:    1.0.0
Modified:   2022-06-08

Github:             https://github.com/w33zl

Changelog:
v1.0        Initial public release (TBD)

COPYRIGHT:
You may not redistribute the script, in original or modified state, unless you have explicit permission from the author (i.e. w33zl).

However, contact me (WZL Modding) on Facebook and I -will- happily grant you permission to use and redistribute the script! I just want to know how, and by who, the script is being used <3


--------------------------------------------------------------------------------------

USAGE:

	<modDesc>
		<map>
			<animals>
				<food filename="xml/animalFood.xml" />
			</animals>
		</map>
	</modDesc>

]]

assert(Log, "The dependency 'Log' from WeezlsModLibrary was not found!")

local Log = Log:newLog(g_currentModName .. ":AnimalFoodExtesion")

local g_currentModDirectory = g_currentModDirectory
local g_currentModName = g_currentModName

if AnimalFoodSystem == nil then -- Something is really wrong!
    Log:error("Could not find class AnimalFoodSystem")
    return
end

local function loadDataFromModXML(mapXMLFile, xmlKey, baseDirectory, loadTarget, loadFunc, ...)
    Log:info("Loading map extension data ('%s') for mod '%s'", xmlKey, g_currentModName)

    local filename = getXMLString(mapXMLFile, string.format("modDesc.%s#filename", xmlKey))
    local xmlFile = mapXMLFile

    if filename ~= nil then
        local xmlFilename = Utils.getFilename(filename, baseDirectory)
        if fileExists(xmlFilename) then
            -- xmlFile = loadXMLFile("mapDataXML", xmlFilename)
            -- return loadFunc(loadTarget, xmlFile, ...)
            local xmlFileFood = XMLFile.load("animalFood", xmlFilename, AnimalFoodSystem.xmlSchema)
            return loadFunc(loadTarget, xmlFileFood, ...)
        else
            Log:error("No animal food XML file with the filename '%s' was found in the mod '%s'", xmlFilename, g_currentModName)
        end
    else
        --TODO: now silently ignore, maybe better to find out if that was intended or not
        Log:warning("The Animal Food Extension was enabled, but no '%s' key was found in the modDesc", xmlKey)
    end

    return false
end



AnimalFoodSystem.loadMapData = Utils.appendedFunction(AnimalFoodSystem.loadMapData, function(xmlFile, missionInfo)
    Log:debug("Loading AnimalFoodSystem Food Extension data for mod %s", g_currentModName)

    -- Hack to fix a "bug"(?) where l10n texts doesn't load from mod
    -- local oldCustomEnvironment = missionInfo.customEnvironment
    -- g_currentMission.customEnvironment = g_currentModName
    g_currentMission.animalFoodSystem.customEnvironment = g_currentModName

    local modDescFilename = Utils.getFilename("modDesc.xml", g_currentModDirectory)
    local modXmlFile = loadXMLFile("mapDataXML", modDescFilename)

	return loadDataFromModXML(modXmlFile, "map.animals.food", g_currentModDirectory, g_currentMission.animalFoodSystem, AnimalFoodSystem.loadModData, missionInfo, g_currentModDirectory)
end)

function AnimalFoodSystem:loadModData(xmlFileFood, missionInfo, baseDirectory)

	if xmlFileFood == nil then
		return false
	end

	Log:table("PRE LOAD AnimalFoodSystem.self", self)

    -- Log:table("g_currentMission.animalFoodSystem.animalTypeIndexToFood", g_currentMission.animalFoodSystem.animalTypeIndexToFood)

	self:allowReplacingAnimalFeed(xmlFileFood)

	if not self:loadAnimalFood(xmlFileFood, baseDirectory) then
		xmlFileFood:delete()

		return false
	end

    -- Log:table("g_currentMission.animalFoodSystem.animalTypeIndexToFood AFTER", g_currentMission.animalFoodSystem.animalTypeIndexToFood, 4)

	self:allowReplacingMixtures(xmlFileFood)

	if not self:loadMixtures(xmlFileFood, baseDirectory) then
		xmlFileFood:delete()

		return false
	end

    
    self:allowReplacingRecipes(xmlFileFood)

	if not self:loadRecipes(xmlFileFood, baseDirectory) then
		xmlFileFood:delete()

		return false
	end

	xmlFileFood:delete()

	Log:table("POST LOAD AnimalFoodSystem.self", self)

	return true
end


function AnimalFoodSystem:allowReplacingAnimalFeed(xmlFile)
	xmlFile:iterate("animalFood.animals.animal", function (_, key)
		local animalTypeName = xmlFile:getValue(key .. "#animalType")
        -- local recipeShouldBeReplaced = xmlFile:getBool(key .. "#replace", false)
		local recipeShouldBeReplaced = true

		if animalTypeName == nil or not recipeShouldBeReplaced then
			return false
		end
		
		local animalTypeIndex = self.mission.animalSystem:getTypeIndexByName(animalTypeName)

		local animalFood = self.animalTypeIndexToFood[animalTypeIndex]
		if animalFood == nil then
			Log:debug("Animal type '%s' feed is not defined, no need to remove anything", animalTypeName)
			return
		end

		-- -- Reindex all food items after the one to remove
		-- for index, currentAnimalFoodItem in ipairs(self.animalFood) do
		-- 	if index > animalFood.index then
		-- 		-- local oldIndex = currentAnimalFoodItem.index
		-- 		-- local newIndex = oldIndex - 1
		-- 		currentAnimalFoodItem.index = index - 1
		-- 		-- self.indexToAnimalFood[newIndex] = currentAnimalFoodItem
		-- 		-- self.animalTypeIndexToFood[animalTypeIndex] = currentAnimalFoodItem -- Shouldn't change
		
		-- 	end
		-- end

		-- Remove actual animal food
		table.remove(self.animalFood, animalFood.index)

		-- Reindex and update references to all food definitons
		self.indexToAnimalFood = {} -- Reset index table and start over..
		for index, currentAnimalFoodItem in ipairs(self.animalFood) do
			currentAnimalFoodItem.index = index -- Set new index value
			self.indexToAnimalFood[index] = currentAnimalFoodItem -- Add reference between index and food definition
		end

		-- self.animalFood[animalFood.index] = {} -- Replace food with empty dummy table HACK: is this really a good idea?

		-- Reset indexes
		-- self.indexToAnimalFood[animalFood.index] = nil
		self.animalTypeIndexToFood[animalTypeIndex] = nil -- Reset reference between animal and food definiton

		Log:info("Removed current feed definition for animal type '%s' (enables this feed to be replaced later)", animalTypeName)

	end)

	return true
end


function AnimalFoodSystem:allowReplacingMixtures(xmlFile)

	local function allowReplacingMixture(key)
		local animalTypeName = xmlFile:getValue(key .. "#animalType")
		local mixtureFillTypeName = xmlFile:getValue(key .. "#fillType")
        local mixtureShouldBeReplaced = xmlFile:getBool(key .. "#replace", false)

		-- Log:debug("allowReplacingMixtures")
		Log:var("animalTypeName", animalTypeName)
		Log:var("mixtureFillTypeName", mixtureFillTypeName)
		Log:var("mixtureShouldBeReplaced", mixtureShouldBeReplaced)

		if not mixtureShouldBeReplaced then
			-- We can simply exit since mixture shouldn't be replaced (basegame code will later take care of additional validation)
			return false
		end


		-- mixtureShouldBeReplaced = mixtureShouldBeReplaced and (animalTypeName ~= nil and mixtureFillTypeName ~= nil)

		if animalTypeName == nil or mixtureFillTypeName == nil then
			-- Something is wrong, however we can silent exit since the basegame add mixtures code will take care of the validation anyway
			return false
		end

		local mixtureFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(mixtureFillTypeName)

		-- Log:var("mixtureFillTypeIndex", mixtureFillTypeIndex)
		-- Log:var("mixtureFillTypeIndexToMixture[mixtureFillTypeIndex]", self.mixtureFillTypeIndexToMixture[mixtureFillTypeIndex])


		-- mixtureShouldBeReplaced = mixtureShouldBeReplaced and (mixtureFillTypeIndex ~= nil and self.mixtureFillTypeIndexToMixture[mixtureFillTypeIndex] ~= nil)

		if mixtureFillTypeIndex == nil or self.mixtureFillTypeIndexToMixture[mixtureFillTypeIndex] == nil then
			-- Something is wrong, however we can silent exit since the basegame add mixtures code will take care of the validation anyway
			return false
		end

		local animalTypeIndex = self.mission.animalSystem:getTypeIndexByName(animalTypeName)

		Log:var("animalTypeIndex", animalTypeIndex)
		Log:var("self.animalMixtures[animalTypeIndex]", self.animalMixtures[animalTypeIndex])
		-- Log:table("AnimalFoodSystem.self:", self)
		-- Log:table("g_currentMission.animalSystem", g_currentMission.animalSystem)


		local mixture = self.mixtureFillTypeIndexToMixture[mixtureFillTypeIndex]

		-- Remove actual mixture and reindex remaining mixtures
		if mixture ~= nil then
			table.remove( self.mixtures, mixture.index)

			for index, value in ipairs(self.mixtures) do
				value.index = index
			end
		end

		if self.animalMixtures ~= nil and self.animalMixtures[animalTypeIndex] ~= nil then
			local animalMixtures = self.animalMixtures[animalTypeIndex]
			-- Log:var("self.animalMixtures["  .. animalTypeIndex .. "]", animalMixtures)
			-- Log:table("self.animalMixtures["  .. animalTypeIndex .. "]", animalMixtures)
			-- Log:table("self.animalMixtures", self.animalMixtures)

			-- If mixtureFillTypeIndex is found in the table, remove that specific table entry (fill type index) and exit loop. This will remove the reference between the specific fill type and the animal type.
			for index, fillTypeIndex in ipairs(animalMixtures) do
				
				if fillTypeIndex == mixtureFillTypeIndex then
					table.remove(animalMixtures, index)
					Log:debug("Removed reference between animal type '%s' and mixture filltype '%s'", animalTypeName, mixtureFillTypeName)
					break
				end
			end

			-- Log:table("self.animalMixtures["  .. animalTypeIndex .. "]", self.animalMixtures[animalTypeIndex])
			-- 	Log:table("XX g_currentMission.animalSystem.animalMixtures["  .. animalTypeIndex .. "]", g_currentMission.animalSystem.animalMixtures[animalTypeIndex])

		end

		-- Reset index to current mixture
		self.mixtureFillTypeIndexToMixture[mixtureFillTypeIndex] = nil

		Log:info("Disabled existing mixture filltype '%s' for animal type '%s' (allows this mixture to be replaced later)", mixtureFillTypeName, animalTypeName)		
	end

	xmlFile:iterate("animalFood.mixtures.mixture", function (_, key)
		allowReplacingMixture(key)
	end)

	return true
end


function AnimalFoodSystem:allowReplacingRecipes(xmlFile)
	xmlFile:iterate("animalFood.recipes.recipe", function (_, key)
		local recipeFillTypeName = xmlFile:getValue(key .. "#fillType")
        local recipeShouldBeReplaced = xmlFile:getBool(key .. "#replace", false)

		if recipeFillTypeName == nil then
			-- Logging.xmlError(xmlFile, "Missing fillType for recipe '%s'", key)

			return false
		end

		local recipeFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(recipeFillTypeName)

		if recipeFillTypeIndex == nil then
			-- Logging.xmlError(xmlFile, "Recipe filltype '%s' not defined for '%s'", recipeFillTypeName, key)

			return false
		end

		if self.recipeFillTypeIndexToRecipe[recipeFillTypeIndex] ~= nil and recipeShouldBeReplaced == true then

			-- Remove actual recipe
			local recipe = self.recipeFillTypeIndexToRecipe[recipeFillTypeIndex]
			table.remove(self.recipes, recipe.index)
			-- 	table.insert(self.recipes, recipe)

			-- Reset ferences
			self.disabledRecipeFillTypeIndexToRecipe = self.disabledRecipeFillTypeIndexToRecipe or {}
			self.disabledRecipeFillTypeIndexToRecipe[recipeFillTypeIndex] = self.recipeFillTypeIndexToRecipe[recipeFillTypeIndex]
			self.recipeFillTypeIndexToRecipe[recipeFillTypeIndex] = nil
			
            Log:info("Disabled existing animal food recipie filltype '%s' (allows this recipie to be 'replaced'/added later)", recipeFillTypeName)
		end

		-- local recipe = {}

		-- if self:loadRecipe(recipe, xmlFile, key) then
		-- 	recipe.index = #self.recipes + 1
		-- 	recipe.fillType = recipeFillTypeIndex

		-- 	table.insert(self.recipes, recipe)

		-- 	self.recipeFillTypeIndexToRecipe[recipeFillTypeIndex] = recipe
		-- end
	end)

	return true
end

-- DensityMapHeightManager.loadMapData = Utils.appendedFunction(DensityMapHeightManager.loadMapData, function(xmlFile, missionInfo, baseDirectory)
--     Log:debug("Loading DensityMapHeightManager mapExtension data for mod %s", g_currentModName)

--     -- Hack to fix a "bug"(?) where l10n texts doesn't load from mod
--     -- local oldCustomEnvironment = missionInfo.customEnvironment
--     -- missionInfo.customEnvironment = oldCustomEnvironment or g_currentModName

--     local modDescFilename = Utils.getFilename("modDesc.xml", g_currentModDirectory)
--     local modXmlFile = loadXMLFile("mapDataXML", modDescFilename)

-- 	return FillTypeManager:loadDataFromModXML(modXmlFile, "extendedDensityMapHeightTypes", g_currentModDirectory, g_densityMapHeightManager, DensityMapHeightManager.loadDensityMapHeightTypes, missionInfo, g_currentModDirectory)
-- end)

-- FillTypeManager.loadMapData = Utils.appendedFunction(FillTypeManager.loadMapData, function(fillTypeManager, mapXmlFile, missionInfo, baseDirectory)
--     Log:debug("Loading FillTypeManager mapExtension data for mod %s", g_currentModName)

--     --HACK: Hack to fix a "bug"(?) where l10n texts doesn't load from mod
--     local oldCustomEnvironment = missionInfo.customEnvironment
--     missionInfo.customEnvironment = oldCustomEnvironment or g_currentModName

--     local modDescFilename = Utils.getFilename("modDesc.xml", g_currentModDirectory)
--     local modXmlFile = loadXMLFile("mapDataXML", modDescFilename)
--     local success = false

--     if FillTypeManager:loadDataFromModXML(modXmlFile, "extendedFillTypes", g_currentModDirectory, g_fillTypeManager, FillTypeManager.loadFillTypes, missionInfo, g_currentModDirectory, false) then
--         g_fillTypeManager:constructFillTypeTextureArrays()
--         -- Log:info("Loaded filltypes from '%s'", modDescFilename)
--         -- return true
--         success = true
--     end

--     if modXmlFile ~= nil then
--         delete(modXmlFile)
--     end

--     missionInfo.customEnvironment = oldCustomEnvironment -- Cleanup the "hack"

--     return success
-- end)


