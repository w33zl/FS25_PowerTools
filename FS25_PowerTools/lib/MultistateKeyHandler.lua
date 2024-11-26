--[[

MultiStateKeyHandler (Weezls Mod Lib for FS25_PowerTools) - Allows binding keys with three different actions (short press, long press, double tap)

Version:    2.0
Modified:   2024-11-26
Author:     w33zl (github.com/w33zl | facebook.com/w33zl)

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
    register = function(self, instance)
        table.insert(self.instances, instance)
    end,    
}

FSBaseMission.update = Utils.appendedFunction(FSBaseMission.update, function(baseMission, ...)
    MultistateKeyHandlerRegistry:refresh()
end)


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
    self.lastState = state
    if state == 1 then
        self.firstTriggerTime = self.firstTriggerTime or getTimeMs() -- Needed for repeated long press
        self.triggerTime = getTimeMs()
        -- if self.allowRepeatedLongpress then
            self:checkLongPressAction()
        -- end
    elseif state == 0 then
        self.releaseTime = getTimeMs()
        self:checkAction()
    end
end

function MultistateKeyHandler:checkLongPressAction()
    local elapsed = self:getElapsed()

    if elapsed > KEYSTATE_LONGPRESS_THRESHOLD then
        -- Log:var("elapsed", elapsed)
        self.lastLongPressTrigger = self.lastLongPressTrigger or self.firstTriggerTime
        local elapsedSinceLastLongPress = getTimeMs() - self.lastLongPressTrigger
        -- Log:var("elapsedSinceLastLongPress", elapsedSinceLastLongPress)

        if elapsedSinceLastLongPress > KEYSTATE_LONGPRESS_REPEAT_DELAY then
            if self.allowRepeatedLongpress then
                -- local newState = self.keyState == MultiKeyState.LONG_PRESS and MultiKeyState.REPEATED_LONG_PRESS or MultiKeyState.LONG_PRESS
                self:execute(MULTISTATEKEY_TRIGGER.REPEATED_LONG_PRESS, false) -- Don't reset, we do a manual reset instead
                self.lastLongPressTrigger = getTimeMs() -- Specific reset for long press repeats
            else
                self:execute(MULTISTATEKEY_TRIGGER.LONG_PRESS, true)
            end
        end
    end
end

function MultistateKeyHandler:reset()
    self.firstTriggerTime = nil
    self.lastLongPressTrigger = nil
    self.triggerTime = nil
    self.releaseTime = nil
    self.keyState = MULTISTATEKEY_TRIGGER.UNKNOWN
end

function MultistateKeyHandler:execute(keyState, reset)
    reset = (reset == nil and true) or reset
    self.keyState = keyState
    if reset then
        self:reset()
    end
    self.lastState = keyState

    local function executeDelegate(callback, customTarget, customPayload)
        -- Log:var("callback", callback)
        if not callback or (type(callback)) ~= "function" then
            Log:debug("No callback set")
            return
        end

        callback(customTarget or self.actionEventTarget, unpack(customPayload or self.payload))
        
    end

    if keyState == MULTISTATEKEY_TRIGGER.DOUBLE_PRESS then
        -- Log:debug("Double press executed")
        executeDelegate(self.doublePressCallback, self.doublePressTargetObject, self.doublePressPayload)
    elseif keyState == MULTISTATEKEY_TRIGGER.LONG_PRESS or keyState == MULTISTATEKEY_TRIGGER.REPEATED_LONG_PRESS then
        -- Log:debug("Long press executed")
        executeDelegate(self.longPressCallback, self.longPressTargetObject, self.longPressPayload)
    elseif keyState == MULTISTATEKEY_TRIGGER.SHORT_PRESS then
        -- Log:debug("Short press executed")
        executeDelegate(self.singlePressCallback, self.singlePressTargetObject, self.singlePressPayload)
    end
end

function MultistateKeyHandler:getElapsed()
    return getTimeMs() - (self.firstTriggerTime or getTimeMs())
end

function MultistateKeyHandler:checkAction()
    local elapsedSinceFirstTrigger = self:getElapsed()
    -- Log:var("elapsedSinceFirstTrigger", elapsedSinceFirstTrigger)

    if elapsedSinceFirstTrigger > KEYSTATE_LONGPRESS_THRESHOLD then
        -- If repeated longpress already tiggered we just need to reset, otherwise execute the callback
        if self.keyState == MULTISTATEKEY_TRIGGER.REPEATED_LONG_PRESS then
            self:reset()
        else
            self:execute(MULTISTATEKEY_TRIGGER.LONG_PRESS)
        end
    else
        local currentState = self.keyState or MULTISTATEKEY_TRIGGER.UNKNOWN
        

        -- local elapsedSinceFirstTrigger = getTimeMs() - self.firstTriggerTime

        --TODO: add double press as conditional, no need to wait if no callback is there...
        if self.allowDoublePress and elapsedSinceFirstTrigger <= KEYSTATE_DOUBLETAP_THRESHOLD_HIGH then
            if currentState == MULTISTATEKEY_TRIGGER.DOUBLE_PRESS_PENDING then
                
                self:execute(MULTISTATEKEY_TRIGGER.DOUBLE_PRESS)
            else
                Log:debug("Double press pending")
                self.keyState = MULTISTATEKEY_TRIGGER.DOUBLE_PRESS_PENDING
            end
        else
            
            self:execute(MULTISTATEKEY_TRIGGER.SHORT_PRESS)
        end
        
    end
end

function MultistateKeyHandler:update()
    -- Log:var("self.keyState", self.keyState)
    if self.keyState == MULTISTATEKEY_TRIGGER.DOUBLE_PRESS_PENDING then
        -- Log:var("self.keyState", self.keyState)
        local elapsedSinceFirstTrigger = self:getElapsed()

        -- If the total time since first trigger is greater than the high threshold for doubletap, we need to "force release" the button
        if elapsedSinceFirstTrigger > KEYSTATE_DOUBLETAP_THRESHOLD_HIGH then
            self:checkAction()
        end
    end
end

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
    elseif keyState == MULTISTATEKEY_TRIGGER.LONG_PRESS then
        self.longPressCallback = callback
        self.longPressTargetObject = target
        self.longPressPayload = payload
    end
    self:updateConditions()
end