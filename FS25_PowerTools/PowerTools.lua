--[[
Power Tools for FS22

Author:     w33zl / WZL Modding (github.com/w33zl)
Version:    2.0.0b
Modified:   2024-11-12

Changelog:
]]

PowerTools = Mod:init()

-- PowerTools:enableDebugMode()

local ACTION = {
    SPAWN_PALLET = 1,
    SPAWN_BALE = 2,
    SPAWN_LOG = 3,
    HIDE_HUD = 4,
    SUPERMAN_MODE = 5,
    TIP_TO_GROUND = 6,
    FLIGHT_MODE = 7,
}

local RESTART_MODE = {
    UNKNOWN = 0,
    EXIT = 1,
    EXIT_FORCED = 2,
    RESTART = 3,
    RESTART_FORCED = 4,
    QUIT_TO_DESKTOP = 5,
}

FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, function()
    local triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings = false, true, false, true, nil, true
    local state, actionEventId, otherEvents = g_inputBinding:registerActionEvent(InputAction.POWERTOOLSMENU, PowerTools, PowerTools.showMenu, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings)
    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
    local state, actionEventId, otherEvents = g_inputBinding:registerActionEvent(InputAction.POWERTOOLS_QUICKSAVE, PowerTools, PowerTools.saveGame, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings)
    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
    g_inputBinding:setActionEventTextVisibility(actionEventId, false) -- INFO: change "false" to "true" to show keybinding in help window
    local state, actionEventId, otherEvents = g_inputBinding:registerActionEvent(InputAction.POWERTOOLS_REPEAT_ACTION, PowerTools, PowerTools.repeatLastAction, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings)
    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
    g_inputBinding:setActionEventTextVisibility(actionEventId, false) -- INFO: change "false" to "true" to show keybinding in help window
end)

FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, function()
    if PowerTools ~= nil then
        if PowerTools.delete ~= nil then
            PowerTools:delete()
        end
        removeModEventListener(PowerTools)
        PowerTools = nil -- GC
    end
end)


