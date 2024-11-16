
MemoryProfiler = {}

function MemoryProfiler.new(text)
    local self = {
        first = 0,
        latest = 0,
        min = 0,
        max = 0,
        delta = 0,
        deltaMax = 0,
        text = text,
        __index = MemoryProfiler,
    }
    setmetatable(self, MemoryProfiler)
    MemoryProfiler.__index = MemoryProfiler
    return self
end

function MemoryProfiler:update()
    self.latest = gcinfo()
    self.min = math.min(self.min, self.latest)
    self.max = math.max(self.max, self.latest)
end

function MemoryProfiler:start()
    self.first = gcinfo()
    self.min = self.first
    self.max = self.first
    self.latest = self.first
    return self
end

function MemoryProfiler:stop()
    self:update()
    self.delta = self.latest - self.first
    self.deltaMax = self.max - self.first
    if self.text then
        print(string.format(self.text, self.delta, self.deltaMax))
    end
    return self.delta, self.deltaMax
end