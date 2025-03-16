--[[

Store Item Extesion (Weezls Mod Lib for FS22) - Utility class to alter store items using fluent "filters"

Author:     w33zl (github.com/w33zl)
Version:    1.0
Modified:   2024-06-16

COPYRIGHT:
You may not redistribute the script, in original or modified state, unless you have explicit permission from the author (i.e. w33zl).

However, contact me (WZL Modding) on Facebook and I -will- happily grant you permission to use and redistribute the script! I just want to know how, and by who, the script is being used <3

]]


local function stringMatch(s1, s2)
	return (string.find(s1, s2, 1, true) ~= nil);
end--function
        
MatchableItem = {}
MatchableItem.__index = MatchableItem

function MatchableItem:updateResultAndReturn(nameOfMethod, testValue, wasMatch)
    self.lastMatchFailed = not wasMatch

    self:logResult(nameOfMethod .. " [" .. tostring(testValue) .. "]", wasMatch);

    return self
end

function MatchableItem:new(storeItem)
    local matchedStoreItem = {}
    setmetatable(matchedStoreItem, MatchableItem)
    matchedStoreItem.storeItem = storeItem
    matchedStoreItem.lastMatchFailed = matchedStoreItem.storeItem == nil
    return matchedStoreItem
end--function

function MatchableItem:match()
    local matchedStoreItem = {}
    setmetatable(matchedStoreItem, MatchableItem)
    matchedStoreItem.storeItem = self.storeItem
    matchedStoreItem.lastMatchFailed = matchedStoreItem.storeItem == nil
    --TODO: add blacklist/exclusions
    return matchedStoreItem
end--function

function MatchableItem:logResult(name, result)

    self.log = (self.log or "");

    if self.log ~= "" then
        self.log = self.log .. " > ";
    end--if

    self.log = self.log .. name .. "=" .. tostring(result);
end--function


function MatchableItem:debugWarning(message)
    -- if not DEBUG_MODE then return end

    self:debug("Warning: " .. message);
end--function

function MatchableItem:debug(message)
    -- if not DEBUG_MODE then return end

    Log:debug("MATCHED DEBUG: " .. message);
end--function


function MatchableItem:hasName(itemName, exactMatch)

    if self.lastMatchFailed == true then
        return self;
    end--if

    local fixedStoreName = string.lower(self.storeItem.name);
    local fixedName = string.lower(itemName);

    exactMatch = (exactMatch or false) and true
    
    local function doMatch()
        if exactMatch == true then
            return fixedStoreName == fixedName
        else 
            return stringMatch(fixedStoreName, fixedName)
        end
    end
    local isMatch = doMatch()

    self.lastMatchFailed = not isMatch;

    self:logResult("hasName '" .. itemName .. "'", isMatch);

    return self;
end--function



--TODO: addSpec

--TODO: duplicate

--TODO: hasBrand
function MatchableItem:hasBrand(brandName)
    if self.lastMatchFailed == true then return self end--if

    local storeItem = self.storeItem

    -- Log:var("g_brandManager", g_brandManager)
    -- Log:var("g_brandManager.nameToIndex", g_brandManager.nameToIndex)

    local matchedBrandIndex = (g_brandManager ~= nil and g_brandManager.nameToIndex ~= nil) and g_brandManager.nameToIndex[brandName]

    -- Log:var("matchedBrandIndex", matchedBrandIndex)

    local isMatch = matchedBrandIndex ~= nil and storeItem.brandIndex == matchedBrandIndex


    -- brandIndex

    -- self.lastMatchFailed = not isMatch;

    -- self:logResult("hasName '" .. itemName .. "'", isMatch);

    -- return self;

    return self:updateResultAndReturn("hasBrand", brandName, isMatch)

end--function


--TODO: changeBrand / newBrand
function MatchableItem:changeBrand(newBrand)
    if self.lastMatchFailed == true then return self end--if

    local wasSuccess = false

    if newBrand ~= nil and newBrand ~= "" then -- and g_storeManager:getCategoryByName(newCategory) ~= nil then

        local newBrandIndex = (g_brandManager ~= nil and g_brandManager.nameToIndex ~= nil) and g_brandManager.nameToIndex[newBrand]
        
        self.storeItem.brandIndex = newBrandIndex or self.storeItem.brandIndex -- Set to new index or fallback to the existing value

        wasSuccess = (newBrandIndex ~= nil)
    end

    return self:updateResultAndReturn("changeBrand", newBrand, wasSuccess)
    -- else
    --     self.lastMatchFailed = true;
    --     self:debugWarning("Could not find category '" .. newCategory .. "', aborting move!");
    -- end--if

    -- self:logResult("moveTo", not self.lastMatchFailed);

    -- return self;
