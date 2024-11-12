--[[

LogHelper (Weezls Mod Lib for FS22) - Quality of life log handler for your mod

The script adds a Log object with some convinient functions to use for loggind and debugging purposes.

Version:    1.1
Modified:   2023-06-04
Author:     w33zl (github.com/w33zl | facebook.com/w33zl)

Changelog:
v1.0        Initial public release

License:    CC BY-NC-SA 4.0
This license allows reusers to distribute, remix, adapt, and build upon the material in any medium or 
format for noncommercial purposes only, and only so long as attribution is given to the creator.
If you remix, adapt, or build upon the material, you must license the modified material under identical terms. 

]]

local function createLog(modName, modDirectory)
    local modDescXML = loadXMLFile("modDesc", modDirectory .. "modDesc.xml");
    local title = getXMLString(modDescXML, "modDesc.title.en");
    delete(modDescXML);

    local function dummy(...) end
        
    local newLog = {
        modName = modName,
        title = title or modName,
        print = function(self, category, message, ...)
            message = (message ~= nil and message:format(...)) or ""
            if category ~= nil and category ~= "" then
                category = " " .. category .. ":"
            else
                category = ""
            end
            print(string.format("[%s]%s %s", self.title, category, tostring(message)))
        end,
        debug = function(self, message, ...) self:print("DEBUG", message, ...) end,
        var = function(self, name, variable)
            local valType = type(variable)
            
            if valType == "string" then
                variable = "'" .. variable .. "'"
            end
            
            self:print("DEBUG-VAR", "%s=%s [@%s]", name, tostring(variable), valType)
        end,
        trace = function(self, message, ...)end,
        table = function(self, tableName, tableObject, maxDepth) end,
        saveTable = function(self, fileName, tableName, tableObject, maxDepth, ignoredTables) end,
        tableX = function(self, tableName, tableObject, skipFunctions, unwrapTables)end,
        info = function(self, message, ...) self:print("", message, ...) end,
        warning = function(self, message, ...) self:print("Warning", message, ...) end,
        error = function(self, message, ...) self:print("Error", message, ...) end,
        newLog = function(self, name, includeModName)
            if name ~= nil then
                if includeModName then
                    name = modName .. "." .. name
                end
            else
                name = title
            end
            return {
                title = name,
                parent = self,
                print = self.print,
                info = self.info,
                warning = self.warning,
                error = self.error,
                debug = self.debug,
                var = self.var,
                table = self.table,
                tableX = self.tableX,
                trace = self.trace,
            }
        end,
    }

    local debugHelperFilename = modDirectory .. "lib/DebugHelper.lua"
    if fileExists(debugHelperFilename) then
        newLog:info("Debug mode enabled!")
        source(debugHelperFilename)

        if DebugHelper ~= nil then 
            DebugHelper:inject(newLog)
            -- if DebugHelper.dumpTable ~= nil then
            --     newLog.table = DebugHelper.dumpTable
            -- end
            -- if DebugHelper.decodeTable ~= nil then
            --     newLog.tableX = DebugHelper.decodeTable
            -- end
            -- if DebugHelper.traceLog ~= nil then
            --     newLog.trace = DebugHelper.traceLog
            -- end
        end
    else
        
        newLog.debug = dummy
        newLog.var = dummy
        newLog.trace = dummy
    end

    return newLog
end

Log = createLog(g_currentModName, g_currentModDirectory)