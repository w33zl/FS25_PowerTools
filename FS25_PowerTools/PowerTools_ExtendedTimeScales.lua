ExtendedTimeScales = {}
-- _G.ExtendedTimeScales = ExtendedTimeScales

function ExtendedTimeScales:prepareTimeScales()

    -- Log:table("Platform.gameplay [BEFORE]", Platform.gameplay)
    local gameplay = Platform.gameplay
    local defaultTimeScales = {}
    local extendedTimeScales = {}
    if gameplay ~= nil and gameplay.timeScaleSettings ~= nil then
        -- table.insert(extendedTimeScales, 0) -- Time is stopped
        for index, value in ipairs(gameplay.timeScaleSettings) do
            table.insert(defaultTimeScales, value)
            table.insert(extendedTimeScales, value)
        end
        -- table.insert(gameplay.timeScaleSettings, 1, 0) -- Time is stopped
        table.insert(extendedTimeScales, 1500) -- 24h in game ~ 1m in real life
        table.insert(extendedTimeScales, 5000) -- 24h in game ~ 20s in real life
        table.insert(extendedTimeScales, 7500) -- 24h in game ~ 12s in real life
    end
    self.defaultTimeScales = defaultTimeScales
    self.extendedTimeScales = extendedTimeScales

    --onInputChangeTimescale
    -- InputAction.DECREASE_TIMESCALE
    -- InputAction.INCREASE_TIMESCALE
end

function ExtendedTimeScales:toggleTimeScales()
    Log:table("Platform.gameplay [BEFORE]", Platform.gameplay)
    local gameplay = Platform.gameplay
    if gameplay ~= nil and gameplay.timeScaleSettings ~= nil then
        
        self.useExtendedTimeScales = not (self.useExtendedTimeScales or false)

        if self.useExtendedTimeScales then
            gameplay.timeScaleSettings = self.extendedTimeScales
        else
            gameplay.timeScaleSettings = self.defaultTimeScales
        end
    end
    Log:table("Platform.gameplay [AFTER]", Platform.gameplay)
end


-- function ExtendedTimeScales:injectAdditonalTimeScales()
--     Log:table("Platform.gameplay [BEFORE]", Platform.gameplay)
--     local gameplay = Platform.gameplay
--     if gameplay ~= nil and gameplay.timeScaleSettings ~= nil then
--         -- table.insert(gameplay.timeScaleSettings, 1, 0) -- Time is stopped
--         table.insert(gameplay.timeScaleSettings, 1500) -- 24h in game ~ 1m in real life
--         table.insert(gameplay.timeScaleSettings, 5000) -- 24h in game ~ 20s in real life
--         table.insert(gameplay.timeScaleSettings, 7500) -- 24h in game ~ 12s in real life
--     end
--     -- Log:table("Platform.gameplay [AFTER]", Platform.gameplay)

--     --onInputChangeTimescale
--     -- InputAction.DECREASE_TIMESCALE
--     -- InputAction.INCREASE_TIMESCALE
-- end




function ExtendedTimeScales:onIncreaseTimescale_longPress()
    self:toggleTimeScales()

    local message = nil
    if self.useExtendedTimeScales then
        message = "Time Scales Extended"
    else
        message = "Time Scales Restored to Default"
    end
    g_currentMission:addGameNotification(message, "", "", nil, 1500)
end

function ExtendedTimeScales:onDecreaseTimescale_longPress()
    -- if g_currentMission.missionInfo.timeScale  then
    --     self.lastKnownTimeScale = g_currentMission.missionInfo.timeScale
        
        local message
        if g_currentMission.missionInfo.timeScale == 0 then
            message = "Time Already Stopped"
        else
            g_currentMission:setTimeScale(0)
            message = "Time Stopped"
        end
        g_currentMission:addGameNotification(message, "", "", nil, 1500)
    
    -- else
    --     g_currentMission:setTimeScale(self.lastKnownTimeScale)
    --     self.lastKnownTimeScale = nil
    --     g_currentMission:showBlinkingWarning("onDecreaseTimescale_longPress")
    -- end
end

function ExtendedTimeScales:hookIntoGlobalKeys()
    if self.globalKeysInitiated == true then
        Log:trace("SKIP hookIntoGlobalKeys")
        return
    end
    Log:trace("hookIntoGlobalKeys")


    local function hookIntoKey(action, callback)
        local actionEvent = GlobalHelper.GetActionEvent(action, nil, true)    
        if actionEvent ~= nil then
            callback(actionEvent)
        else
            Log:warning("Failed to hook into action '%s'", action)
        end
    end

    if self.parent:getIsServerAdmin() then

        hookIntoKey(InputAction.DECREASE_TIMESCALE, function(actionEvent) 
            local decreaseTimescaleMSKH = MultistateKeyHandler.new(nil, nil, nil, true)
            decreaseTimescaleMSKH:injectIntoAction(actionEvent, nil, false)
            -- decreaseTimescaleMSKH:setCallback(MULTISTATEKEY_TRIGGER.DOUBLE_PRESS, self.onHelpTextKey_doublePress, self)
            decreaseTimescaleMSKH:setCallback(MULTISTATEKEY_TRIGGER.LONG_PRESS, self.onDecreaseTimescale_longPress, self)

            self.helpTextKeyMSKH = decreaseTimescaleMSKH

        end)

        hookIntoKey(InputAction.INCREASE_TIMESCALE, function(actionEvent) 
            local increaseTimescaleMSKH = MultistateKeyHandler.new(nil, nil, nil, true)
            increaseTimescaleMSKH:injectIntoAction(actionEvent, nil, false)
            increaseTimescaleMSKH:setCallback(MULTISTATEKEY_TRIGGER.LONG_PRESS, self.onIncreaseTimescale_longPress, self)

            self.helpTextKeyMSKH = increaseTimescaleMSKH

        end)

        Log:info("Server admin specific hooks injected")
    else

        Log:info("Advanced features are only available for server admins. Changing time scales is disabled.")

    end

    -- local helpTextActionEvent = GlobalHelper.GetActionEvent(InputAction.DECREASE_TIMESCALE, nil, true)
    -- -- Log:table("helpTextActionEvent4", helpTextActionEvent, 2)


    -- if helpTextActionEvent ~= nil then
    --     local helpTextKeyMSKH = MultistateKeyHandler.new(nil, nil, nil, true)
    --     helpTextKeyMSKH:injectIntoAction(helpTextActionEvent, nil, false)
    --     helpTextKeyMSKH:setCallback(MULTISTATEKEY_TRIGGER.DOUBLE_PRESS, self.onHelpTextKey_doublePress, self)
    --     helpTextKeyMSKH:setCallback(MULTISTATEKEY_TRIGGER.LONG_PRESS, self.onDecreaseTimescale_longPress, self)

    --     self.helpTextKeyMSKH = helpTextKeyMSKH

    -- end

    self.globalKeysInitiated = true
end

function ExtendedTimeScales.init(parent)
    Log:info("ExtendedTimeScales.init")

    ExtendedTimeScales.parent = parent

    Player.onStartMission = Utils.overwrittenFunction(Player.onStartMission, function (self, superFunc, ...)
        Log:debug("ExtendedTimeScales.Player.onStartMission")
        local retVal = superFunc(self, ...)
        ExtendedTimeScales:hookIntoGlobalKeys()
        return retVal
    end)
    
    
    FSBaseMission.onStartMission = Utils.appendedFunction(FSBaseMission.onStartMission, function(baseMission, ...) 
        Log:debug("ExtendedTimeScales.FSBaseMission.onStartMission")
        ExtendedTimeScales:prepareTimeScales()
    end)
end