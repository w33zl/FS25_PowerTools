--[[

MathHelper (Weezls Mod Lib for FS22) - Quality of life math utility functions for your mod

Author:     w33zl (github.com/w33zl | facebook.com/w33zl)
Version:    1.0
Modified:   2023-07-17

Changelog:
v1.0        Initial public release

License:    CC BY-NC-SA 4.0
This license allows reusers to distribute, remix, adapt, and build upon the material in any medium or 
format for noncommercial purposes only, and only so long as attribution is given to the creator.
If you remix, adapt, or build upon the material, you must license the modified material under identical terms. 

]]


---Print formatted strings (like printf in other languages), basically a wrapper for 'print(string.format(...))', useful for debugging
---@param stringFormat string Format string
---@param ... any Values to be passed on to string.format
local function printf(stringFormat, ...)
    print(string.format(stringFormat, ...))
end


--- Rounds a number to a specified number of decimal places
--- @param x (number) The number to round
--- @param decimals (integer) The number of decimal places to round to (default: 0)
--- @return (number) "The rounded number"
local function round(x, decimals)
    --* To make the round function faster and more efficient we use the math.pow function instead of 10^decimals to calculate the power of 10. This avoids unnecessary exponentiation
    return math.floor(x * math.pow(10, decimals or 0) + 0.5) / math.pow(10, decimals or 0)
end


--- Rounds a number to a specified number of decimal places
--- @param x (number) The number to round
--- @param decimals (integer) The number of decimal places to round to (optional, default is 0)
--- @return (number) "The floored number"
local function floorEx(x, decimals)
    local powerOf10 = math.pow(10, decimals or 0)
    return math.floor(x * powerOf10 + 0.0000001) / powerOf10 --? Do we really need to add 0.0000001?
end


--- Rounds up a number to the specified number of decimal places
--- @param x The number to round up
--- @param decimals (optional) The number of decimal places to round up to (default is 0)
--- @return (number) "The rounded up number"
local function ceilEx(x, decimals)
    local powerOf10 = math.pow(10, decimals or 0)
    return math.ceil( x * powerOf10 - 0.0000001) / powerOf10 --? Is it correct to subtract 0.0000001?
end


-- Create our utility class
MathHelper = MathHelper or {}
MathHelper.round = MathHelper.round or round
MathHelper.floor = MathHelper.floor or floorEx
MathHelper.ceil = MathHelper.ceil or ceilEx


-- Inject our QoL functions into the core lua math lib
math = math or {}
math.ceilEx = math.ceilEx or ceilEx
math.floorEx = math.floorEx or floorEx
math.round = math.round or round

-- Inject our QoL functions into the FS MathUtil lib
if MathUtil ~= nil then
    MathUtil.ceilEx = MathUtil.ceilEx or ceilEx
    MathUtil.floorEx = MathUtil.floorEx or floorEx
    MathUtil.round = MathUtil.round or round
    MathUtil.roundEx = MathUtil.roundEx or round
end
