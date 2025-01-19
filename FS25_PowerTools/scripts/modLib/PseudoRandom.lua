--[[

   Pseudo-random number generator
   Produces identical sequences of pseudo-random numbers across all platforms and versions of Lua: 5.1, 5.2, 5.3, 5.4, LuaJIT

   Functions:
      random()         -- standard Lua function was redefined with cross-platform implementation
      randomseed()     -- standard Lua function was redefined with cross-platform implementation
      getrandomseed()  -- new function, it returns the current position of the PRN sequence to be able to continue its generation later

   Internal state (seed): 53 bits, can be read or modified at any time

   Good statistical properties of PRN sequence:
      uniformity
      long period of 255 * 2^45 (approximately 2^53)
      unpredictability (probably better than xoshiro)

   Non-standard Lua forks having 32-bit "float" Lua numbers (instead of 64-bit "double") are not supported

   Code was posted as an example on StackOverflow and is modified to suit my FS implementation. Original post can be found here: https://stackoverflow.com/a/71993215. Alternate implementation can be found here: https://gist.github.com/Egor-Skriptunoff/375ffe05075063c9a2ce61bb30b1ce50 (same author as the post in StackOveflow).

]]--

assert(Log ~= nil, "Log library dependency is not loaded, please ensure LogHelper.lua is properly included (see https://github.com/w33zl/FS22_WeezlsModLib for details)")

PseudoRandom = {}
local PseudoRandom_mt = Class(PseudoRandom)