end--function


function MatchableItem:isBaseGame()
    if self.lastMatchFailed == true then return self end--if

    local isMatch = (self.storeItem.customEnvironment == nil or self.storeItem.customEnvironment == "");

    self.lastMatchFailed = not isMatch;

    self:logResult("isBaseGame", isMatch);

    return self;
end--function	

function MatchableItem:isMod(modName)
    if self.lastMatchFailed == true then return self end--if

    local isMatch = false;
    
    if modName ~= nil and modName ~= "" then
        if self.storeItem.customEnvironment ~= nil and self.storeItem.customEnvironment ~= "" then
            local fixedStoreModName = string.lower(self.storeItem.customEnvironment);
            local fixedModName = string.lower(modName);
            isMatch = stringMatch(fixedStoreModName, fixedModName);
        end--if
    else
        self:debugWarning("Parameter 'modName' is required!");
    end--if

    self.lastMatchFailed = not isMatch;

    self:logResult("isMod '" .. modName .. "'", isMatch);

    return self;
end--function

function MatchableItem:anyMod()
    if self.lastMatchFailed == true then return self end--if

    local isMatch = (self.storeItem.customEnvironment ~= nil and self.storeItem.customEnvironment ~= "")
    
    return self:updateResultAndReturn("anyMod", "", isMatch)
end--function

function MatchableItem:inCategory(category)
    if self.lastMatchFailed == true then return self end--if

    local isMatch = false;
    
    if category ~= nil and category ~= "" then
        local fixedStoreCategoryName = string.upper(self.storeItem.categoryName);
        local fixedMatchCategoryName = string.upper(category);
        isMatch = (fixedStoreCategoryName == fixedMatchCategoryName);
    else
        self:debugWarning("Parameter 'category' is required!");
    end--if

    self.lastMatchFailed = not isMatch;

    self:logResult("inCategory '" .. category .. "'", isMatch);

    return self;
end--function

function MatchableItem:hasFilename(filename)
    if self.lastMatchFailed == true then return self end--if

    local isMatch = false;
    
    if filename ~= nil and filename ~= "" then
        local fixedStoreFileName = string.lower(self.storeItem.xmlFilenameLower);
        local fixedMatchFileName = string.lower(filename);
        if fixedMatchFileName:sub(-4) ~= ".xml" then
            fixedMatchFileName = fixedMatchFileName .. ".xml";
        end--if
        isMatch = stringMatch(fixedStoreFileName, fixedMatchFileName);
    else
        self:debugWarning("Parameter 'filename' is required!");
    end--if

    self.lastMatchFailed = not isMatch;

    self:logResult( "hasFilename '" .. filename .. "'", isMatch);

    return self;
end--function

function MatchableItem:hasSpecs(specs)
    if self.lastMatchFailed == true then return self end--if

    local isMatch = false;
    
    if specs ~= nil and specs ~= "" then
        local storeItem = self.storeItem;

        if storeItem ~= nil and storeItem.specs ~= nil and storeItem.specs.combination ~= nil then
            local fixedSpecsList = string.lower(storeItem.specs.combination);
            local fixedMatchSpecs = string.lower(specs);
            isMatch = stringMatch(fixedSpecsList, fixedMatchSpecs);
        end--if

    else
        self:debugWarning("Parameter 'specs' is required!");
    end--if

    self.lastMatchFailed = not isMatch;

    self:logResult("hasSpecs '" .. specs .. "'", isMatch);

    return self;
end--function

function MatchableItem:getSpecType(specTypeName)

    local specTypePassiveIncome = g_storeManager:getSpecTypeByName(specTypeName)
    local success, passiveIncome = pcall(specTypePassiveIncome.getValueFunc, self.storeItem)

    if success then
        return passiveIncome
    else
        return nil
    end
end

