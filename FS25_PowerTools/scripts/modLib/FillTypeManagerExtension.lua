--[[

FillType Manager Extesion (Weezls Mod Lib for FS22) - Simplifies the process of adding filltypes and heighttypes to mods for FS22

Author:     w33zl (github.com/w33zl)
Version:    1.0
Modified:   2022-02-27

Changelog:
v1.0        Initial public release
v0.9        Internal beta release


COPYRIGHT:
You may not redistribute the script, in original or modified state, unless you have explicit permission from the author (i.e. w33zl).

However, contact me (WZL Modding) on Facebook and I -will- happily grant you permission to use and redistribute the script! I just want to know how, and by who, the script is being used <3



map.fillTypes#filename

]]

assert(Log, "The dependency 'Log' from WeezlsModLibrary was not found!")

local Log = Log:newLog("FillTypeManagerExtension")

Log:warning("The 'FillTypeManagerExtension' is deprecated, please use basegame 'FillTypeManager' instead!")

-- local EXTENSION_NAME = "FillTypeManagerExtension"
local g_currentModDirectory = g_currentModDirectory
local g_currentModName = g_currentModName

if FillTypeManager == nil then -- Somethins is really wrong!
    Log:error("Could not find class FillTypeManager")
    return
end

DensityMapHeightManager.loadMapData = Utils.appendedFunction(DensityMapHeightManager.loadMapData, function(xmlFile, missionInfo, baseDirectory)
    Log:debug("Loading DensityMapHeightManager mapExtension data for mod %s", g_currentModName)

    -- Hack to fix a "bug"(?) where l10n texts doesn't load from mod
    -- local oldCustomEnvironment = missionInfo.customEnvironment
    -- missionInfo.customEnvironment = oldCustomEnvironment or g_currentModName

    local modDescFilename = Utils.getFilename("modDesc.xml", g_currentModDirectory)
    local modXmlFile = loadXMLFile("mapDataXML", modDescFilename)

	return FillTypeManager:loadDataFromModXML(modXmlFile, "extendedDensityMapHeightTypes", g_currentModDirectory, g_densityMapHeightManager, DensityMapHeightManager.loadDensityMapHeightTypes, missionInfo, g_currentModDirectory)
end)


FillTypeManager.loadMapData = Utils.appendedFunction(FillTypeManager.loadMapData, function(fillTypeManager, mapXmlFile, missionInfo, baseDirectory)
    Log:debug("Loading FillTypeManager mapExtension data for mod %s", g_currentModName)

    --HACK: Hack to fix a "bug"(?) where l10n texts doesn't load from mod
    local oldCustomEnvironment = missionInfo.customEnvironment
    missionInfo.customEnvironment = oldCustomEnvironment or g_currentModName

    local modDescFilename = Utils.getFilename("modDesc.xml", g_currentModDirectory)
    local modXmlFile = loadXMLFile("mapDataXML", modDescFilename)
    local success = false

    if FillTypeManager:loadDataFromModXML(modXmlFile, "extendedFillTypes", g_currentModDirectory, g_fillTypeManager, FillTypeManager.loadFillTypes, missionInfo, g_currentModDirectory, false) then
        g_fillTypeManager:constructFillTypeTextureArrays()
        -- Log:info("Loaded filltypes from '%s'", modDescFilename)
        -- return true
        success = true
    end

    if modXmlFile ~= nil then
        delete(modXmlFile)
    end

    missionInfo.customEnvironment = oldCustomEnvironment -- Cleanup the "hack"

    return success
end)

function FillTypeManager:loadDataFromModXML(mapXMLFile, xmlKey, baseDirectory, loadTarget, loadFunc, ...)
    Log:info("Loading map extension data ('%s') for mod '%s'", xmlKey, g_currentModName)

    local filename = getXMLString(mapXMLFile, string.format("modDesc.%s#filename", xmlKey))
    local xmlFile = mapXMLFile

    if filename ~= nil then
        local xmlFilename = Utils.getFilename(filename, baseDirectory)
        xmlFile = loadXMLFile("mapDataXML", xmlFilename)
    else
        --TODO: now silently ignore, maybe better to find out if that was intended or not
        return false
    end

    return loadFunc(loadTarget, xmlFile, ...)
end


