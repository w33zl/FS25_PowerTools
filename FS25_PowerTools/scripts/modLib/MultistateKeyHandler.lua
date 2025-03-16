--[[

MultiStateKeyHandler (Weezls Mod Lib for FS25_PowerTools) - Allows binding keys with three different actions (short press, long press, double tap)

Version:    2.0
Modified:   2024-11-26
Author:     w33zl (github.com/w33zl)

Changelog:
v2.0        FS25 rewrite
v1.0        Initial FS22 version

License:    CC BY-NC-SA 4.0
This license allows reusers to distribute, remix, adapt, and build upon the material in any medium or 
format for noncommercial purposes only, and only so long as attribution is given to the creator.
If you remix, adapt, or build upon the material, you must license the modified material under identical terms. 

]]

local MULTISTATEKEY_TRIGGER = {
    UNKNOWN = 0,
    SHORT_PRESS = 1,
    LONG_PRESS = 2,
    DOUBLE_PRESS = 3,
    REPEATED_LONG_PRESS = 4,
    DOUBLE_PRESS_PENDING = 5,
    SHORT_PRESS_FORCED = 6,
    BLOCK = 7,
}

local MULTISTATEKEY_ACTION = {
    UNKNOWN = 0,
    SHORT_PRESS = 1,
    LONG_PRESS = 2,
    DOUBLE_PRESS = 3,
    DEFAULT = 4,
}
local KEYSTATE_DOUBLETAP_THRESHOLD_LOW = 25
local KEYSTATE_DOUBLETAP_THRESHOLD_HIGH = 225 --250
local KEYSTATE_LONGPRESS_THRESHOLD = 500
local KEYSTATE_LONGPRESS_REPEAT_DELAY = 1000

local DEBUG_DRAW_MODE = false


local MultistateKeyHandler = {}
local MSKH_mt = Class(MultistateKeyHandler)
_G.MultistateKeyHandler = MultistateKeyHandler
_G.MULTISTATEKEY_TRIGGER = MULTISTATEKEY_TRIGGER

local function getTimeMs()
    return getTimeSec() * 1000
end

local MultistateKeyHandlerRegistry = {
    instances = {},
    refresh = function(self)
        for _, instance in pairs(self.instances) do
            if instance ~= nil and type(instance.update) == "function" then
                instance:update()
            end
        end
    end,
    draw = function(self)
        for _, instance in pairs(self.instances) do
            if instance ~= nil and type(instance.debugDraw) == "function" then
                instance:debugDraw()
            end
        end
    end,    
    register = function(self, instance)
        table.insert(self.instances, instance)
    end,    
}

FSBaseMission.update = Utils.appendedFunction(FSBaseMission.update, function(baseMission, ...)
    MultistateKeyHandlerRegistry:refresh()
end)

if DEBUG_DRAW_MODE then
    FSBaseMission.draw = Utils.appendedFunction(FSBaseMission.draw, function(baseMission, ...)
        MultistateKeyHandlerRegistry:draw()
    end)
end

FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, function(baseMission, ...)
    MultistateKeyHandlerRegistry.refresh = function() end -- Dummy function to disable update
    MultistateKeyHandlerRegistry.instances = {}
end)


function MultistateKeyHandler.new(singlePressCallback, longPressCallback, doublePressCallback, allowRepeatedLongpress, longPressRepeatDelay)
    local newItem = setmetatable({
        singlePressCallback = singlePressCallback,
        longPressCallback = longPressCallback,
        doublePressCallback = doublePressCallback,
        allowRepeatedLongpress = allowRepeatedLongpress,
        longPressRepeatDelay = longPressRepeatDelay or KEYSTATE_LONGPRESS_REPEAT_DELAY,
        longPressThreshold = KEYSTATE_LONGPRESS_THRESHOLD,
        doublePressThreshold = KEYSTATE_DOUBLETAP_THRESHOLD_HIGH,
    }, MSKH_mt)
    newItem:updateConditions()
    MultistateKeyHandlerRegistry:register(newItem)
    return newItem
end


function MultistateKeyHandler:updateConditions()
    self.allowDoublePress = (self.doublePressCallback ~= nil)
    self.allowLongPress = (self.longPressCallback ~= nil)
    self.allowRepeatedLongpress = self.allowLongPress and self.allowRepeatedLongpress
end

--TODO: add function to register a new key