function MatchableItem:hasCombo(name)
    if self.lastMatchFailed == true then return self end--if

    local combination = self:getSpecType("combination")
    local isMatch = false
    
    if combination ~= nil then
        local fixedStoreComboList = string.lower(combination);
        local fixedMatchComboList = string.lower(name);
        isMatch = stringMatch(fixedStoreComboList, fixedMatchComboList);
    end

    self.lastMatchFailed = not isMatch;

    self:logResult("hasCombo", isMatch);

    return self;
end

function MatchableItem:hasFilltype(...)
    if self.lastMatchFailed == true then return self end--if

    local isMatch = false
    local fillTypeList = {...}

    Log:debug(self.storeItem.name)

    Log:table("self.storeItem", self.storeItem, 1)

    

    -- -- if type(fillTypeNames) == "string" then
    -- --     Log:var("Matching single item", fillTypeNames)
    -- --     fillTypeList = { fillTypeNames }
    -- -- else
    -- --     Log:var("Matching multiple items", fillTypeNames)
    -- --     fillTypeList = fillTypeNames
    -- -- end



    -- if type(fillTypeList) == "table" then

    --     -- local fillTypes = self:getSpecType("fillTypes")
    --     local fillTypes = self.storeItem.specs ~= nil and self.storeItem.specs.fillTypes

    --     -- Log:table(fillTypes)
        

    --     -- Log:var("Checking filltype '" .. name .. "'", fillTypes)

    --     -- if fillTypes ~= nil then
    --     --     DebugUtil.printTableRecursively(fillTypes, "fillTypes:: ", 0, 2)
    --     --     -- Log:var("fillTypes.useWindrowed", fillTypes.useWindrowed)
    --     --     -- Log:var("fillTypes.fillTypeNames", fillTypes.fillTypeNames)
    --     -- end

    --     local namesInStore = fillTypes ~= nil and (fillTypes.categoryNames or fillTypes.fillTypeNames)

        
    --     if fillTypes ~= nil and namesInStore ~= nil then
    --         Log:var("namesInStore", namesInStore)
    --         local fixedStoreFillTypeNameList = string.lower(namesInStore);
            
    --         for _,v in ipairs(fillTypeList) do
    --             local fixedMatchFillTypeName = string.lower(v);
    --             local isThisMatch = stringMatch(fixedStoreFillTypeNameList, fixedMatchFillTypeName)
    --             isMatch = isMatch or isThisMatch
    --             Log:var("Comparing '" .. fixedMatchFillTypeName .. "' == '" .. fixedStoreFillTypeNameList .. "'", isThisMatch)
    --         end
            
    --         -- Log:var("isMatch", isMatch)
    --     end
    -- end

    self.lastMatchFailed = not isMatch;

    self:logResult("hasFilltype", isMatch);

    return self;
end

function MatchableItem:hasAttacher(...)
    if self.lastMatchFailed == true then return self end--if

    local isMatch = false
    local combinationsList = {...}

    if type(combinationsList) == "table" then

        local combinations = self.storeItem.specs ~= nil and self.storeItem.specs.combination
        

        -- Log:var("Checking filltype '" .. name .. "'", fillTypes)

        -- if fillTypes ~= nil then
        --     DebugUtil.printTableRecursively(fillTypes, "fillTypes:: ", 0, 2)
        --     -- Log:var("fillTypes.useWindrowed", fillTypes.useWindrowed)
        --     -- Log:var("fillTypes.fillTypeNames", fillTypes.fillTypeNames)
        -- end

        -- local namesInStore = combinations ~= nil and (combinations.categoryNames or combinations.fillTypeNames)

        
        if combinations ~= nil then
            Log:var("combinations", combinations)
            -- local fixedStoreFillTypeNameList = string.lower(combinations);
            
            -- for _,v in ipairs(combinationsList) do
            --     local fixedMatchFillTypeName = string.lower(v);
            --     Log:var("Comparing '" .. fixedMatchFillTypeName .. "'", fixedStoreFillTypeNameList)
            --     isMatch = isMatch or stringMatch(fixedMatchFillTypeName, fixedStoreFillTypeNameList);
            -- end
            
        end
    end

    self.lastMatchFailed = not isMatch;

    self:logResult("hasAttacher", isMatch);

    return self;
