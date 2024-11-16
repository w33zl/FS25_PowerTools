--[[

DebugHelper (Weezls Mod Lib for FS22) - A extension "class" that improves the LogHelper by adding some additional features specifically for debugging

Author:     w33zl (github.com/w33zl | facebook.com/w33zl)
Version:    1.2
Modified:   2023-08-10

Changelog:
v1.2        Added TimedExecution
v1.1        Added saveTable function
v1.0        Initial public release

License:    CC BY-NC-SA 4.0
This license allows reusers to distribute, remix, adapt, and build upon the material in any medium or 
format for noncommercial purposes only, and only so long as attribution is given to the creator.
If you remix, adapt, or build upon the material, you must license the modified material under identical terms. 

]]

DebugHelper = {
    dumpTable = function(self, tableName, tableObject, maxDepth)
        maxDepth = maxDepth or 2
        if tableObject == nil then
            print(tableName .. ":: [nil]")
        elseif type(tableObject) ~= "table" then
            Log:warning("%s is not a table, cannot print table contents", tableName)
        else
            DebugUtil.printTableRecursively(tableObject, tableName .. ":: ", 0, maxDepth)
        end
    end,

    saveTable = function(self, fileName, tableName, tableObject, maxDepth, ignoredTables)
        maxDepth = maxDepth or 2

        local function getTableInfo(inputTable, inputIndent, depth, desiredDepth, knownTables, ignoredTables)
            inputIndent = inputIndent or "  "
            depth = depth or 0
            desiredDepth = desiredDepth or 2
        
            if depth > desiredDepth then
                return nil
            end
        
            knownTables = knownTables or {}
        
            -- Always this current table to known tables
            knownTables[tostring(inputTable)] = true
        
            local string1 = ""
        
            local ignore = {
                -- string = true,
                -- math = true,
                -- table = true
            }
            ignore = ignoredTables or ignore
        
            for i, j in pairs(inputTable) do
                local indexOrKey = tostring(i)
                
                if type(i) == "number" then
                    indexOrKey = string.format("[%d]", i)
                elseif type(i) == "table" then
                    indexOrKey = string.format("[\"%s\"]", i)
                elseif type(i) == "string" and not indexOrKey:match("^[%w_]+$") then
                    indexOrKey = string.format("[\"%s\"]", i)
                end

                -- if type(j) == "userdata" then
                --     j = string.format("userdata: (%s)", tostring(j))
                -- end

                if type(j) == "table" and knownTables[tostring(j)] == true then
                    string1 = string1 .. string.format("\n%s%s = {}, -- REFERENCE %s\n", inputIndent, indexOrKey, tostring(j))
                elseif type(j) == "table" and ignore[tostring(i)] == true then
                    print(string.format("Skipped table '%s'", indexOrKey))
                elseif type(j) == "table" then
                    local string2 = getTableInfo(j, inputIndent .. "\t", depth + 1, desiredDepth, knownTables, ignore)
        
                    -- string1 = string1 .. string.format("\n%s %s = { -- %s\n", inputIndent, tostring(i), tostring(j))
        
        
                    if string2 ~= nil then
                        string2 = string.format("%s%s", inputIndent, string2)
                        string1 = string1 .. string.format("\n%s%s = { -- %s%s\n%s},", inputIndent, indexOrKey, tostring(j), string2, inputIndent)
                    else
                        string1 = string1 .. string.format("\n%s%s = {}, -- %s\n", inputIndent, indexOrKey, tostring(j))
                    end
        
                    -- knownTables[tostring(j)] = true
        
                elseif type(j) == "function" and ignore[j] ~= true then
                    string1 = string1 .. string.format("\n%s%s = function() end, -- %s", inputIndent, indexOrKey, tostring(j))
        
        
                    --TODO: maybe do a pcall and try to figure out return type and even parameters?!
                else
        
                    local value = tostring(j)
                    if type(j) == "string" then
                        value = value:gsub("\\\"", "\"")
                        value = value:gsub("\"", "\\\"")
                        value = value:gsub("\n", "\\\n")
                        value = value:gsub("\r", "\\\r")
                        value = value:gsub("\t", "\\\t")
                        value = string.format("\"%s\"", value)
                    elseif type(j) == "userdata" then
                        value = string.format("\"%s\"", value)
                    end
        
                    string1 = string1 .. string.format("\n%s%s = %s, -- %s", inputIndent, indexOrKey, value, type(j))
                end
            end
        
            return string1
        end

        if tableObject == nil then
            Log:error("Table '%s' was nil, skipped saving to file '%s'", tableName, fileName)
        else

            -- Log:debug("Opening file '%s'", fileName)
            
            local fileId = createFile(fileName, FileAccess.WRITE)
            
            if fileId ~= nil then
                -- Log:debug("Writing to file handle #%d", fileId)
            
                local output = getTableInfo(tableObject, "\t", 0, maxDepth - 1, {}, ignoredTables)
            
                fileWrite(fileId, string.format("%s = {%s\n}\n", tableName, output))

                delete(fileId)
                fileId = nil
            else
                Log:error("Filed to open file '%s'", fileName)
            end
        end
    end,

    decodeTable = function(self, tableName, tableObject, skipFunctions, unwrapTables)
        if Log == nil then return end
        if tableObject == nil then
            Log:warning("Table '%s' was not found", tableName)
            return 
        end

        skipFunctions = skipFunctions or false

        local function logIt(index, value)
            local typeName = type(value)
            if typeName == "string" then
                value = "\"" .. value .. "\""
            elseif skipFunctions and typeName == "function" then
                return -- Skip function
            else
                value = tostring(value)
            end
            Log:print("TABLE", "%s%s = %s [%s]", tableName, index, value, typeName)
        end
        
        for index, value in ipairs(tableObject) do
            logIt("[" .. tostring(index) .. "]", value)
        end

        for key, value in pairs(tableObject) do
            logIt("." .. key, value)
        end
    end,

    traceLog = function(self, message, ...)
        if Log == nil then return end
        Log.traceIndex = (Log.traceIndex or 999) + 1
        Log:print("TRACE-" .. tostring(Log.traceIndex), message, ...)
    end,

    inject = function(self, log)
        log.table = self.dumpTable
        log.tableX = self.decodeTable
        log.trace = self.traceLog
        log.saveTable = self.saveTable
    end,

    ---Intercepts a event/function call on any object and prints the input parameters
    ---@param target table The target object where to intercept a function
    ---@param functionName string Name of the function to intercept
    interceptDecode = function(self, target, functionName)
        local prefix = functionName

        local logger

        if Log ~= nil then
            logger = Log
        else
            logger = { 
                debug = function(self, message, ...) 
                    Logging.info("[DebugHelper] " .. message, ...)
                end
            }
        end

        local function internalDecoder(self, superFunc, ...)
            local a = { ... }
            print("")
            logger:debug("### DECODING: %s [Arg count=%d]", prefix, #a)
            for index, value in ipairs(a) do
                logger:debug("%s.param[%d]='%s' [%s]", prefix, index, tostring(value), type(value))
            end
        
            for index, value in ipairs(a) do
                if type(value) == "table" then
                    DebugUtil.printTableRecursively(value, prefix .. ".param[" .. tostring(index) .. "]:: ", 0, 1 )
                end
            end
        
            --TODO: fix - should pack/unpack?

            local returnValue = superFunc(self, ...)
            logger:debug("<< RETURN VALUE = %s [%s]", tostring(returnValue), type(returnValue))
            -- if type(returnValue) == "table" then
            --     DebugUtil.printTableRecursively(returnValue, "RETURN:: ", 0, 1)
            -- else
            --     Logging.extInfo("RETURN=%s [%s]", tostring(returnValue), type(returnValue))
            -- end
            
            return returnValue
        end
            
        
        target[functionName] = Utils.overwrittenFunction(target[functionName], internalDecoder)
    end
    
}


--- Executes any function and returns the time it took to execute. 
--- The first return value is the execution time (in ms) and the rest of the values are the return values from the callback function.
---@param callback function Callback function to execute
---@return number timeElapsed "Execution time (in ms)"
---@return  returnValues "A list of return values from the callback function" 
function DebugHelper:timedExecution(callback)
    local startTime = getTimeSec()

    local returnValue = { callback() }
    local timeElapsed = (getTimeSec() - startTime)

    return timeElapsed, unpack(returnValue)
end


--- Starts a execution timer with the given format string.
---@param formatString string "Format string to print the execution time (you need to add '%f' to the string)"
---@return table "Execution timer object with the stop function (call ':stop(true)' to supress automatic print of the results)"
---@remark The results will be printed to the console when the timer is stopped (see ':stop()') unless the 'noPrint' parameter is set to true (e.g. ':stop(true)').
function DebugHelper:measureStart(formatString)
    return {
        text = formatString,
        startTime = getTimeSec(),
        stop = function(self, noPrint)
            self.endTime = getTimeSec()
            self.diff = self.endTime - self.startTime
            self.results = string.format(formatString, self.diff)
            if not noPrint then
                print(self.results)
            end
            return self.results
        end,
    }
end