--- Create new pseudo-random number generator that will produce identical sequences of pseudo-random numbers across all platforms and versions of Lua: 5.1, 5.2, 5.3, 5.4, LuaJIT.
--- Use optional parameters key6, key7 and key44 to ensure that the PRN sequence is both unqiue and reproducible between different classes and methods, e.g. use unqiue static (hard coded) keys for different mods/classes.
---@param key6 number "6-bit  arbitrary integer (0..63)"
---@param key7 number "7-bit  arbitrary integer (0..127)"
---@param key44 number "44-bit arbitrary integer (0..17592186044415)"
---@return table "A new pseudo-random object with methods .random(), .randomseed() and .getrandomseed()"
function PseudoRandom.new(key6, key7, key44)
   -- all parameters in PRNG formula are derived from these 57 secret bits:
   local secret_key_6  = 59            -- 6-bit  arbitrary integer (0..63)
   local secret_key_7  = 115           -- 7-bit  arbitrary integer (0..127)
   local secret_key_44 = 3580861008713 -- 44-bit arbitrary integer (0..17592186044415)

   local temp_secret_key_6 = key6 or secret_key_6
   local temp_secret_key_7 = key7 or secret_key_7
   local temp_secret_key_44 = key44 or secret_key_44

   secret_key_6 = math.max(0, math.min(63, temp_secret_key_6))
   secret_key_7 = math.max(0, math.min(127, temp_secret_key_7))
   secret_key_44 = math.max(0, math.min(17592186044415, temp_secret_key_44))

   if secret_key_6 ~= temp_secret_key_6 then
      Log:warning("Key6 value (%d) is out of range (0..63), clamped to %d", temp_secret_key_6, secret_key_6)
   end

   if secret_key_7 ~= temp_secret_key_7 then
      Log:warning("Key7 value (%d) is out of range (0..127), clamped to %d", temp_secret_key_7, secret_key_7)
   end

   if secret_key_44 ~= temp_secret_key_44 then
      Log:warning("Key44 value (%d) is out of range (0..17592186044415), clamped to %d", temp_secret_key_44, secret_key_44)
   end



   local newPseudoRandomizer = setmetatable({}, PseudoRandom_mt)

   local function primitive_root_257(idx)
      -- returns primitive root modulo 257 (one of 128 existing roots, idx = 0..127)
      local g, m, d = 1, 128, 2 * idx + 1
      repeat
         g, m, d = g * g * (d >= m and 3 or 1) % 257, m / 2, d % m
      until m < 1
      return g
   end

   local param_mul_8 = primitive_root_257(secret_key_7)
   local param_mul_45 = secret_key_6 * 4 + 1
   local param_add_45 = secret_key_44 * 2 + 1

   -- state of PRNG (53 bits in total)
   local state_45 = 0 -- 0..(2^45-1)
   local state_8 = 2  -- 2..256

   local function get_random_uint32()
      -- returns pseudo-random 32-bit integer 0..4294967295

      -- A linear congruental generator with period of 2^45
      state_45 = (state_45 * param_mul_45 + param_add_45) % 2^45

      -- Lehmer RNG having period of 256
      repeat
         state_8 = state_8 * param_mul_8 % 257
      until state_8 ~= 1  -- skip one value to reduce period from 256 to 255 (we need it to be coprime with 2^45)

      -- Idea taken from PCG: shift and rotate "state_45" by varying number of bits to get 32-bit result
      local r = state_8 % 32
      local n = state_45 / 2^(13 - (state_8 - r) / 32)
      n = (n - n % 1) % 2^32 / 2^r
      r = n % 1
      return r * 2^32 + (n - r)
   end

   local address = tonumber(tostring{}:match"%x%x%x+", 16)

   newPseudoRandomizer.randomseed = function(self, seed1, seed2)
      if type(self) ~= "table" then
         -- assert(type(self) == "number", "bad argument #1 to 'PseudoRandom.random' (number expected, got "..type(self)..")")
         seed2 = tonumber(seed1)
         seed1 = tonumber(self)
      end


      -- arguments may be integers or floating point numbers
      -- without arguments: set initial seed to os.time()
      if not (seed1 or seed2) then
         seed1, seed2 = getTime(), address
      end
      local seed = (seed1 or 0) + (seed2 or 0)
      local lo = seed % 1 * 2^53
      local mi = seed % 9007199254740992  -- 2^53
      local hi = (seed - mi) / 2^53
      seed = (lo + mi + hi) % 2^53
      seed = seed - seed % 1
      state_45 = seed % 2^45
      state_8 = (seed - state_45) / 2^45 % 255 + 2
      return seed
   end

   newPseudoRandomizer.getrandomseed = function()
      -- returns current seed as 53-bit integer
      -- you can pass this number later to PseudoRandom.randomseed to continue the sequence
      return (state_8 - 2) * 2^45 + state_45
   end

   local two32 = 65536 * 65536  -- 2^32
   local Lua_has_integers = two32 * two32 == 0
   local Lua_has_int64 = Lua_has_integers and two32 ~= 0
   local math_floor = math.floor

   local function get_random_full_int()
      local hi22 = math_floor(get_random_uint32() / 2^10)
      local mi21 = math_floor(get_random_uint32() / 2^11)
      local lo21 = math_floor(get_random_uint32() / 2^11)
      local two21 = 2097152  -- 2^21
      return (hi22 * two21 + mi21) * two21 + lo21
   end

   local function get_random_float()
      local hi21 = get_random_uint32() / 2^21 % 1
      local lo32 = get_random_uint32() / 2^53
      return hi21 + lo32
   end

   newPseudoRandomizer.random = function(self, m, n)
      -- .random(self=1, m=2, n=nil)    :random(m=1, n=2)
      -- If self is not a table, we assume dot notation was used and we should shelf m>self and n>m, and we should also ensure self is then actually a number
      if type(self) ~= "table" then
         -- assert(type(self) == "number", "bad argument #1 to 'PseudoRandom.random' (number expected, got "..type(self)..")")
         n = tonumber(m)
         m = tonumber(self)
      end

      -- print(tonumber(nil))
      -- print(tonumber("fgafsf"))
      -- print(tonumber("144241"))
      -- print(tonumber(1))


      if not m then
         -- returns pseudo-random 53-bit floating point number 0 <= x < 1
         return get_random_float()
      elseif m == 0 and not n and Lua_has_integers then
         -- returns an integer with all bits pseudo-random
         return get_random_full_int()
      end
      if not n then
         m, n = 1, m
      end
      -- returns pseudo-random integer in the range m..n
      m, n = m - m % 1, n - n % 1
      if n < m then
         error("Invalid arguments for function 'PseudoRandom.random()'"..": interval is empty", 2)
      elseif m >= -2^53 and n <= 2^53 and m + 2^52 > n - 2^52 then
         return math_floor(m + get_random_float() * 2^53 % (0.0 + n - m + 1))
      elseif m >= -2^63 and n < 2^63 and Lua_has_int64 then
         m, n = math_floor(m), math_floor(n)
         local k = n - m + 1
         if k > 0 then
            return m + get_random_full_int() % k
         end
      end
      error("Invalid arguments for function 'PseudoRandom.random()'", 2)
   end

   -- set initial random seed
   newPseudoRandomizer.randomseed()  -- PseudoRandom.randomseed() without arguments derives seed from os.time()

   return newPseudoRandomizer

end