end

--TODO: add to hasXxxx()
-- 		specs :: table: 0x019ef7b98938
-- 2020-07-08 20:29 .        seedFillTypes :: table: 0x019ef69579d0
-- 2020-07-08 20:29 .        fillTypes :: table: 0x019ef6672af8
-- 2020-07-08 20:29 .        fuel :: table: 0x019ef6672a00
-- 2020-07-08 20:29 .        capacity :: table: 0x019ef6672ab0
-- 2020-07-08 20:29 .        workingWidthVar :: table: 0x019ef73627d8
-- 2020-07-08 20:29 .        incomePerHour :: table: 0x019ef7027ec8
-- 2020-07-08 20:29 .707 :: table: 0x019ef6782120
-- 2020-07-08 20:29 .    specs :: table: 0x019ef77e1560
-- 2020-07-08 20:29 .        seedFillTypes :: table: 0x019ef6782200
-- 2020-07-08 20:29 .        fillTypes :: table: 0x019ef6c4d000
-- 2020-07-08 20:29 .        capacity :: table: 0x019ef6c4d068
-- 2020-07-08 20:29 .        power :: 200
-- 2020-07-08 20:29 .        fuel :: table: 0x019ef73c61d0
-- 2020-07-08 20:29 .        maxSpeed :: 80
-- 2020-07-08 20:29 .        workingWidthVar :: table: 0x019ef6938a18
-- 2020-07-08 21:27 [ATidierStore] Passive income :: Greenhouse : cucumber
-- 2020-07-08 21:27   loadFunc :: function: 0x01c6d7c84200
-- 2020-07-08 21:27   getValueFunc :: function: 0x01c6d7c83928
-- 2020-07-08 21:27   name :: incomePerHour
-- 2020-07-08 21:27   profile :: shopListAttributeIconIncomePerHour
-- 2020-07-08 21:27   seedFillTypes :: table: 0x01c6b86487f8
-- 2020-07-08 21:27   fillTypes :: table: 0x01c6b726ed60
-- 2020-07-08 21:27       useWindrowed :: false
-- 2020-07-08 21:27   fuel :: table: 0x01c6b2ce9510
-- 2020-07-08 21:27       fillUnits :: table: 0x01c6b86488b0
-- 2020-07-08 21:27       consumers :: table: 0x01c6b86488f8
-- 2020-07-08 21:27   capacity :: table: 0x01c6b726ed18
-- 2020-07-08 21:27   workingWidthVar :: table: 0x01c6b726eda8
-- 2020-07-08 21:27   incomePerHour :: table: 0x01c6bcf50598
-- 2020-07-08 21:27       1 :: 88
-- 2020-07-08 21:27       2 :: 56
-- 2020-07-08 21:27       3 :: 14

function MatchableItem:hasPassiveIncome()
    if self.lastMatchFailed == true then return self end--if

    local passiveIncome = self:getSpecType("incomePerHour")
    local isMatch = passiveIncome ~= nil

    self.lastMatchFailed = not isMatch;

    self:logResult("hasPassiveIncome", isMatch);

    return self;
end--function	

function MatchableItem:hasPower(min, max)
    if self.lastMatchFailed == true then return self end--if
end

local function removeCategoryFromArray(storeItem, newCategory)
    for i, category in ipairs(storeItem.categoryNames) do
        if category == newCategory then
            table.remove(storeItem.categoryNames, i)
            break
        end
    end
end


function MatchableItem:moveTo(newCategory)
    if self.lastMatchFailed == true then return self end--if

    if newCategory ~= nil and newCategory ~= "" and g_storeManager:getCategoryByName(newCategory) ~= nil then


        -- storeItem.categoryNames

        -- Log:var("self.storeItem.categoryName:before", self.storeItem.categoryName)
        -- removeCategoryFromArray(self.storeItem, self.storeItem.categoryName)
        -- self.storeItem.categoryName = string.upper(newCategory);
        -- Log:var("self.storeItem.categoryName:after", self.storeItem.categoryName)
        local newCategory = string.upper(newCategory)
        self.storeItem.categoryNames = { newCategory }
        self.storeItem.categoryName = newCategory --self.storeItem.categoryNames[1]

    else
        self.lastMatchFailed = true;
        self:debugWarning("Could not find category '" .. newCategory .. "', aborting move!");
    end--if

    self:logResult("moveTo", not self.lastMatchFailed);

    return self;
