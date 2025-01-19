
if UserAttributeType == nil then
    UserAttributeType = {
        INTEGER = 1,
        STRING = 2,
        NODE_ID = 5,
        FLOAT = 2,
        BOOLEAN = 0,
        CALLBACK = 4,
    }
end

I3DHelper = {}

local g_currentModName = g_currentModName

local function tryGetGlobalObject(tablePath)
    local success, obj = pcall (
        function()
            return loadstring("return " .. tablePath)()
        end
    )

    if success then
        return obj
    end
end

function I3DHelper.getUserAttributeCallback(nodeId, key)
    local userAttributeCallback, userAttributeType = getUserAttributeValueAndType(nodeId, key)
    Log:debug("Node '%s' [%d]", getName(nodeId), nodeId)
    Log:var("user attribute callback", userAttributeCallback)

    if userAttributeCallback == nil then
        Log:debug("No callback found for key '%s'", key)
        return nil
    end

    if userAttributeType == UserAttributeType.CALLBACK then
        if type(userAttributeCallback) == "string" then
            Log:debug("Loading callback '%s' via string", userAttributeCallback)
            local actualCallbackFunction = tryGetGlobalObject(userAttributeCallback) or tryGetGlobalObject(g_currentModName .. "." .. userAttributeCallback)
            Log:var("actualCallbackFunction", actualCallbackFunction)
            return actualCallbackFunction
        elseif type(userAttributeCallback) == "function" then
            Log:debug("Loading callback '%s' via function", userAttributeCallback)
            return userAttributeCallback
        else
            Log:warning("Unknown callback type '%s' for key '%s', supported types are string and function", type(userAttributeCallback), key)
        end
        return userAttributeCallback
    else
        Log:warning("User attribute type '%d' for key '%s' is not supported", userAttributeType, key)
        return nil
    end
end