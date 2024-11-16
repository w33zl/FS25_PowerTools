MeshBuilder = {
    DEFAULT_OPTIMIZE_ISLANDS = false,
    DEFAULT_RENDER_HALF_PIXELS = false
}
local MeshBuilder_mt = Class(MeshBuilder)

function MeshBuilder.new(worldSize, optimizeIslands, renderHalfPixels)
    local DEFAULT_DENSITYMAP_SIZE = g_currentMission.terrainSize * g_densityMapHeightManager.worldToDensityMap
	local self = {
        DEFAULT_DENSITYMAP_SIZE = DEFAULT_DENSITYMAP_SIZE,
        worldSize = worldSize or DEFAULT_DENSITYMAP_SIZE,
        optimizeIslands = optimizeIslands or MeshBuilder.DEFAULT_OPTIMIZE_ISLANDS,
        renderHalfPixels = renderHalfPixels or MeshBuilder.DEFAULT_RENDER_HALF_PIXELS,
    }
    setmetatable(self, MeshBuilder_mt)

    if self.optimizeIslands then
        Log:warning("MeshBuilder: optimizeIslands is not yet fully implemented")
    end

    Log:debug("MeshBuilder initialized")
    Log:var("worldSize", self.worldSize)
    Log:var("optimizeIslands", self.optimizeIslands)
    Log:var("renderHalfPixels", self.renderHalfPixels)

    
    Log:var("g_currentMission.terrainSize", g_currentMission.terrainSize)
    Log:var("densityMapSize", getDensityMapSize(g_currentMission.terrainDetailId))

    Log:var("g_densityMapHeightManager.worldToDensityMap", g_densityMapHeightManager.worldToDensityMap)
    Log:var("g_densityMapHeightManager.densityToWorldMap", g_densityMapHeightManager.densityToWorldMap)
    
    self:clearMesh()

    return self
end

function MeshBuilder:clearMesh()
    self.currentMesh = {
        vertices = {},
        triangles = {},
        verticePositionToIndex = {},
        touchedPixels = {},
        processedVertices = 0,
        duplicateVertices = 0,
        skippedPixels = 0,
        boundingBox = {}
    }
end

function MeshBuilder:getBoundingBox()
    return self.currentMesh.boundingBox
end



-- function fieldFinder_callback(worldX, worldZ, value)
--     if value == 2 then
--         local v1 = newVertex(worldX, 0, worldZ)
--         local v2 = newVertex(worldX + 1, 0, worldZ)
--         local v3 = newVertex(worldX + 1, 0, worldZ + 1)
--         local v4 = newVertex(worldX, 0, worldZ + 1)
--         -- table.insert(triangles, { v3, v2, v1 })
--         table.insert(triangles, { v1, v2, v3 })
--         -- table.insert(triangles, { v1, v3, v4 })
        
--     end
--     outData[worldZ] = outData[worldZ] or {}
--     outData[worldZ][worldX] = value
-- end

function MeshBuilder:getPositionIndex(x, z)
    return (z * self.worldSize) + x --y * boundingBoxWidth) + x
end

function MeshBuilder:getCoordinatesFromPosition(pos)
    local x = pos % self.worldSize
    local z = (pos - x) / self.worldSize
    return { x, z }
end

function MeshBuilder:addVertice(x, y, z)
    local current = self.currentMesh

    --TODO: add support for Y axis as well!!

    current.processedVertices = current.processedVertices + 1

    local vertices = current.vertices
    local verticePositionToIndex = current.verticePositionToIndex
    local boundingBox = current.boundingBox

    boundingBox.xMax = math.max(boundingBox.xMax or x, x)
    boundingBox.xMin = math.min(boundingBox.xMin or x, x)
    boundingBox.zMax = math.max(boundingBox.zMax or z, z)
    boundingBox.zMin = math.min(boundingBox.zMin or z, z)

    --BUG: reuse known vertices doesn't really work..
    local posIndex = self:getPositionIndex(x, z)
    local verticeIndex = verticePositionToIndex[posIndex] -- Get cached vertex index
    local shouldAdd = verticeIndex == nil or not self.optimizeIslands

    if verticeIndex ~= nil then
        current.duplicateVertices = current.duplicateVertices + 1
    end

    if shouldAdd then
        --TODO: get world y from heightmap if y == nil
        table.insert( vertices, {x, z} )

        verticeIndex = #vertices

        verticePositionToIndex[posIndex] = verticeIndex
    end

    return verticeIndex, x, z
end

