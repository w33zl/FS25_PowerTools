I3DWriter = {
    DEFAULT_WORLD_COORDINATE_PRECISION = "%0.2f %0.2f %0.2f",
    DEFAULT_UV_PRECISION = "%d %d",
    DEFAULT_PRETTY_MODE = false,
    DEFAULT_INVERT_DIRECTION = false,
    DEFAULT_OPTIMIZE_ISLANDS = false,
    DEFAULT_USE_XY_COORDINATE_DIMENSIONS = false,
    DEFAULT_VERBOSE_MODE = false,

}
local I3DWriter_mt = Class(I3DWriter)

function I3DWriter.new(optimizeIslands, prettyMode, invertDirection, worldCoordinatePrecision, uvPrecision, useXYCoordinateDimensions)
    
	local self = {
        optimizeIslands = optimizeIslands or I3DWriter.DEFAULT_OPTIMIZE_ISLANDS,
        prettyMode = prettyMode or I3DWriter.DEFAULT_PRETTY_MODE,
        invertDirection = invertDirection or I3DWriter.DEFAULT_INVERT_DIRECTION,
        worldCoordinatePrecision = worldCoordinatePrecision or I3DWriter.DEFAULT_WORLD_COORDINATE_PRECISION,
        uvPrecision  = uvPrecision or I3DWriter.DEFAULT_UV_PRECISION,
        useXYCoordinateDimensions = useXYCoordinateDimensions or I3DWriter.DEFAULT_USE_XY_COORDINATE_DIMENSIONS,
        verboseMode = I3DWriter.DEFAULT_VERBOSE_MODE,
    }
    setmetatable(self, I3DWriter_mt)

    assert(type(self.optimizeIslands) == "boolean", "optimizeIslands needs to be a boolean")
    assert(type(self.prettyMode) == "boolean", "prettyMode needs to be a boolean")
    assert(type(self.invertDirection) == "boolean", "invertDirection needs to be a boolean")
    assert(type(self.useXYCoordinateDimensions) == "boolean", "useXYCoordinateDimensions needs to be a boolean")


    return self
end

function I3DWriter:setVerboseMode(enable)
    self.verboseMode = enable
end

function I3DWriter:setInvertDirection(enable)
    self.invertDirection = enable
end

function I3DWriter:setOptimizeIslands(enable)
    self.optimizeIslands = enable
end

function I3DWriter:setPrettyMode(enable)
    self.prettyMode = enable
end

function I3DWriter:setUseXYCoordinateDimensions(enable)
    self.useXYCoordinateDimensions = enable
end



local function createXmlHeader()
    return [[
<?xml version="1.0" encoding="iso-8859-1"?>
<i3D version="1.6">
    <Materials>
        <Material name="mat1" materialId="1" diffuseColor="0 0 1 0.5" alphaBlending="true"/>
    </Materials>
    <Shapes>
        <IndexedTriangleSet name="navMeshSegment" shapeId="1" meshUsage="1" bvCenter="0 0 0" bvRadius="0" isOptimized="true">
]]
end

local function createXmlFooter()
    return [[
        </IndexedTriangleSet>         
    </Shapes>
    <Scene>
        <Shape shapeId="1" name="nvm" nodeId="1" materialIds="1" distanceBlending="false"/>
    </Scene>
</i3D>
]]
end


