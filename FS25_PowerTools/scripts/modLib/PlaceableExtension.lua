--[[

PLACEABLE EXTENSION (PART OF WEEZLS MOD LIB FOR FS25):
- Adds additional events on nodes in the i3d scene to allow code to be executed when a placeable is finalized, rather than the i3d is loaded

Author:     w33zl (github.com/w33zl)

COPYRIGHT:
You may redistribute the script, in original or modified state. All I request in return is that you leave this header intact and let me (the author, w33zl) know that you have used the script. Contact me on Facebook let me know in which mod you used the script.

I will also kindly ask you to, if possible, share your creations freely to the community, together we will create better mods and we all benefit of an open and sharing community!
]]

assert(Log, "The dependency 'Log' from WeezlsModLibrary was not found! Please add '<sourceFile filename=\"scripts/ModLib/LogHelper.lua\" />' to your <extraSourceFiles> section in modDesc.xml")

PlaceableExtension = {
	
}

function PlaceableExtension.checkForOnFinalize(nodeId, placeable)
    if nodeId ~= nil then
        local onFinalizeDelegate = I3DHelper.getUserAttributeCallback(nodeId, "onFinalize")
        Log:debug("Node '%s' [%d]", getName(nodeId), nodeId)
        Log:var("onFinalizeDelegate", onFinalizeDelegate)

        if onFinalizeDelegate ~= nil and type(onFinalizeDelegate) == "function" then
            Log:debug("Calling onFinalizeDelegate for node '%s' [%d]", getName(nodeId), nodeId)
            onFinalizeDelegate(nil, nodeId, placeable)
        end 
    end
end

function PlaceableExtension.recursiveOnFinalize(rootNodeId, placeable)
    Log:debug("PlaceableExtension.recursiveOnFinalize")

    local function scanChildren(parentNodeId)
        if parentNodeId == nil then
            return
        end

        Log:var("Scanning node", rootNodeId)

        local numChildren = getNumOfChildren(parentNodeId)
        
        if numChildren > 0 then
            for i=0, numChildren - 1 do
                local childNode = getChildAt(parentNodeId, i)
                PlaceableExtension.checkForOnFinalize(childNode, placeable)
                scanChildren(childNode) -- Recurse children
            end
        end
    end

    scanChildren(rootNodeId)
end

Placeable.finalizePlacement = Utils.overwrittenFunction(Placeable.finalizePlacement, function (self, superFunc, ...)
    Log:debug("Placeable.finalizePlacement")
    local returnValue = superFunc(self, ...)


    if self ~= nil then
        local components = self.components
        Log:table("components", components)
        if components ~= nil and #components > 0 then
            for _, component in ipairs(components) do
                local componentNodeId = component ~= nil	and component.node
                if componentNodeId ~= nil then
                    Log:debug("Component node '%s' [%d]", getName(componentNodeId), componentNodeId)
                    PlaceableExtension.checkForOnFinalize(componentNodeId, self)
                end
            end
        end
    end

    -- Log:var("self.rootNode", self.rootNode)
    -- local onFinalizeDelegate = getUserAttribute(self.rootNode, "onFinalize")
    -- Log:var("onFinalizeDelegate", onFinalizeDelegate)
    -- Log:var("groupId", getUserAttribute(self.rootNode, "groupId"))
    

    return returnValue
end)