end--function

function MatchableItem:addTo(newCategory)
    if self.lastMatchFailed == true then return self end--if

    if newCategory ~= nil and newCategory ~= "" and g_storeManager:getCategoryByName(newCategory) ~= nil then
        local newCategory = string.upper(newCategory)
        --TODO: add check if category already exists?
        table.insert( self.storeItem.categoryNames, newCategory )
    else
        self.lastMatchFailed = true;
        self:debugWarning("Could not find category '" .. newCategory .. "', no category added!");
    end--if

    self:logResult("addTo", not self.lastMatchFailed);

    return self;
end--function

function MatchableItem:newCategory(newCategory)
    self:moveTo(newCategory);
end

function MatchableItem:dump(onlyIfMatch, alsoDumpStoreItem)
    
    if onlyIfMatch and self.lastMatchFailed == true then return self end--if

    local matchString

    if self.lastMatchFailed then 
        matchString = "NOT a"
    else 
        matchString = "a"
    end

    self:debug(string.format( "MatchableItem:: Name='%s' | Category=%s | Filename='%s' was %s match: %s", self.storeItem.name, self.storeItem.categoryName, self.storeItem.xmlFilenameLower, matchString, self.log));

    if alsoDumpStoreItem then
        DebugUtil.printTableRecursively(self.storeItem, "MatchableItem.storeItem:: ", 0, 2)
    end

    return self;
end--function

function MatchableItem:rename(newName)
    if self.lastMatchFailed == true then return self end--if

    if newName ~= nil and newName ~= "" then
        self.storeItem.name = newName;
    end;

    return self
end--function

function MatchableItem:hideInStore()
    if self.lastMatchFailed == true then return self end--if

    self.storeItem.showInStore = false

    return self
end--function

function MatchableItem:addSuffix(suffix)
    if self.lastMatchFailed == true then return self end--if

    if suffix ~= nil and suffix ~= "" then
        self.storeItem.name = self.storeItem.name .. suffix;
    end

    return self
end--function

function MatchableItem:fixDlcTitle(forceChange)
    if self.lastMatchFailed == true then return self end--if

    forceChange = forceChange or true

    local modName = self.storeItem.customEnvironment or ""
    local shouldUpdate = (modName ~= "") and (self.storeItem.isMod or forceChange)

    if shouldUpdate then
        modName = modName:gsub("FS19_", "")
        modName = modName:gsub("LS19_", "")
        modName = modName:gsub("_", " ")
        self.storeItem.dlcTitle = modName
        self.storeItem.isMod = false
    end

    --TODO: change title

    return self
end--function


function MatchableItem:updateModTitle(force)
    if self.lastMatchFailed == true then return self end--if

    force = (force == nil or force) -- Default to true


    local shouldUpdate = false
    local modName = self.storeItem.customEnvironment

    if self.storeItem.isMod or (modName ~= nil and modName ~= "") then
        
        local modTitle = self.storeItem.dlcTitle
        shouldUpdate = (modTitle == "") or force

        Log:var("updateModTitle.shouldUpdate", shouldUpdate)
        Log:var("updateModTitle.force", force)

        if shouldUpdate then

            
            local xmlFilename = self.storeItem.xmlFilename
            
            Log:var("updateModTitle.modName", modName)
            Log:var("updateModTitle.xmlFilename", xmlFilename)

            -- Use cache to prevent unnecessary file access
            TidyShop.modTitleCache = TidyShop.modTitleCache or {}
            local cachedTitle = TidyShop.modTitleCache[modName]

            Log:var("updateModTitle.cachedTitle", cachedTitle)

            if cachedTitle == nil or cachedTitle == "" then
                
                cachedTitle = getModTitle(modName)
                TidyShop.modTitleCache[modName] = cachedTitle -- Save to cache to prevent unnecessary file access
                Log:var("updateModTitle.cachedTitle:read", cachedTitle)
            end

            self.storeItem.dlcTitle = cachedTitle
            self.storeItem.isMod = false
            
        end
    end

    self:logResult("updateModTitle", shouldUpdate)

    return self
end--function