function MeshBuilder:createMeshAsync(triggerState)
    triggerState = triggerState or 1
    -- assert(triggerState, "triggerState must not be nil")
    assert(type(triggerState) == "number", "triggerState must be a number")
    assert(triggerState >= 0, "triggerState must be a positive integer")

    self:clearMesh()

    Log:var("optimizeIslands", self.optimizeIslands)
    Log:var("worldSize", self.worldSize)
    Log:var("triggerState", triggerState)

    local PIXEL_SIZE = g_currentMission.terrainSize / self.worldSize
    
    local PIXEL_STEP = g_currentMission.terrainSize / self.worldSize
    local PIXEL_SIZE = 0.5

    Log:var("PIXEL_SIZE", PIXEL_SIZE)

    local current = self.currentMesh
    local vertices = current.vertices
    local verticePositionToIndex = current.verticePositionToIndex
    local triangles = current.triangles

    local touchedPixels = current.touchedPixels
    local isFirst = true

    self.currentMesh.numCallbacks = 0

    return function(worldX, worldZ, pixelState)
        self.currentMesh.numCallbacks = self.currentMesh.numCallbacks + 1
        if pixelState == triggerState then
            -- if not isFirst then
            --     return
            -- end

            -- Calculate virtual pixel coordinates based on pixel size
            local targetX = worldX - (worldX % PIXEL_SIZE)
            local targetZ = worldZ - (worldZ % PIXEL_SIZE)
            local targetPosition = self:getPositionIndex(targetX, targetZ)
            
            if touchedPixels[targetPosition] then
                current.skippedPixels = current.skippedPixels + 1
                return
            end
            touchedPixels[targetPosition] = true

            

            local v1 = { self:addVertice(worldX, 0, worldZ) }
            -- local v2 = { self:addVertice(worldX + PIXEL_SIZE, 0, worldZ)}
            local v2 = { self:addVertice(worldX - PIXEL_SIZE, 0, worldZ)}
            local v3 = { self:addVertice(worldX, 0, worldZ + PIXEL_SIZE)}
            local v4 = {}
            table.insert(triangles, { v1[1], v2[1], v3[1] })

            if not self.renderHalfPixels then
                v4 = { self:addVertice(worldX - PIXEL_SIZE, 0, worldZ + PIXEL_SIZE) }
                table.insert(triangles, { v3[1], v2[1], v4[1] })
                -- local v4 = self:addVertice(worldX, 0, worldZ + PIXEL_SIZE)
                -- table.insert(triangles, { v3, v4, v1 })

            end

            if isFirst then
                isFirst = false

                Log:table("First triangle", {
                    position = {worldX, worldZ},
                    v1 = v1,
                    v2 = v2,
                    v3 = v3,
                })
                Log:table("Second triangle", {
                    position = {worldX, worldZ},
                    v3 = v3,
                    v2 = v2,
                    v4 = v4,
                })
            end

        end
    end
end


function MeshBuilder:finalizeCreateMeshAsync()
    local returnData = {
        vertices = self.currentMesh.vertices,
        triangles = self.currentMesh.triangles
    }
    local returnMetaData = {
        processedVertices = self.currentMesh.processedVertices,
        duplicateVertices = self.currentMesh.duplicateVertices,
        skippedPixels = self.currentMesh.skippedPixels,
        boundingBox = self.currentMesh.boundingBox,
        numCallbacks = self.currentMesh.numCallbacks,
    }
    self:clearMesh()
    return returnData, returnMetaData
end

