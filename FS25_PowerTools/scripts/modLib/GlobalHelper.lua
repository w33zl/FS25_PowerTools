GlobalHelper = {}
_G.GlobalHelper = GlobalHelper

function GlobalHelper.GetActionEvent(name, specialization, preferGlobal)
    local actionName = g_inputBinding.nameActions[name]
    local actionEvent = nil

    -- Log:var("binding name", name)
    -- Log:var("action name", actionName)
    -- Log:table("specialization.actionEvents", specialization.actionEvents)

    local function getSpecActionEvent()
        if specialization == nil or specialization.actionEvents == nil then return end
        -- Log:var("specialization.actionEvents[name]", specialization.actionEvents[name])
        return specialization.actionEvents[name]
    end

    local function getGlobalActionEvent()
        local actionEvents = g_inputBinding.actionEvents[actionName] or {}
        return ((#actionEvents > 0) and actionEvents[1]) or nil
    end

    if preferGlobal then
        -- Log:var("preferGlobal", preferGlobal)
        actionEvent = getGlobalActionEvent()
        -- Log:var("global actionEvent", actionEvent)
        if actionEvent == nil then
            actionEvent = getSpecActionEvent()
            -- Log:var("spec actionEvent", actionEvent)
        end
    else
        actionEvent = getSpecActionEvent()
        -- Log:var("spec actionEvent", actionEvent)
        if actionEvent == nil then
            actionEvent = getGlobalActionEvent()
            -- Log:var("global actionEvent", actionEvent)
        end
    end
    return actionEvent
end

function GlobalHelper.executeAction(actionEvent)
    if actionEvent == nil or actionEvent.callback == nil or type(actionEvent.callback) ~= "function" then
        Log:warning("Could not trigger action event '%s'", actionEvent.id)
        return
    end
    actionEvent.callback(actionEvent.targetObject)
end

function GlobalHelper.GetSpecActionEventId(spec, inputAction)
    if spec ~= nil and spec.actionEvents ~= nil and inputAction ~= nil then
        local actionEvent = spec.actionEvents[inputAction]

        if actionEvent ~= nil then
            local actionEventId = actionEvent.actionEventId

            return actionEventId

        end
    end
end