function MultistateKeyHandler:injectIntoAction(actionEvent, preserveDefaultCallback, forceOverride)
    preserveDefaultCallback = (preserveDefaultCallback == nil) or preserveDefaultCallback
    forceOverride = forceOverride or false

    if self.actionEvent ~= nil then
        if self.actionEvent == actionEvent and not forceOverride then
            Log:warning("injectIntoAction: action event already injected")
            return
        elseif not forceOverride then
            Log:warning("injectIntoAction: This handler is already linked to another action, either use new MultistateKeyHandler or use the forceOverride parameter")
            return
        end
    end

    -- Save a reference to the actionEvent and some of its original properties
    self.actionEventTarget = actionEvent.targetObject
    self.actionEventArgs = actionEvent.targetArgs --- TODO: needs to be verified
    self.actionEvent = actionEvent
    self.originalCallback = actionEvent.callback -- Store original callback as single press (default) action

    if self.singlePressCallback == nil or preserveDefaultCallback then
        self.singlePressCallback = self.originalCallback -- Store original callback as single press (default) action
    end

    actionEvent.targetObject = self -- Set ourselves as target object
    actionEvent.callback = self.trigger -- Set new callback to our trigger
    actionEvent.triggerAlways = true
    actionEvent.triggerDown = true
    actionEvent.triggerUp = true
    actionEvent.displayIsVisible = false
end

function MultistateKeyHandler:trigger(name, state, callbackState, isAnalog, isMouse, deviceCategory)
    -- Log:table("MSKH:trigger", self)
    -- self:handleActionEvent(name, state, callbackState, isAnalog, isMouse, deviceCategory)
    self.payload = {
        name,
        state,
        callbackState, 
        isAnalog, 
        isMouse, 
        deviceCategory,
    }
    local isSameState = (self.lastKeyState == state)
    
    
    self.lastKeyState = state
    if state == 1 then
        local isHolding = (state ~= 0 and isSameState)

        self.firstTriggerTime = self.firstTriggerTime or getTimeMs() -- Needed for repeated long press
        self.triggerTime = getTimeMs()
        -- Log:debug("Trigger: %s [keyState: %s / lastState: %s / isHolding: %s]", state, self.keyState, self.lastState, tostring(isHolding))
        -- if self.allowRepeatedLongpress then
            -- self:checkLongPressAction()
        -- end
        -- self:checkAction()
        self:onPressKey(isHolding)
    elseif state == 0 then
        self.releaseTime = getTimeMs()
        self:onReleaseKey()
        -- self:checkAction()
        -- self.blockUntilNextReset = false
    end
end

function MultistateKeyHandler:onPressKey(isHolding)
    if self.pendingState ~= MULTISTATEKEY_TRIGGER.BLOCK or self.allowRepeatedLongpress then
        self.repeatedTriggerTime = self.repeatedTriggerTime or self.firstTriggerTime or getTimeMs()
        local totalElapsed = getTimeMs() - self.repeatedTriggerTime
        -- local totalElapsed = getTimeMs() - self.repeatedTriggerTime

        if totalElapsed > KEYSTATE_LONGPRESS_REPEAT_DELAY then
            -- Log:var("allowRepeatedLongpress", self.allowRepeatedLongpress)
            local mode = self.allowRepeatedLongpress and MULTISTATEKEY_TRIGGER.REPEATED_LONG_PRESS or MULTISTATEKEY_TRIGGER.LONG_PRESS
            -- Log:var("mode", mode)
            self:triggerState(mode)
        end
    end

end

function MultistateKeyHandler:onReleaseKey()
    self.firstTriggerTime = self.firstTriggerTime or getTimeMs() -- Just to ensure we never get nil no matte what
    local elapsed = self.releaseTime - self.firstTriggerTime
    if self.pendingState == MULTISTATEKEY_TRIGGER.BLOCK then
        self:triggerState(MULTISTATEKEY_TRIGGER.BLOCK)
    elseif elapsed > KEYSTATE_LONGPRESS_THRESHOLD then
        self:triggerState(MULTISTATEKEY_TRIGGER.LONG_PRESS)
    elseif self.pendingState == MULTISTATEKEY_TRIGGER.REPEATED_LONG_PRESS then
        Log:debug("Ingored")
    elseif self.allowDoublePress and elapsed < KEYSTATE_DOUBLETAP_THRESHOLD_HIGH then
        if self.pendingState == MULTISTATEKEY_TRIGGER.DOUBLE_PRESS_PENDING then
            self:triggerState(MULTISTATEKEY_TRIGGER.DOUBLE_PRESS)
        else
            Log:debug("Double press pending")
            self.pendingState = MULTISTATEKEY_TRIGGER.DOUBLE_PRESS_PENDING
        end
    else -- This should always be a single press, right?
        self:triggerState(MULTISTATEKEY_TRIGGER.SHORT_PRESS)
        
    end
    -- self.firstTriggerTime = nil 