function MeshBuilder:createMeshFromPixels(pixelData, pixelToWorldRatio, triggerState)
    Log:debug("MeshBuilder:createMeshFromPixels")
    local measureAll = LogHelper:measureStart("Mesh generated from pixel data in %0.2fs", true)

    pixelToWorldRatio = pixelToWorldRatio or 1

    -- self:clearMesh()
    local processPixelCallback = self:createMeshAsync(triggerState)

    Log:var("pixelToWorldRatio", pixelToWorldRatio)


    local current = self.currentMesh

    local vertices = current.vertices
    local verticePositionToIndex = current.verticePositionToIndex
    local triangles = current.triangles

    local function pixelToWorldCoordinate(x, z)
        return { x * pixelToWorldRatio, z * pixelToWorldRatio }
    end

    local measureGenerateVertices = LogHelper:measureStart("Generate vertices from pixel data took %fs")
    local processedPixels = 0
    for z, row in ipairs(pixelData) do
        -- boundingBoxWidth = math.max(boundingBoxWidth, #row)
        for x, pixel in ipairs(row) do

            if pixel ~= 0 then
                processedPixels = processedPixels + 1
                local worldX, worldZ = unpack(pixelToWorldCoordinate(x, z))
                processPixelCallback(worldX, worldZ, pixel)
                -- self:addTriangle(x, 0, z, 1, 1)
            else
                
            end
        end
    end
    measureGenerateVertices:stop()

    local p = self:getPositionIndex(28, 997)
    -- local p = getPositionIndex(10, 10)
    -- local p = getPositionIndex(1, 1)
    -- local p = self:getPositionIndex(0, 0)
    local v = self:getCoordinatesFromPosition(p)

    Log:var("p", p)
    Log:var("v", table.concat(v, ","))

    Log:var("processedPixels", processedPixels)
    Log:var("duplicateVertices", current.duplicateVertices)
    Log:var("initialVertices", current.processedVertices)
    Log:var("optimizedVertices", #vertices)

    local allData = {
        vertices = vertices,
        verticePositionToIndex = verticePositionToIndex,
        triangles = triangles,
        boundingBox = current.boundingBox,
    }

    DebugHelper:saveTable("D:/OneDrive/Projects/lua/LuaLabb/Output/VerticeData2.lua", "O", allData, 10)

    measureAll:stop()

    return self:finalizeCreateMeshAsync()
end

function MeshBuilder:convertPixelsToTriangles(pixelData)
    assert(pixelData, "pixelData must not be nil")
    local vertices = {}
    local verticePositionToIndex = {}
    local triangles = {}

    local optimizeIslands = self.optimizeIslands

    local boundingBoxWidth = 0

    local measureBBox = DebugHelper:measureStart("Calculate bounding box width took %fs")
    for y, row in ipairs(pixelData) do
        boundingBoxWidth = math.max(boundingBoxWidth, #row)
    end
    measureBBox:stop()

    Log:var("boundingBoxWidth", boundingBoxWidth)

    local function getPositionIndex(x, z)
        return (z * self.worldSize) + x --y * boundingBoxWidth) + x
    end

    local function getCoordinatesFromPosition(pos)
        local x = pos % self.worldSize
        local z = (pos - x) / self.worldSize
        return { x, z }
    end


    local duplicateVertices = 0
    local processedVertices = 0

    local function addVertice(x, y, z)
        processedVertices = processedVertices + 1

        --TODO: reuse known vertices
        local posIndex = getPositionIndex(x, z)
        local verticeIndex = verticePositionToIndex[posIndex] -- Get cached vertex index
        local shouldAdd = verticeIndex == nil or not optimizeIslands

        if verticeIndex ~= nil then
            duplicateVertices = duplicateVertices + 1
        end

        if shouldAdd then
            table.insert( vertices, {z, x} )

            verticeIndex = #vertices

            -- verticePositionToIndex[getPositionIndex(x, z)] = verticeIndex

            verticePositionToIndex[posIndex] = verticeIndex

            -- if verticePositionToIndex[posIndex] == nil then
            --     verticePositionToIndex[posIndex] = verticeIndex
            -- else
            --     duplicateVertices = duplicateVertices + 1
            --     -- Log:debug("Duplicate found")
            -- end
    
        -- else
        --     duplicateVertices = duplicateVertices + 1
        end

        return verticeIndex
    end

    local function addTriangle(x, y, z, width, height)
        -- table.insert( triangles, {x, y, z, width, height} )

        local v1 = addVertice(x, y, z)
        local v2 = addVertice(x + width, y, z)
        local v3 = addVertice(x + width, y, z + height)

        table.insert( triangles, {v1, v2, v3} )
    end

    local measureGenerateVertices = DebugHelper:measureStart("Generate vertices took %fs")
    for z, row in ipairs(pixelData) do
        boundingBoxWidth = math.max(boundingBoxWidth, #row)
        for x, pixel in ipairs(row) do
            if pixel == 1 then
                addTriangle(x, 0, z, 1, 1)

                -- addTriangle(x + 1, 0, z + 1, -1, -1)

                -- --TODO: reuse known vertices

                -- table.insert( vertices, {z, x} )

                -- verticePositionToIndex[getPositionIndex(x, z)] = #vertices

                -- local posIndex = getPositionIndex(x, z)

                -- if verticePositionToIndex[posIndex] == nil then
                --     verticePositionToIndex[posIndex] = #vertices
                -- else
                --     Log:debug("Duplicate found")
                -- end


            end
        end
    end
    measureGenerateVertices:stop()

    local p = getPositionIndex(28, 997)
    -- local p = getPositionIndex(10, 10)
    -- local p = getPositionIndex(1, 1)
    local p = getPositionIndex(0, 0)
    local v = getCoordinatesFromPosition(p)

    -- Log:var("p", p)
    -- Log:var("v", table.concat(v, ","))

    Log:var("duplicateVertices", duplicateVertices)
    Log:var("initialVertices", processedVertices)
    Log:var("optimizedVertices", #vertices)

    local allData = {
        vertices = vertices,
        verticePositionToIndex = verticePositionToIndex,
        triangles = triangles,
    }

    DebugHelper:saveTable("D:/OneDrive/Projects/lua/LuaLabb/Output/VerticeData.lua", "O", allData, 10)

    -- local meshData = {
    --     vertices = vertices,
    --     triangles = triangles
    -- }

    return {
        vertices = vertices,
        triangles = triangles
    }
    
end