
--[[

StringWriter (Weezls Mod Lib for FS25) - A string writer optimized for a balance between speed, memory usage and ease of use

Author:     w33zl (github.com/w33zl)
Version:    2.0
Modified:   2024-11-13

Changelog:
v2.0        Converted to FS25
v1.2        Added TimedExecution
v1.1        Added saveTable function
v1.0        Initial public release

License:    CC BY-NC-SA 4.0
This license allows reusers to distribute, remix, adapt, and build upon the material in any medium or 
format for noncommercial purposes only, and only so long as attribution is given to the creator.
If you remix, adapt, or build upon the material, you must license the modified material under identical terms. 

]]


StringWriter = {}
local StringWriter_mt = Class(StringWriter)

function StringWriter.new(writeDelegate, ...)
    writeDelegate = writeDelegate or print
    local appendTrailingNewline = false
    local collectGarbageOnFlush = true
	local self = {
        rawString = "",
        writeDelegate = writeDelegate,
        delegateParams = {...},
        chunkCount = 0,
        dataLength = 0,
        bufferedChunks = 0,
        bufferedLength = 0,
        MAX_CHUNKS = 150,
        MAX_BUFFER_LENGTH = 1024 * 4,
        collectGarbageOnFlush = collectGarbageOnFlush,
        enableTrailingNewLine = function(self, enabled) appendTrailingNewline = (enabled == nil) or false end,
        onFlush = function () end,
        getTrimmedText = function(self)
            if not appendTrailingNewline then
                return string.gsub(self.rawString, "\n$", "") -- remove trailing newline
            else
                return self.rawString
            end
        end,
    }
    setmetatable(self, StringWriter_mt)
    -- self:enableTrailingNewLine(false)
    return self
end

function StringWriter:append(any)
    local chunkSize = string.len(any)
    self.dataLength = self.dataLength + chunkSize
    self.chunkCount = self.chunkCount + 1
    self.bufferedChunks = self.bufferedChunks + 1
    self.bufferedLength = self.bufferedLength + chunkSize

    -- print(string.format("Adding %d, total chunks %d, total length %d", string.len(any), self.chunkCount, self.dataLength))
    self.rawString = self.rawString .. any

    if self.bufferedChunks > self.MAX_CHUNKS then
        -- print("Chunk treshold met")
        self:flush()
    end

    if self.bufferedLength > self.MAX_BUFFER_LENGTH then
        -- print("Size treshold met")
        self:flush()
    end
end

function StringWriter:appendF(formatString, ...)
    self:append(string.format(formatString, ...))
end

function StringWriter:appendLine(any)
    self:append(any .. "\n")
end

function StringWriter:appendLineF(formatString, ...)
    self:append(string.format(formatString, ...) .. "\n")
end

function StringWriter:flush()
    -- local params = { unpack(self.delegateParams) }
    -- params[#params+1] = self.rawString
    -- self.writeDelegate(unpack(params)

    local outputText = self:getTrimmedText()

    if next(self.delegateParams) ~= nil then
        self.writeDelegate(unpack(self.delegateParams), outputText)
    else
        self.writeDelegate(outputText)
    end

    if self.memoryProfiler ~= nil and type(self.memoryProfiler.update) == "function"  then
        self.memoryProfiler:update()
    end

    self.rawString = nil
    self.bufferedChunks = 0
    self.bufferedLength = 0

    if self.collectGarbageOnFlush then
        collectgarbage("collect")
    end

    self:onFlush()

    self.rawString = ""

end