end

function MultistateKeyHandler:triggerState(state)
    Log:debug("Trigger state: %s, pendingState %s", state, self.pendingState)
    local ignore = (self.pendingState == MULTISTATEKEY_TRIGGER.BLOCK)

    if state == MULTISTATEKEY_TRIGGER.LONG_PRESS then
        -- Log:debug("Long press triggered")
    elseif state == MULTISTATEKEY_TRIGGER.REPEATED_LONG_PRESS then
        -- Log:debug("Repeated long press triggered")
    elseif state == MULTISTATEKEY_TRIGGER.DOUBLE_PRESS then
        -- Log:debug("Double press triggered")
    elseif state == MULTISTATEKEY_TRIGGER.SHORT_PRESS_FORCED then
        -- Log:debug("Short press triggered forced")
    elseif state == MULTISTATEKEY_TRIGGER.SHORT_PRESS then
        -- Log:debug("Short press triggered")
    elseif state == MULTISTATEKEY_TRIGGER.BLOCK then
        ignore = true
    else
        ignore = true
        Log:debug("Unknown trigger")
    end

    if not ignore then
        self:execute(state)
    end

    if state == MULTISTATEKEY_TRIGGER.REPEATED_LONG_PRESS then
        self.previousTriggerTime = self.firstTriggerTime
        self.repeatedTriggerTime = getTimeMs()
        self.pendingState = state
    elseif state == MULTISTATEKEY_TRIGGER.LONG_PRESS then
        self.previousTriggerTime = self.previousTriggerTime or self.firstTriggerTime
        self.pendingState = MULTISTATEKEY_TRIGGER.BLOCK
    else
        self.previousTriggerTime = nil
        self.repeatedTriggerTime = nil
        self.pendingState = nil
    end

    self.firstTriggerTime = nil
    
end

function MultistateKeyHandler:update()
    local elapsed = self:getElapsed()
    if self.pendingState == MULTISTATEKEY_TRIGGER.DOUBLE_PRESS_PENDING then
        if elapsed > KEYSTATE_DOUBLETAP_THRESHOLD_HIGH then -- If double press is pending but threshold is exceeded, fire as single press
            self:triggerState(MULTISTATEKEY_TRIGGER.SHORT_PRESS_FORCED)
        end
    end
end

function MultistateKeyHandler:execute(keyState, reset)
    local function executeDelegate(callback, customTarget, customPayload)
        -- Log:var("callback", callback)
        if not callback or (type(callback)) ~= "function" then
            Log:debug("No callback set")
            return
        end

        callback(customTarget or self.actionEventTarget, unpack(customPayload or self.payload))        
    end

    if keyState == MULTISTATEKEY_TRIGGER.DOUBLE_PRESS then
        Log:debug("Double press executed")
        executeDelegate(self.doublePressCallback, self.doublePressTargetObject, self.doublePressPayload)
    elseif keyState == MULTISTATEKEY_TRIGGER.LONG_PRESS or keyState == MULTISTATEKEY_TRIGGER.REPEATED_LONG_PRESS then
        Log:debug("Long press executed")
        executeDelegate(self.longPressCallback, self.longPressTargetObject, self.longPressPayload)
    elseif keyState == MULTISTATEKEY_TRIGGER.SHORT_PRESS or keyState == MULTISTATEKEY_TRIGGER.SHORT_PRESS_FORCED then
        Log:debug("Short press executed")
        executeDelegate(self.singlePressCallback, self.singlePressTargetObject, self.singlePressPayload)
    end
end

-- function MultistateKeyHandler:checkLongPressAction()
--     local elapsed = self:getElapsed()

--     if elapsed > KEYSTATE_LONGPRESS_THRESHOLD then
--         -- Log:var("elapsed", elapsed)
--         self.lastLongPressTrigger = self.lastLongPressTrigger or self.firstTriggerTime
--         local elapsedSinceLastLongPress = getTimeMs() - self.lastLongPressTrigger
--         -- Log:var("elapsedSinceLastLongPress", elapsedSinceLastLongPress)