function I3DWriter:writeMeshToFile(meshData, filename, forceOverwrite)
    assert(meshData ~= nil, "meshData is nil")
    assert(filename ~= nil, "filename is nil")

    assert(type(meshData) == "table", "meshData needs to be a table [" .. type(meshData) .. "]")
    assert(meshData.vertices ~= nil and meshData.triangles ~= nil, "meshData has invalid structure")

    forceOverwrite = forceOverwrite or false

    if not forceOverwrite and fileExists(filename) then
        Log:error("I3DWriter: Cannot write i3d, file already exists: " .. filename)
        return false
    end

    local triangles = meshData.triangles
    local vertices = meshData.vertices

    local measureAll = LogHelper:measureStart("Writing mesh to i3d file took %0.2fs", self.verboseMode)


    
    local function createVertice(x, y, z, u)
        local verticeString = "<v p=\"" .. string.format( self.worldCoordinatePrecision, x, y, z) ..  "\" n=\"0 1 0\" t0=\"" .. u .. "\"/>"
        if self.prettyMode then
            return "\t\t\t\t" .. verticeString .. "\n"
        else
            return verticeString
        end
    end
    
    local function createTriangle(v1, v2, v3, v4)
        v1 = v1 - 1
        v2 = v2 - 1
        v3 = v3 - 1
        -- v4 = v4 - 1

        local triangleString = "<t vi=\"" .. string.format( "%d %d %d", v1, v2, v3) ..  "\" />"
        if self.prettyMode then
            return "\t\t\t\t" .. triangleString .. "\n"
        else
            return triangleString
        end
    end    
    
    local function createVerticesStart(numVertices)
        local verticesString = string.format("<Vertices count=\"%d\" normal=\"true\" uv0=\"true\">", numVertices)
        if self.prettyMode then
            return "\t\t\t" .. verticesString .. "\n"
        else
            return verticesString
        end
    end
    
    local function createTriangleStart(numTriangles)
        local trianglesStartString = string.format("<Triangles count=\"%d\">", numTriangles)
        if self.prettyMode then
            return "\t\t\t" .. trianglesStartString .. "\n"
        else
            return trianglesStartString
        end        
    end
    
    local function createVerticesEnd()
        if self.prettyMode then
            return "\t\t\t</Vertices>\n"
        else
            return "</Vertices>"
        end        
    end
    
    local function createTrianglesEnd()
        if self.prettyMode then
            return "\t\t\t</Triangles>\n"
        else
            return "</Triangles>"
        end        
    end

    local function createSubsets(numVertices)
        local newLine = self.prettyMode and "\n" or ""
        local indent = self.prettyMode and "\t\t\t" or ""
        local indent2 = self.prettyMode and "\t\t\t\t" or ""
        return string.format("%s<Subsets count=\"1\">%s%s<Subset firstVertex=\"0\" numVertices=\"%d\" firstIndex=\"0\" numIndices=\"%d\" uvDensity0=\"0.199703\"/>%s%s</Subsets>%s", indent, newLine, indent2, numVertices, numVertices, newLine, indent, newLine)
    end
    
    local function writeToFile(filename, cb)
        local file = io.open(filename, "w")
    
        if file == nil then
            error("Could not open file")
            return
        end
    
        cb(file)
    
        file:close()
    
        return true
    end
    

    local function prepareUVs()
        return {
            string.format(self.uvPrecision, 0, 0),
            string.format(self.uvPrecision, 1, 0),
            string.format(self.uvPrecision, 0, 1),
            string.format(self.uvPrecision, 1, 1),
        }
    end
    local UVs = prepareUVs()

    Log:var("Mem before write i3d", collectgarbage("count"))

    local memUsageBeforeStart = collectgarbage("count")
    local memBudgetMB = 30
    local memThreshold = (memUsageBeforeStart + (memBudgetMB * 1024))

    writeToFile(filename, function (file)
        local verticeToTriangleIndex = {}
        file:write(createXmlHeader())
        --TODO: add posibility to add multiple shapes, materials etc

        file:write(createVerticesStart(#vertices))

        local expectedCoordinates = self.useXYCoordinateDimensions and 2 or 3

        collectgarbage()

        local function autoGC()
            local memUsedKB = collectgarbage("count")

            if memUsedKB > memThreshold then
                Log:debug("Memory usage increased from %d to %d", memUsageBeforeStart, memUsedKB)
                collectgarbage("collect")
                Log:var("Did one pass GC, mem usage is now", collectgarbage("count"))
            end
        
        end
        
        for verticeIndex, vertice in ipairs(vertices) do
            if expectedCoordinates ~= #vertice then
                Log:error("Wrong coordinate dimension for vertice %d, expected %d, got %d: ", verticeIndex, expectedCoordinates, #vertice)
                break
            end
            local x, y, z = unpack(vertice)
            if self.useXYCoordinateDimensions then
                z = y
                y = 0
            end
            -- local x, y, z = unpack(vertice) -- TODO: should also be Y
            file:write(createVertice(x, y, z, UVs[1]))

            if verticeIndex % 400 == 0 then
                usleep(1)

                autoGC()
            end
        end
        file:write(createVerticesEnd())

        collectgarbage()

        file:write(createTriangleStart(#triangles))
        for triangleIndex, triangle in ipairs(triangles) do
            file:write(createTriangle(triangle[1], triangle[2], triangle[3], triangle[4]))
            if triangleIndex % 200 == 0 then
                usleep(1)

                autoGC()
            end
        end
        file:write(createTrianglesEnd())

        file:write(createSubsets(#vertices))

        file:write(createXmlFooter())
    end)

    measureAll:stop()
end

-- return I3DWriter