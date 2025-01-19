function Enumerable(originalTable, sorted, sortOnKey)
    -- Store the original data in a separate table
    local keyToValue = {}
    local valueToKey = {}
    local keys = {}
    for k, v in pairs(originalTable) do
        keyToValue[k] = v
        valueToKey[v] = k
        table.insert(keys, k)
    end

    if sorted then
        if sortOnKey then
            table.sort(keys, function(a, b)
                return a < b
            end)
        else
            table.sort(keys, function(a, b)
                return keyToValue[a] < keyToValue[b]
            end)
        end
    end


    -- Add utility functions to the original table
    function originalTable.getAll()
        return keyToValue
    end

    function originalTable.getNames()
        return keys
    end


    --- Get the name of the value
    ---@param index any
    ---@return any
    function originalTable.getName(index)
        return valueToKey[index]
    end

    local function customPairs()
        local i = 0
        return function()
            i = i + 1
            local key = keys[i]
            -- print("key: " .. tostring(key))
            if key then
                return key, keyToValue[key]
            end
        end
    end

    local function customIPairs()
        local i = 0
        return function()
            i = i + 1
            local key = keys[i]
            -- print("key: " .. tostring(key))
            if key then
                return keyToValue[key], key
            end
        end
    end

    function originalTable.iterate()
        return customPairs()
    end

    -- Metatable for the read-only behavior
    local readOnlyMetatable = {
        __index = function(_, key)
            print("key: " .. tostring(key))
            return keyToValue[key]
        end,
        __newindex = function(_, key, value)
            error("Attempt to modify a read-only table: " .. tostring(key) .. " = " .. tostring(value))
        end,
        __pairs = customPairs,
        __ipairs = customIPairs,
        -- __pairs = function()
        --     return nil --pairs(keyToValue)
        -- end,
        -- __ipairs = function()
        --     return ipairs(keys)
        -- end
    }

    -- -- Override the global `pairs` function for this table
    -- local oldPairs = pairs
    -- function pairs(t)
    --     local mt = getmetatable(t)
    --     if mt and mt.__pairs then
    --         return mt.__pairs()
    --     end
    --     return oldPairs(t)
    -- end    

    -- local oldIPairs = ipairs
    -- function ipairs(t)
    --     local mt = getmetatable(t)
    --     if mt and mt.__ipairs then
    --         return mt.__ipairs()
    --     end
    --     return oldIPairs(t)
    -- end    

    -- Set the metatable to enforce read-only
    return setmetatable(originalTable, readOnlyMetatable)
end
