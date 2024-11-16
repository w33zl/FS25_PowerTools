-- StoreManager.loadItem = Utils.overwrittenFunction(StoreManager.loadItem, function(self, superFunc, xmlFilename, baseDir, customEnvironment, isMod, isBundleItem, dlcTitle)

assert(Log, "The dependency 'Log' from WeezlsModLibrary was not found!")

local Log = Log:newLog("StoreManagerExtension")

local g_currentModDirectory = g_currentModDirectory
local g_currentModName = g_currentModName

if StoreManager == nil then -- Something is really wrong!
    Log:error("Could not find class StoreManager")
    return
end

StoreManager.loadItem = Utils.overwrittenFunction(StoreManager.loadItem, function(self, superFunc, rawXMLFilename, baseDir, customEnvironment, isMod, isBundleItem, dlcTitle, extraContentId, ignoreAdd)
    -- Log:debug("StoreManager.loadItem override")
    local shouldBeReplaced = false
    local actualXmlFilename = rawXMLFilename
    local tempFileName = g_currentModDirectory .. rawXMLFilename:gsub("$data/", "dataOverride/")
    

    if customEnvironment == g_currentModName then
        Log:warning("Should not replace items from self")
    end

    if customEnvironment ~= g_currentModName then

        shouldBeReplaced = fileExists(tempFileName) and (g_currentModDirectory..rawXMLFilename ~= tempFileName)

        -- if tempFileName:find("$") then

        --'$data/vehicles/valtra/ASeries/ASeries.xml'

        if shouldBeReplaced then
            --TODO: 
            actualXmlFilename = tempFileName
            -- Log:var("originalXmlFilename", rawXMLFilename)
            -- Log:var("replacedXmlFilename", actualXmlFilename)
        end
        -- Log:var("xmlFilename", xmlFilename)
        -- Log:var("tempFileName", tempFileName)
        -- Log:var("shouldBeReplaced", shouldBeReplaced)
        -- Log:var("actualXmlFilename", actualXmlFilename)

    end
    
    return superFunc(self, rawXMLFilename, baseDir, customEnvironment, isMod, isBundleItem, dlcTitle, extraContentId, ignoreAdd)

end)

XMLFile.load = Utils.overwrittenFunction(XMLFile.load, function(objectName, superFunc, filename, schema)

    
    local actualFilename = filename

    --storeManagerLoadItemXml

    -- if objectName == "storeManagerLoadItemXml" then
        local shouldBeReplaced = false
        local tempFileName = ""
        local isSelf = string.sub( filename, 1, string.len( g_currentModDirectory ) ) == g_currentModDirectory

        if not isSelf then
            if string.sub( filename, 1, 5 ) == "data/" then
                tempFileName = g_currentModDirectory .. filename:gsub("data/", "basegameOverride/")
            else
                --TODO: support for mods...
            end
    
            -- if customEnvironment ~= g_currentModName then
            -- Log:var("XMLFile.load::objectName", objectName)
            -- Log:var("XMLFile.load::filename", filename)
    
            shouldBeReplaced = fileExists(tempFileName) and (g_currentModDirectory..filename ~= tempFileName)
        else
            Log:debug("We are not replacing our internal items, skipping file")
        end

        if shouldBeReplaced then
            actualFilename = tempFileName
            Log:var("XMLFile.load::objectName", objectName)
            Log:var("originalFilename", filename)
            Log:var("replacedFilename", actualFilename)
        end

        -- end
    -- end

    return superFunc(objectName, actualFilename, schema)
end)

