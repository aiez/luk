-- lib.luk: Lua "battery" for .luk programs.
-- usage:  L := require("lib")
--         abs, argmin = L.abs, L.argmin   -- or use L.abs etc.

-- adds :fmt(...) method to all strings (alias for string.format)
getmetatable("").__index.fmt = string.format

local abs  = math.abs
local max  = math.max
local min  = math.min
local sqrt  = math.sqrt
local exp  = math.exp
local floor  = math.floor

local sum   -- forward: mean uses sum

local sort  = function(t, f) table.sort(t, f); return t end

local of  = function(z) return z=="True" or z~="False" and (tonumber(z) or z) end

local keys  = function(t) return sort((function() local _r={} for k, _ in pairs(t) do _r[#_r+1]=k end return _r end)()) end

local mean  = function(xs) return sum(xs) / #xs end

sum = function(xs)
  local s  = 0
  for _, x in ipairs(xs) do
    s = s + x end
  return s end

local argmin  = function(xs, key, cmp)
  cmp = cmp or function(a,b) return a<b end
  local best  = xs[1]
  local bv  = key(best)
  for i = 2, #xs do
    local v  = key(xs[i])
    if (cmp(v, bv)) then best, bv = xs[i], v end end
  return best end

local argmax  = function(xs, key)
  return argmin(xs, key, function(a,b) return a>b end) end

local csv  = function(file)
  local out  = {}
  for ln in io.lines(file) do
    local ln  = ln:gsub("^%s+", ""):gsub("%s+$", "")
    if (#ln > 0 and ln:sub(1,1) ~= "#") then
      local row  = {}
      for x in ln:gmatch("[^,]+") do row[#row+1] = of(x) end
      out[#out+1] = row end end
  return out end

return {abs=abs, max=max, min=min, sqrt=sqrt, exp=exp, floor=floor,
   argmin=argmin, argmax=argmax, sum=sum, mean=mean,
   sort=sort, keys=keys, of=of, csv=csv}
