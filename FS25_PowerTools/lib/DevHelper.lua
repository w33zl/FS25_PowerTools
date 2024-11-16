--[[

DevHelper (Weezls Mod Lib for FS22) - A utility "class" to assist mod development

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

DevHelper = {}
_G.DevHelper = DevHelper

--- Executes any function and returns the time it took to execute. 
--- The first return value is the execution time (in ms) and the rest of the values are the return values from the callback function.
---@param callback function Callback function to execute
---@return number timeElapsed "Execution time (in ms)"
---@return  returnValues "A list of return values from the callback function" 
function DevHelper.timedExecution(callback)
    local startTime = getTimeSec()

    local returnValue = { callback() }
    local timeElapsed = (getTimeSec() - startTime)

    return timeElapsed, unpack(returnValue)
end


--- Starts a execution timer with the given format string.
---@param formatString string "Format string to print the execution time (you need to add '%f' to the string)"
---@return table "Execution timer object with the stop function (call ':stop(true)' to supress automatic print of the results)"
---@remark The results will be printed to the console when the timer is stopped (see ':stop()') unless the 'noPrint' parameter is set to true (e.g. ':stop(true)').
function DevHelper.measureStart(formatString)
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
        elapsed = function(self)
            return getTimeSec() - self.startTime
        end,
    }
end


---Prints a table in a human readable format. 
---@param table table The table to print
---@param maxDepth number The maximum depth to print
---@param verbose boolean Whether to print verbose information (e.g. type information)
function DevHelper.visualizeTable(table, maxDepth, verbose)
    assert(StringWriter, "StringWriter class from WeezlsModLib is not available, please install it to use DevHelper.visualizeTable")
    local PREFIX = string.char(195) .. string.char(196) .. " " -- .. string.char(196)
    local PREFIX_TABLE = string.char(195) .. string.char(194) .. " " -- .. string.char(196)
    -- local PREFIX_TABLE = string.char(192) .. string.char(194) .. string.char(196)
    local INDENT_PREFIX = string.char(179)

    local PREFIX = unicodeToUtf8(0x251C) .. " " -- .. string.char(196)
    local PREFIX_TABLE = unicodeToUtf8(0x251C) .. unicodeToUtf8(0x252C) .. " " -- .. string.char(196)
    local INDENT_PREFIX = unicodeToUtf8(0x2502)
    
    -- PREFIX = ""
    -- PREFIX_TABLE = "-"

    -- PREFIX = unicodeToUtf8(PREFIX)
    -- PREFIX_TABLE = unicodeToUtf8(PREFIX_TABLE)
    

    local writer = StringWriter.new()
    writer:enableTrailingNewLine(false)

    maxDepth = maxDepth or 2
    verbose = verbose or false

    local function printTable(t, indent, depth)
        local firstValue = true
        depth = depth or 1
        -- if depth >= maxDepth then return end
        if indent == nil then indent = "" end
        --TODO: improve indexing using next, we can identify last item and choose different prefix

        for k, v in pairs(t) do
            local CURRENT_PREFIX = indent .. PREFIX --.. " "
            -- if firstValue and indent ~= "" then
            --     CURRENT_PREFIX = PREFIX_TABLE .. ""
            --     firstValue = false
            -- end

            -- if type(k) == "table" then
            --     k = k:gsub("table:", "{") .. " }"
            -- end

            -- if type(k) == "string" then
            --     k = k:gsub("table:", "{")
            -- end

            local indexOrKey = tostring(k)

            if type(k) == "number" then
                indexOrKey = string.format("[%d]", k)
            elseif type(k) == "boolean" then
                indexOrKey = "[\"" .. tostring(k) .. "\"]"
            elseif type(k) == "table" then
                indexOrKey = string.format("[\"%s\"]", k)
            elseif type(k) == "string" and not indexOrKey:match("^[%w_]+$") then
                indexOrKey = string.format("[\"%s\"]", k)
            end            

            if type(v) == "table" then
                --TODO: make this better when max depth
                if next(v) ~= nil and depth < maxDepth then
                    writer:appendLine(indent .. PREFIX_TABLE .. indexOrKey .. ": -- " .. tostring(v))
                    printTable(v,  indent .. INDENT_PREFIX, depth + 1)
                else
                    local tableContents = next(v) ~= nil and " ... " or ""
                    writer:appendLine(indent .. PREFIX .. indexOrKey .. ":: {"  .. tableContents .. "}")
                    -- print(indent .. string.char(192))
                end
            else
                local typeName = ""

                if verbose and type(v) ~= "function" then
                    typeName = " [" .. type(v) .. "]"
                end

                if type(v) == "boolean" then
                    v = tostring(v)
                elseif type(v) == "function" then
                    v = "function()" .. tostring(v)
                elseif type(v) == "userdata" then
                    v = "-- userdata: " .. tostring(v)
                end

                -- --HACK: disable type name
                -- typeName = ""

                -- if typeName ~= "" then
                --     typeName = " [" .. typeName .."]"
                -- end

                writer:appendLine(CURRENT_PREFIX .. indexOrKey .. ": " .. v.. typeName)
                -- print(CURRENT_PREFIX .. k .. " [" .. typeName .."]" .. ": " .. v)

                firstValue = false
            end
        end
        -- if firstValue then
        --     print(indent .. string.char(192))
        -- end
    end

    printTable(table)
    writer:flush()
end



function DevHelper.saveTableToFile(fileName, tableName, tableObject, maxDepth, ignoredTables, writer, memProfiler, header)
    maxDepth = maxDepth or 2

    if tableObject == nil then
        Log:error("Table '%s' was nil, skipped saving to file '%s'", tableName, fileName)
        return
    end

    -- local fileId = createFile(fileName, FileAccess.WRITE)
    -- local writer = nil



    local function getTableInfo(inputTable, inputIndent, depth, desiredDepth, knownTables, ignoredTables)
        inputIndent = inputIndent or "\t"
        depth = depth or 0
        desiredDepth = desiredDepth or 2

    
        if depth > desiredDepth then
            return nil
        end
    
        --TODO: improve to keep track of the "path" to known tables and use that with the references?
        knownTables = knownTables or {}
    
        -- Always this current table to known tables
        knownTables[tostring(inputTable)] = true

        -- local string1 = ""
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
            elseif type(i) == "boolean" then
                indexOrKey = "[\"" .. tostring(i) .. "\"]"
            elseif type(i) == "table" then
                indexOrKey = string.format("[\"%s\"]", i)
            elseif type(i) == "string" and not indexOrKey:match("^[%w_]+$") then
                indexOrKey = string.format("[\"%s\"]", i)
            end

            -- if type(j) == "userdata" then
            --     j = string.format("userdata: (%s)", tostring(j))
            -- end

            if type(j) == "table" and knownTables[tostring(j)] == true then
                -- string1 = string1 .. string.format("\n%s%s = {}, -- REFERENCE %s\n", inputIndent, indexOrKey, tostring(j))
                --TODO: change to embeeded --[[]] comment instead
                writer:appendF("\n%s%s = {}, -- REFERENCE %s", inputIndent, indexOrKey, tostring(j))
            elseif type(j) == "table" and ignore[tostring(i)] == true then
                -- print(string.format("Skipped table '%s'", indexOrKey))
                writer:appendF("Skipped table '%s'", indexOrKey)
            elseif type(j) == "table" then
                -- local string2 = getTableInfo(j, inputIndent .. "\t", depth + 1, desiredDepth, knownTables, ignore)
    
                -- string1 = string1 .. string.format("\n%s %s = { -- %s\n", inputIndent, tostring(i), tostring(j))
    
    
                -- if string2 ~= nil then
                --     string2 = string.format("%s%s", inputIndent, string2)

                --     -- string1 = string1 .. string.format("\n%s%s = { -- %s%s\n%s},", inputIndent, indexOrKey, tostring(j), string2, inputIndent)
                --     writer:appendF("\n%s%s = { -- %s%s\n%s},", inputIndent, indexOrKey, tostring(j), string2, inputIndent)
                -- else
                    -- string1 = string1 .. string.format("\n%s%s = {}, -- %s\n", inputIndent, indexOrKey, tostring(j))
                    writer:appendF("\n%s%s = {}, -- %s", inputIndent, indexOrKey, tostring(j))
                -- end

                getTableInfo(j, inputIndent .. "\t", depth + 1, desiredDepth, knownTables, ignore)
    
                -- knownTables[tostring(j)] = true
    
            elseif type(j) == "function" and ignore[j] ~= true then
                -- string1 = string1 .. string.format("\n%s%s = function() end, -- %s", inputIndent, indexOrKey, tostring(j))
                writer:appendF("\n%s%s = function() end, -- %s", inputIndent, indexOrKey, tostring(j))
    
    
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
    
                --TODO: remove data type name?
                -- string1 = string1 .. string.format("\n%s%s = %s, -- %s", inputIndent, indexOrKey, value, type(j))
                writer:appendF("\n%s%s = %s, -- %s", inputIndent, indexOrKey, value, type(j))
            end

            if memProfiler ~= nil then
                memProfiler:update()
            end
        end
    
        -- writer:flush()
        -- return string1
    end

    local file = io.open(fileName, "w")

    if file ~= nil then
        if writer == nil then
            writer = StringWriter.new(function(...) file:write(...) end)
        end

        if writer == nil then
            Log:error("No walid writer delegate was found, cannot save table '%s' to file '%s'", tableName, fileName)
            return
        end
        -- Log:debug("Writing to file handle #%d", fileId)

        -- local memProfiler = nil
        -- if memProfiler == nil and MemoryProfiler ~= nil then
        --     memProfiler = MemoryProfiler.new("Saving table consumed %.2f kb of memory")
        --     -- local memUsed, memUsedMax = memProfiler:stop(true)
        --     -- Log:debug("Memory used: %.2f (max %.2f) KB", memUsed / 1024, memUsedMax / 1024)
        -- end

        writer.memoryProfiler = memProfiler

        local executionTimer = DevHelper.measureStart("")
        local lastElapsedValue = 0

        writer.MAX_CHUNKS = 25000
        writer.MAX_BUFFER_LENGTH = 1024 * 400

        writer.onFlush = function()
            local elapsed = executionTimer:elapsed()
            if elapsed - lastElapsedValue >= 10 then
                print("Still working on it... Time elapsed " .. elapsed .. " seconds")
                lastElapsedValue = elapsed
                usleep(1)
                if memProfiler ~= nil then
                    memProfiler:update()
                end
                collectgarbage()
            end
        end

        if header ~= nil then
            writer:appendLine(header)
        end

        writer:appendF("%s = {", tableName)

        getTableInfo(tableObject, "\t", 0, maxDepth - 1, {}, ignoredTables)

        writer:appendLine("\n}")
        writer:flush()

        executionTimer = nil

        file:close()
    else
        Log:error("Filed to open file '%s'", fileName)
        return
    end
end