--         if elapsedSinceLastLongPress > KEYSTATE_LONGPRESS_REPEAT_DELAY then
--             if self.allowRepeatedLongpress then
--                 -- local newState = self.keyState == MultiKeyState.LONG_PRESS and MultiKeyState.REPEATED_LONG_PRESS or MultiKeyState.LONG_PRESS
--                 self:execute(MULTISTATEKEY_TRIGGER.REPEATED_LONG_PRESS, false) -- Don't reset, we do a manual reset instead
--                 self.lastLongPressTrigger = getTimeMs() -- Specific reset for long press repeats
--             else
--                 self:execute(MULTISTATEKEY_TRIGGER.LONG_PRESS, true)
--             end
--         end
--     end
-- end

-- function MultistateKeyHandler:reset()
--     self.firstTriggerTime = nil
--     self.lastLongPressTrigger = nil
--     self.triggerTime = nil
--     self.releaseTime = nil
--     self.keyState = MULTISTATEKEY_TRIGGER.UNKNOWN
--     self.lastState = MULTISTATEKEY_TRIGGER.UNKNOWN
--     self.blockUntilNextReset = false
-- end

-- function MultistateKeyHandler:execute(keyState, reset)
--     if self.blockUntilNextReset then
--         Log:debug("Block until next reset")
--         return
--     end
    
--     reset = (reset == nil and true) or reset
--     local blockSinglePress = (self.lastState ~= MULTISTATEKEY_TRIGGER.UNKNOWN)
--     -- Log:debug("Trigger: %s [keyState: %s / lastState: %s / blockSP: %s]", keyState, self.keyState, self.lastState, tostring(blockSinglePress))
--     self.keyState = keyState
--     if reset then
--         self:reset()
--     end
--     self.blockUntilNextReset = keyState ~= MULTISTATEKEY_TRIGGER.SHORT_PRESS
--     self.lastState = keyState

--     local function executeDelegate(callback, customTarget, customPayload)
--         -- Log:var("callback", callback)
--         if not callback or (type(callback)) ~= "function" then
--             Log:debug("No callback set")
--             return
--         end

--         callback(customTarget or self.actionEventTarget, unpack(customPayload or self.payload))
        
--     end

--     if keyState == MULTISTATEKEY_TRIGGER.DOUBLE_PRESS then
--         -- Log:debug("Double press executed")
--         executeDelegate(self.doublePressCallback, self.doublePressTargetObject, self.doublePressPayload)
--     elseif keyState == MULTISTATEKEY_TRIGGER.LONG_PRESS or keyState == MULTISTATEKEY_TRIGGER.REPEATED_LONG_PRESS then
--         Log:debug("Long press executed")
--         executeDelegate(self.longPressCallback, self.longPressTargetObject, self.longPressPayload)
--     elseif not blockSinglePress and keyState == MULTISTATEKEY_TRIGGER.SHORT_PRESS then
--         Log:debug("Short press executed")
--         executeDelegate(self.singlePressCallback, self.singlePressTargetObject, self.singlePressPayload)
--     end
-- end

function MultistateKeyHandler:getElapsed()
    return getTimeMs() - (self.firstTriggerTime or getTimeMs())
end

-- function MultistateKeyHandler:checkAction()
--     local elapsedSinceFirstTrigger = self:getElapsed()
--     -- Log:var("elapsedSinceFirstTrigger", elapsedSinceFirstTrigger)

--     if elapsedSinceFirstTrigger > KEYSTATE_LONGPRESS_THRESHOLD then
--         -- If repeated longpress already tiggered we just need to reset, otherwise execute the callback
--         -- if self.keyState == MULTISTATEKEY_TRIGGER.REPEATED_LONG_PRESS then
--         --     self:reset()
--         -- else
--         --     self:execute(MULTISTATEKEY_TRIGGER.LONG_PRESS)
--         -- end

--         self.lastLongPressTrigger = self.lastLongPressTrigger or self.firstTriggerTime
--         local elapsedSinceLastLongPress = getTimeMs() - self.lastLongPressTrigger
--         -- Log:var("elapsedSinceLastLongPress", elapsedSinceLastLongPress)

--         if elapsedSinceLastLongPress > KEYSTATE_LONGPRESS_REPEAT_DELAY then
--             if self.allowRepeatedLongpress then
--                 -- local newState = self.keyState == MultiKeyState.LONG_PRESS and MultiKeyState.REPEATED_LONG_PRESS or MultiKeyState.LONG_PRESS
--                 self:execute(MULTISTATEKEY_TRIGGER.REPEATED_LONG_PRESS, false) -- Don't reset, we do a manual reset instead
--                 self.lastLongPressTrigger = getTimeMs() -- Specific reset for long press repeats
--             else
--                 self:execute(MULTISTATEKEY_TRIGGER.LONG_PRESS, true)
--             end
--         end        
--     else
--         local currentState = self.keyState or MULTISTATEKEY_TRIGGER.UNKNOWN
        