function PowerTools:showMenu()
    self.lastAction = nil

    local useAltMode = Utils.getNoNil(Input.isKeyPressed(Input.KEY_rctrl), false)
    local isInVehicle = g_currentMission.controlledVehicle ~= nil

    local actionFillVehicle = { g_i18n:getText("fillVehicle"), self.fillVehicle }
    local actionTipOnGround = { g_i18n:getText("tipOnGround"), self.tipToGround }
    local actionSpawnBale = { g_i18n:getText("spawnObjectsActionTitle"), self.spawnObjects }

    local actionRestart = { g_i18n:getText("restartMode"), self.menuActionRestartGame }
    local actionExit = { g_i18n:getText("exitMode"), self.menuActionExitSavegame }

    if useAltMode then
        actionRestart = { g_i18n:getText("forcedRestartMode"), self.menuActionForceRestartGame }
        actionExit = { g_i18n:getText("forcedExitMode"), self.menuActionForceExitSavegame }
    end

    local actions = {
        -- (isInVehicle == true and actionFillVehicle) or actionTipOnGround,
        { g_i18n:getText("superStrengthMode"), self.toggleSuperStrength },
        { g_i18n:getText("flightMode"), self.toggleFlightMode },
        { g_i18n:getText("noHudMode"), self.toggleHUDMode },
        { g_i18n:getText("changeMoneyMode"), self.addRemoveMoney },
        { g_i18n:getText("saveGame"), self.saveGame },
        actionExit,
        actionRestart,
    }

    if self:getIsMultiplayer() then
        Log:info("Running in multiplayer mode, some features will be disabled [isMaster=%s, isServer=%s, isAdmin=%s, isFarmAdmin=%s]", self:getIsMasterUser(), self:getIsServer(), self:getHasFarmAdminAccess(), self:getIsValidFarmManager())
    end

    --TODO: replace when TipOnGround works
    if self:getIsServer() then --NOTE: only allowed on the server host for now, maybe change in the future
        if isInVehicle == true then
            table.insert( actions, 1, actionFillVehicle )
        else
            table.insert( actions, 1, actionSpawnBale )
        end
    end

    local options = {}
    for index, value in ipairs(actions) do
        options[#options + 1] = index .. ") " .. value[1]
    end

    local dialogArguments = {
        text = g_i18n:getText("chooseAction"),
        title = g_i18n:getText("powerTools"),
        options = options,
        target = self,
        args = { },
        callback = function(target, selectedOption, a)
            if type(selectedOption) ~= "number" or selectedOption == 0 then
                return
            end

            local delegate = actions[selectedOption][2]

            delegate(self)
        end,
    }

    --TODO: hack to reset the "remembered" option (i.e. solve a bug in the game engine)
    local dialog = g_gui.guis["OptionDialog"]
    if dialog ~= nil then
        dialog.target:setOptions({""}) -- Add fake option to force a "reset"
    end

    g_gui:showOptionDialog(dialogArguments)
    

end

function PowerTools:showSubMenu(text, title, defaultOption, actions)
    local options = {}
    for index, value in ipairs(actions) do
        options[#options + 1] = index .. ") " .. value[1]
    end

    self:showOptionDialog(
        text, 
        title, 
        options,
        function(target, selectedOption, a)
            if type(selectedOption) ~= "number" or selectedOption == 0 then
                return
            end

            local delegate = actions[selectedOption][2]
            local args = actions[selectedOption][3] or {}

            delegate(self, unpack(args))
        end,
        true
    )
end

function PowerTools:repeatLastAction()
    Log:var("Repeat action", self.lastAction)
    if self.lastAction == nil then return end

    Log:var("Repeat action type", self.lastAction.actionType)

    local lastAction = self.lastAction
    local targetObject = lastAction.targetObject
    local targetCommand = lastAction.targetCommand
    local payload = lastAction.payload

    if targetObject ~= nil and targetCommand ~= nil and type(targetCommand) == "function" then
        Log:var("Executing repeating action on object", targetObject)

        targetCommand(targetObject, unpack(payload))
    end

    

end

function PowerTools:tipToGround()

end


function PowerTools:toggleSuperStrength()
    g_currentMission.player:consoleCommandToggleSuperStrongMode()

    if g_currentMission.player.superStrengthEnabled then
        g_currentMission:addGameNotification(g_i18n:getText("superStrength") .. ": " .. g_i18n:getText("enabled"), "", "")
    else
        g_currentMission:addGameNotification(g_i18n:getText("superStrength") .. ": " .. g_i18n:getText("disabled"), "", "")
    end

    self:saveAction(ACTION.SUPERMAN_MODE, self,PowerTools.toggleSuperStrength, {} )

end

function PowerTools:toggleHUDMode()
    g_currentMission.hud:consoleCommandToggleVisibility()
    -- g_currentMission.hud.isVisible = not (g_currentMission.hud.isVisible or false)  -- thirdPersonViewActive

    self:saveAction(ACTION.HIDE_HUD, self,PowerTools.toggleHUDMode, {} )
end

function PowerTools:toggleFlightMode()
    g_currentMission.player:consoleCommandToggleFlightMode()

    if g_flightModeEnabled then
        g_currentMission:addGameNotification(g_i18n:getText("flightMode") .. ": " .. g_i18n:getText("enabled"), g_i18n:getText("flightModeUsage"), "", 2500)
        g_currentMission.player.debugFlightModeWalkingSpeed = 0.032
        g_currentMission.player.debugFlightModeRunningFactor = 4

        PowerTools.maxWalkingSpeed = PowerTools.maxWalkingSpeed or g_currentMission.player.motionInformation.maxWalkingSpeed
        g_currentMission.player.motionInformation.maxWalkingSpeed = 12
    
        g_currentMission.player:onInputDebugFlyToggle()
    else
        g_currentMission:addGameNotification(g_i18n:getText("flightMode") .. ": " .. g_i18n:getText("disabled"), "", "", 1500)
        g_currentMission.player.motionInformation.maxWalkingSpeed = PowerTools.maxWalkingSpeed or g_currentMission.player.motionInformation.maxWalkingSpeed
        PowerTools.maxWalkingSpeed = nil
    end

    self:saveAction(ACTION.FLIGHT_MODE, self,PowerTools.toggleFlightMode, {} )
end

function PowerTools:addRemoveMoney()
    if not self:validateMPFarmAdmin() then return end

    local dialogArguments = {
        text = g_i18n:getText("changeMoneyMode"):upper() .. ":\n\n" .. g_i18n:getText("changeMoneyUsage"):gsub("\\\\n", "\n"),
        target = self, 
        defaultText = "", 
        maxCharacters = 10, 
        args = {}, 
        disableFilter = true,
        confirmText = g_i18n:getText("changeMoneyMode"),
        backText = g_i18n:getText("buttonCancel"),
    }

    dialogArguments.callback = function(target, value, arguments)
        if value == nil or value == "" then return end

        local function addMoney(amount, isAbsolute)
            local moneyChange = amount

            if isAbsolute then
                local farm = g_farmManager:getFarmById(g_currentMission.player.farmId)
                local refMoney = farm.money
                moneyChange = amount - refMoney
            end

            g_currentMission:consoleCommandCheatMoney(moneyChange);

        end

        local numericValue, isExact = 0, false

        if value:find("=") == 1 then
            value = value:sub(2, -1)
            isExact = true
        end

        numericValue = tonumber(value)

        if numericValue ~= nil and type(numericValue) == "number" then
            addMoney(numericValue, isExact)
        else
            g_currentMission:showBlinkingWarning(g_i18n:getText("errorNotNumeric") .. tostring(value))
        end
    end

    g_gui:showTextInputDialog(dialogArguments)
end


-- function PowerTools:consoleCommandDumpTableToFile(tableName, filename)
--     local function printUsage()
--         PowerTools:printInfo("USAGE: ptSaveTable tableName filename [depth]")
--     end
--     if tableName == nil or type(tableName) ~= "string" then
--         PowerTools:printError("Parameter tableName can not be empty!\n")
--         printUsage()
--         return
--     end
-- local debugTable = loadstring("return " .. tableName)

--     local tableFile = getUserProfileAppPath() .. filename
-- 	local file = io.open(tableFile, "w")
--if file ~= nil then
--file:write(header .. "\n")
--file:close()
-- end

function PowerTools:consoleCommandPrintTable(tableName, depth)
    local function printUsage()
        PowerTools:printInfo("USAGE: ptTable tableName [depth]")
    end
    if tableName == nil or type(tableName) ~= "string" then
        PowerTools:printError("Parameter tableName can not be empty!\n")
        printUsage()
        return
    end

    depth = tonumber(depth) or 3

    if depth == nil or depth < 1 then
        PowerTools:printError("Optional parameter 'depth' must be a positive number!\n")
        printUsage()
        return
    end

    local debugTable = loadstring("return " .. tableName)

    if type(debugTable) == "function" then
        debugTable = debugTable()
    end

    if debugTable ~= nil and type(debugTable)== "table" then
        DebugUtil.printTableRecursively(debugTable, "debugTable:: ", 0, depth)
    else
        self:printError("Table '%s' could not be found", tableName)
    end
end




function PowerTools:showOptionDialog(text, title, options, callback, noReset)
    --TODO: hack to reset the "remembered" option (i.e. solve a bug in the game engine)
    local dialog = g_gui.guis["OptionDialog"]
    if dialog ~= nil and not noReset then
        dialog.target:setOptions({""}) -- Add fake option to force a "reset"
    end

    g_gui:showOptionDialog({
        text = text,
        title = title,
        defaultText = "",
        options = options,
        defaultOption = 1,
        target = self,
        args = { },
        callback = callback,
    })
end

function PowerTools:fillFillUnit(selectedFillUnit)
    if selectedFillUnit == nil then
        g_currentMission:showBlinkingWarning("No/invalid fillunit index")
        return
    end

    local options = {}
    local optionToFilltypeIndex = {}
    options[#options + 1] = g_i18n:getText("filltypeNone") --:upper()
    optionToFilltypeIndex[#optionToFilltypeIndex + 1] = 0


    for fillTypeIndex, _ in pairs(selectedFillUnit.supportedFillTypes) do
        local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)
        local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

        if fillType ~= nil and fillType.title ~= nil then
            fillTypeName = fillType.title
        end

        -- Log:table("FillType", g_fillTypeManager:getFillTypeByIndex(fillTypeIndex))

        if self.debugMode then fillTypeName = fillTypeName .. " [" .. tostring(fillTypeIndex) .. "]" end

        options[#options + 1] = fillTypeName
        optionToFilltypeIndex[#optionToFilltypeIndex + 1] = fillTypeIndex
    end

    if #options < 1 then
        g_currentMission:showBlinkingWarning(g_i18n:getText("errorNoValidFilltypes"))
        return
    end


    local dialogArguments = {
        text = g_i18n:getText("selectFillType"),
        title = g_i18n:getText("fillVehicle"),
        -- okTexr = "Spara",
        options = options,
        target = self,
        args = { },
        callback = function(target, selectedOption, a)

            PowerTools:printDebugVar("selectedOption", selectedOption)
            if selectedOption > 0 then

                local selectedFillUnitIndex = selectedFillUnit.fillUnitIndex
                local selectedFillTypeIndex = optionToFilltypeIndex[selectedOption]
                local amount = selectedFillUnit.capacity or 1000

                PowerTools:printDebugVar("selectedFillUnit.capacity", selectedFillUnit.capacity)
                PowerTools:printDebugVar("selectedFillTypeIndex", selectedFillTypeIndex)

                -- Clean first...
                local currentFillTypeIndex = selectedFillUnit.fillType or selectedFillUnit.supportedFillTypes[1]
                FSBaseMission.consoleCommandFillUnitAdd(g_currentMission, selectedFillUnitIndex, g_fillTypeManager:getFillTypeNameByIndex(currentFillTypeIndex), 0)

                if selectedFillTypeIndex > 0 then
                    local selectedFillTypeName = g_fillTypeManager:getFillTypeNameByIndex(selectedFillTypeIndex)
                    PowerTools:printDebugVar("selectedFillTypeName", selectedFillTypeName)
                    PowerTools:printDebugVar("amount", amount)

                    FSBaseMission.consoleCommandFillUnitAdd(g_currentMission, selectedFillUnitIndex, selectedFillTypeName, amount)
                end

            end
        end,
    }

    g_gui:showOptionDialog(dialogArguments)

end

function PowerTools:fillVehicle()

    local controlledVehicle = g_currentMission.controlledVehicle
    local selectedVehicle = controlledVehicle ~= nil and controlledVehicle:getSelectedVehicle()
    local currentVehicle = selectedVehicle or controlledVehicle
    local spec_fillUnit = currentVehicle ~= nil and currentVehicle.spec_fillUnit

    -- Pre scan
    local validFillUnits = {}
    local function checkFillUnitsForVehicle(vehicle)
        local spec_fillUnit = vehicle ~= nil and vehicle.spec_fillUnit
        local perVehicleIndex = 0

        if spec_fillUnit == nil then
            return
        end

        local function addFillUnitOption(index, fillUnit)
            perVehicleIndex = perVehicleIndex + 1
            local fillUnitOption = {
                index = index,
                fillType = fillUnit.fillType,
                fillLevel = fillUnit.fillLevel,
                capacity = fillUnit.capacity,
                unitText = fillUnit.unitText,
                vehiclePrefix = vehicle.typeDesc:upper() .. "[" .. tostring(perVehicleIndex) .. "]"
            }
            
            validFillUnits[#validFillUnits + 1] = fillUnitOption

        end
        
        
        for index, fillUnit in ipairs(spec_fillUnit.fillUnits) do
            if fillUnit.supportedFillTypes ~= nil and fillUnit.showOnInfoHud then
                if #fillUnit.supportedFillTypes > 0 then
                    addFillUnitOption(index, fillUnit)
                else-- Second chance
                    for k, v in pairs(fillUnit.supportedFillTypes) do
                        if type(k) == "number" and type(v) == "boolean" and v == true then
                            addFillUnitOption(index, fillUnit)
                            break
                        end
                    end
                end
            end
            
        end
    end
    
    checkFillUnitsForVehicle(currentVehicle)
    -- if currentVehicle ~= controlledVehicle then
    --     checkFillUnitsForVehicle(controlledVehicle)
    -- end


    local selectedFillUnitIndex
    if #validFillUnits == 0 then
        g_currentMission:showBlinkingWarning(g_i18n:getText("errorNoValidFillUnits"))
        return
    elseif #validFillUnits == 1 then
        selectedFillUnitIndex = 1
        self:fillFillUnit(spec_fillUnit.fillUnits[1])
    else
        local options = {}
        for index, value in ipairs(validFillUnits) do
            local name = value.fillType == 0 and "-" or g_fillTypeManager:getFillTypeNameByIndex(value.fillType)
            options[#options + 1] = string.format( "%s: %s (%d/%d)", value.vehiclePrefix, name, value.fillLevel, value.capacity)
        end

        self:showOptionDialog(
            g_i18n:getText("chooseFillUnitDetailed"),
            g_i18n:getText("chooseFillUnit"),
            options,
            function(target, selectedOption)
                if selectedOption > 0 then
                    self:fillFillUnit(spec_fillUnit.fillUnits[validFillUnits[selectedOption].index])
                end
            end
        )
    end
end

function PowerTools:saveGame()
    if not self:validateMPHost() then return end
    self.isQuickSaving = true
    g_currentMission:startSaveCurrentGame()
end

SavegameController.onSaveComplete = Utils.appendedFunction(SavegameController.onSaveComplete, function(self, errorCode)
    if not PowerTools.isQuickSaving then return end

    if errorCode == Savegame.ERROR_OK then
        g_gui:closeDialogByName("MessageDialog")
    else
        g_gui:showInfoDialog({
            dialogType = DialogElement.TYPE_WARNING,
            text = g_currentMission.inGameMenu.l10n:getText(InGameMenu.L10N_SYMBOL.NOT_SAVED)
        })    
    end

    PowerTools.isQuickSaving = nil
end)

function PowerTools:spawnSquareBales()
end

function PowerTools:spawnSquareBales()
end


function PowerTools:saveAction(type, targetObject, targetCommand, payload)
    self.lastAction = {
        actionType= type,
        targetObject = targetObject,
        targetCommand = targetCommand,
        payload = payload,
    }
end

function PowerTools:spawnBales(baleType)
    local options = {}
    for index, baleSize in ipairs(baleType.sizes) do
        local title
        if baleSize.isRoundbale then
            title = g_i18n:getText("fillType_roundBale") .. " " .. tostring(baleSize.diameter) .. "x" .. tostring(baleSize.width) .. " (" .. tostring(baleSize.capacity) .. "L)"
        else
            title = g_i18n:getText("fillType_squareBale") .. " " .. tostring(baleSize.width) .. "x" .. tostring(baleSize.height) .. "x" .. tostring(baleSize.length) .. " (" .. tostring(baleSize.capacity) .. "L)"
        end
        options[#options + 1] = title
    end

    local function showBaleTypeOptions()
        self:showOptionDialog(
            g_i18n:getText("spawnObjectsActionText"),
            g_i18n:getText("spawnObjectsActionTitle"),
            options,
            function(target, selectedOption)
                if type(selectedOption) == "number" and selectedOption > 0 then
                    local baleSize = baleType.sizes[tonumber(selectedOption)]
                    local wrapState = (baleSize.wrapState and 1) or nil
                    local payload = { baleType.fillTypeName, tostring(baleSize.isRoundbale), baleSize.width, (baleSize.isRoundbale and baleSize.diameter) or baleSize.height, baleSize.length, wrapState }
                    g_baleManager:consoleCommandAddBale(unpack(payload))
                    self:saveAction(ACTION.SPAWN_BALE, g_baleManager,g_baleManager.consoleCommandAddBale, payload )
                    showBaleTypeOptions()
                else
                    self:spawnObjects()
                end
            end,
            true
        )
            
    end

    showBaleTypeOptions()

end

function PowerTools:spawnPallets()
    local palletTypes = {}
    for index, fillType in ipairs(g_fillTypeManager.fillTypes) do
        if fillType.palletFilename ~= nil and fillType.palletFilename:find("fillablePallet.xml") == nil then
            palletTypes[#palletTypes + 1] = { fillType.index, fillType.name, fillType.title, fillType.palletFilename }
        end
    end

    local options = {}
    for index, value in ipairs(palletTypes) do
        options[#options + 1] = value[3]
    end

    local function showPalletOptions()
        self:showOptionDialog(
            g_i18n:getText("spawnObjectsActionText"),
            g_i18n:getText("spawnObjectsActionTitle"),
            options,
            function(target, selectedOption)
                if selectedOption > 0 then
                    g_currentMission:consoleCommandAddPallet(palletTypes[selectedOption][2])
                    self:saveAction(ACTION.SPAWN_PALLET, g_currentMission, g_currentMission.consoleCommandAddPallet, { palletTypes[selectedOption][2] })
                    showPalletOptions()
                end
            end,
            true
        )
            
    end

    showPalletOptions()    
end

function PowerTools:spawnLogs()
    Log:debug("Spwaning logs")
    -- Log:table("g_treePlantManager", g_treePlantManager)
    Log:table("SPRUCE1", g_treePlantManager.nameToTreeType["SPRUCE1"])
    Log:var("Name of tree", g_i18n:getText("treeType_oak"))

    -- g_treePlantManager.nameToTreeType
	-- if treeType == nil then
	-- 	treeType = "SPRUCE1"
	-- end
    -- BIRCH
    -- PINE
    -- SPRUCE1

    -- nameToTreeType
    -- nameI18N :: treeType_oak
    -- treeFilenames

	-- local treeTypeDesc = g_treePlantManager:getTreeTypeDescFromName(treeType)

	-- if treeTypeDesc == nil then
	-- 	return "Invalid tree type. " .. usage
	-- end

	-- growthState = Utils.getNoNil(growthState, table.getn(treeTypeDesc.treeFilenames))    
    -- g_currentMission:consoleCommandLoadTree(MathUtil.clamp(6, 1, 8), "SPRUCE1", 6)




    local logTypes = {}
    local function addLogType(type, length)
        logTypes[#logTypes + 1] = { type.index, type.name, g_i18n:getText(type.nameI18N) .. " [" .. length .. "m]", #type.treeFilenames, length }
    end
    for name, treeType in pairs(g_treePlantManager.nameToTreeType) do
        if name == "SPRUCE1" or name == "BIRCH" or name == "PINE" then
            local maxLength = (name == "PINE" and 8) or 6
            addLogType(treeType, 1)
            for i = 2, maxLength, 2 do
                addLogType(treeType, i)
            end
            -- logTypes[#logTypes + 1] = { treeType.index, treeType.name, g_i18n:getText(treeType.nameI18N), #treeType.treeFilenames, maxLength }
        end
    end

    local options = {}
    for index, value in ipairs(logTypes) do
        options[#options + 1] = value[3]
    end

    local function showLogOptions(preventReset)
        self:showOptionDialog(
            g_i18n:getText("spawnObjectsActionText"),
            g_i18n:getText("spawnObjectsActionTitle"),
            options,
            function(target, selectedOption)
                if selectedOption > 0 then
                    local selectedLogType = logTypes[selectedOption]
                    g_currentMission:consoleCommandLoadTree(selectedLogType[5], selectedLogType[2], selectedLogType[4])
                    -- g_currentMission:consoleCommandLoadTree(MathUtil.clamp(6, 1, 8), "SPRUCE1", 6)
                    self:saveAction(ACTION.SPAWN_LOG, g_currentMission, g_currentMission.consoleCommandLoadTree, { selectedLogType[5], selectedLogType[2], selectedLogType[4] })

                    showLogOptions(true)
                end
            end,
            preventReset
        )
            
    end

    showLogOptions(false)
end

function PowerTools:unwrapBaleTypes()
    local baleTypes = { }
    
    for index, baleType in ipairs(g_baleManager.bales) do
        if baleType.isAvailable then
            for index, baleFillType in ipairs(baleType.fillTypes) do
                local fillType = g_fillTypeManager:getFillTypeByIndex(baleFillType.fillTypeIndex)
                local fillTypeName = fillType.name
                
                baleTypes[fillTypeName] = baleTypes[fillTypeName] or {
                    fillTypeIndex = baleFillType.fillTypeIndex,
                    fillTypeTitle = fillType.title,
                    fillTypeName = fillTypeName,
                    sizes = {},
                }

                local baleSizes = baleTypes[fillTypeName].sizes

                baleSizes[#baleSizes + 1] = {
                    isRoundbale = baleType.isRoundbale,
                    diameter = baleType.diameter,
                    width = baleType.width,
                    height = baleType.height,
                    length = baleType.length,
                    capacity = baleFillType.capacity,
                    wrapState = true and (fillTypeName:upper() == "SILAGE")
                }
            end
        end
    end
    self.baleTypes = baleTypes
end

function PowerTools:showWarningIfNoAccess(hasAccess)
    if not hasAccess then
        g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThis"))
    end
    return hasAccess
end

function PowerTools:validateMPFarmAdmin()
    return PowerTools:showWarningIfNoAccess(self:getIsValidFarmManager())
end

function PowerTools:validateMPServerAdmin()
    return PowerTools:showWarningIfNoAccess(self:getIsMasterUser())
end

function PowerTools:validateMPAdmin()
    return PowerTools:showWarningIfNoAccess(self:getIsMasterUser() or self:getIsValidFarmManager())

    -- if not requireFarmAdmin and g_currentMission.getIsServer() == true then
    --     return true
    -- end

    -- --currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_VEHICLE)
    -- if not self:getIsMasterUser() or not self:getIsValidFarmManager() then --not self:getIsValidFarmManager() then
    --     g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThis"))
    --     return false
    -- end    
    -- return true
end

function PowerTools:validateMPHost()
    if not self:getIsServer() then
        g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThis"))
        return false
    end    
    return true
end

function PowerTools:spawnObjects()
    if not self:validateMPAdmin() then return end

    if self.baleTypes == nil then
        self:unwrapBaleTypes()
    end

    local actions = {}

    for key, value in pairs(self.baleTypes) do
        actions[#actions + 1] = {
            g_i18n:getText("infohud_bale") .. " [" .. value.fillTypeTitle .. "]",
            self.spawnBales,
            { value }
        }
    end

    table.insert( actions, 1 , { g_i18n:getText("infohud_pallet"), self.spawnPallets } )--infohud_pallet 
    table.insert( actions, 2 , { g_i18n:getText("fillType_wood"), self.spawnLogs } )

    self:showSubMenu(
        g_i18n:getText("spawnObjectsActionText"),
        g_i18n:getText("spawnObjectsActionTitle"),
        nil,
        actions
    )

    if true then
        return
    end

end

local function quitGame(restart, hardReset)
    restart = restart or false
    hardReset = hardReset or false

    local success = pcall(function()
        if not hardReset and g_currentMission ~= nil then
            OnInGameMenuMenu()
            RestartManager:setStartScreen(RestartManager.START_SCREEN_MAIN)
        end

        local gameID = ""
        if restart and g_careerScreen ~= nil and g_careerScreen.currentSavegame ~= nil then
            gameID = g_careerScreen.currentSavegame.savegameIndex
        end

        doRestart(hardReset, "-autoStartSavegameId " .. gameID)
    end)

    if not success then
        PowerTools:printError("Failed to exit/restart game")
    end
end

local function exitToMenu(force)
    PowerTools:printInfo("Exiting to menu")
    
    quitGame(false, force)
end

local function restartGame(force)
    local savegameName = "unknown"
    local saveGameIndex = "?"

    pcall(function()
        savegameName = g_careerScreen.currentSavegame.savegameName
        saveGameIndex = g_careerScreen.currentSavegame.savegameIndex
    end)

    PowerTools:printInfo("Restarting current savegame '%s' [%d]", savegameName, saveGameIndex)
    quitGame(true, force)
end




local function doExitRestartGame(shouldRestart)
    local useHardReset = false -- NOTE: Change to 'true' to force application restart

    -- PowerTools:printInfo("Exiting to main menu/restarting current game")

    if shouldRestart then
        restartGame(useHardReset)
    else
        exitToMenu(useHardReset)
    end

    -- if useHardReset then
    --     PowerTools:printInfo("Using hard reset mode to exit/restart game")

    --     -- RestartManager:setStartScreen(RestartManager.START_SCREEN_MAIN)
    --     doRestart(true, "-autoStartSavegameId 0")
    -- else
    --     -- SystemConsoleCommands:softRestart()

    --     -- StartParams.getIsSet("restart")
    --     -- g_careerScreen.savegameList:setSelectedIndex(tonumber(1), true)
    --     -- g_careerScreen.currentSavegame = savegame

    --     -- 2023-08-06 20:56 g_careerScreen.currentSavegame:: savegameIndex :: 1

    --     -- Log:table("g_currentMission", g_currentMission)
    --     -- Log:table("g_careerScreen.currentSavegame", g_careerScreen.currentSavegame)
	-- 	if g_currentMission ~= nil then
	-- 		OnInGameMenuMenu()
    --         Log:debug("OnInGameMenuMenu()")
    --         RestartManager:setStartScreen(RestartManager.START_SCREEN_MAIN)
    --         doRestart(false, "-autoStartSavegameId 1")
            

	-- 		return
	-- 	end

    --     -- g_currentMission = nil

	-- 	-- RestartManager:setStartScreen(RestartManager.START_SCREEN_MAIN)
	-- 	doRestart(false, "")

    -- end
    
end

function PowerTools:confirmExitRestartGame(confirmCallback, ...)
    local callbackArgs = { ... }
    g_gui:showYesNoDialog({
        title = g_i18n:getText("confirmExit"),
        text = g_i18n:getText("exitRestartWarning"),
        callback =  function(self, yes)
            PowerTools:printDebugVar("doExit?", yes)
            if yes == true then
                confirmCallback(unpack(callbackArgs))
            end
        end,
        target = self
    })
end

function PowerTools:menuActionRestartGame()
    self:confirmExitRestartGame(function()
        restartGame(false)
    end)
end

function PowerTools:menuActionForceRestartGame()
    self:confirmExitRestartGame(function()
        restartGame(true)
    end)
end

function PowerTools:menuActionExitSavegame()
    self:confirmExitRestartGame(function()
        exitToMenu(false)
    end)
end

function PowerTools:menuActionForceExitSavegame()
    self:confirmExitRestartGame(function()
        exitToMenu(true)
    end)

    -- g_gui:showYesNoDialog({
    --     title = g_i18n:getText("confirmExit"),
    --     text = g_i18n:getText("exitRestartWarning"),
    --     callback =  function(self, yes)
    --         PowerTools:printDebugVar("doExit?", yes)
    --         if yes == true then
    --             doExitRestartGame(false)
    --         end
    --     end,
    --     target = self
    -- })
end

-- function PowerTools:consoleCommandExitSavegame()
--     -- self.shouldEnforceExitRestart = true
-- end

function PowerTools:update(dt)
    -- if self.shouldEnforceExitRestart then
    --     self.shouldEnforceExitRestart = nil
    --     exitToMenu(false)
    -- end

    if self.pendingRestartMode == RESTART_MODE.EXIT then
        exitToMenu(false)
    elseif self.pendingRestartMode == RESTART_MODE.EXIT_FORCED then
        exitToMenu(true)
    elseif self.pendingRestartMode == RESTART_MODE.RESTART then
        restartGame(false)
    elseif self.pendingRestartMode == RESTART_MODE.RESTART_FORCED then
        restartGame(true)
    end
end

function PowerTools:commandQuitGame()
    doExit()
end

function PowerTools:consoleCommandRestartGame()
    self.pendingRestartMode = RESTART_MODE.RESTART_FORCED
end

function PowerTools:consoleCommandExitGame()
    self.pendingRestartMode = RESTART_MODE.EXIT_FORCED
end


function PowerTools:initMission()
    addConsoleCommand("ee", "Exit to the menu", "consoleCommandExitGame", self)
    addConsoleCommand("rr", "Force restart savegame", "consoleCommandRestartGame", self)
    addConsoleCommand("qq", "Quit the game", "commandQuitGame", self)
    addConsoleCommand("ptTable", "Print table", "consoleCommandPrintTable", self)
end

function PowerTools:delete()
    self:printDebug("Unloading mod Power Tools")
    removeConsoleCommand("ee")
    removeConsoleCommand("rr")
    removeConsoleCommand("qq")
    removeConsoleCommand("ptTable")
    
end