--         -- local elapsedSinceFirstTrigger = getTimeMs() - self.firstTriggerTime

--         --TODO: add double press as conditional, no need to wait if no callback is there...
--         if self.allowDoublePress and elapsedSinceFirstTrigger <= KEYSTATE_DOUBLETAP_THRESHOLD_HIGH then
--             if currentState == MULTISTATEKEY_TRIGGER.DOUBLE_PRESS_PENDING then
                
--                 self:execute(MULTISTATEKEY_TRIGGER.DOUBLE_PRESS)
--             else
--                 Log:debug("Double press pending")
--                 self.keyState = MULTISTATEKEY_TRIGGER.DOUBLE_PRESS_PENDING
--             end
--         else
            
--             self:execute(MULTISTATEKEY_TRIGGER.SHORT_PRESS)
--         end
        
--     end
-- end

-- function MultistateKeyHandler:update()
--     local elapsedSinceFirstTrigger = self:getElapsed()

--     -- Log:var("self.keyState", self.keyState)
--     if self.keyState == MULTISTATEKEY_TRIGGER.DOUBLE_PRESS_PENDING then
--         -- Log:var("self.keyState", self.keyState)
        

--         -- If the total time since first trigger is greater than the high threshold for doubletap, we need to "force release" the button
--         if elapsedSinceFirstTrigger > KEYSTATE_DOUBLETAP_THRESHOLD_HIGH then
--             self:checkAction()
--         end
--     elseif elapsedSinceFirstTrigger > KEYSTATE_LONGPRESS_THRESHOLD then
--         self:checkAction()
--         -- -- Log:var("elapsed", elapsed)
--         -- self.lastLongPressTrigger = self.lastLongPressTrigger or self.firstTriggerTime
--         -- local elapsedSinceLastLongPress = getTimeMs() - self.lastLongPressTrigger
--         -- -- Log:var("elapsedSinceLastLongPress", elapsedSinceLastLongPress)

--         -- if elapsedSinceLastLongPress > KEYSTATE_LONGPRESS_REPEAT_DELAY then
--         --     if self.allowRepeatedLongpress then
--         --         -- local newState = self.keyState == MultiKeyState.LONG_PRESS and MultiKeyState.REPEATED_LONG_PRESS or MultiKeyState.LONG_PRESS
--         --         self:execute(MULTISTATEKEY_TRIGGER.REPEATED_LONG_PRESS, false) -- Don't reset, we do a manual reset instead
--         --         self.lastLongPressTrigger = getTimeMs() -- Specific reset for long press repeats
--         --     else
--         --         self:execute(MULTISTATEKEY_TRIGGER.LONG_PRESS, true)
--         --     end
--         -- end
                
--     end
-- end

function MultistateKeyHandler:debugDraw()
    local first = self.firstTriggerTime or -1
    local last = self.triggerTime or -1
    local release = self.releaseTime or -1
    local keyState = self.keyState or MULTISTATEKEY_TRIGGER.UNKNOWN
    local lastState = self.lastState or MULTISTATEKEY_TRIGGER.UNKNOWN
    local text = "First: " .. first .. "\nLast: " .. last .. "\nRelease: " .. release .. "\nCurrent state: " .. keyState .. "\nLast state: " .. lastState

    renderText(0.2, 0.2, 0.03, text)
end

--TODO: add function registerCallbacks...

--TODO: refactor registerCallback
function MultistateKeyHandler:setCallback(keyState, callback, target, payload)
    if keyState == MULTISTATEKEY_TRIGGER.SHORT_PRESS then
        self.singlePressCallback = callback
        self.singlePressTargetObject = target
        self.singlePressPayload = payload
    elseif keyState == MULTISTATEKEY_TRIGGER.DOUBLE_PRESS then
        self.doublePressCallback = callback
        self.doublePressTargetObject = target
        self.doublePressPayload = payload
    elseif keyState == MULTISTATEKEY_TRIGGER.LONG_PRESS or keyState == MULTISTATEKEY_TRIGGER.REPEATED_LONG_PRESS then
        self.longPressCallback = callback
        self.longPressTargetObject = target
        self.longPressPayload = payload
        self.allowRepeatedLongpress = (keyState == MULTISTATEKEY_TRIGGER.REPEATED_LONG_PRESS)
    end
    self:updateConditions()
end