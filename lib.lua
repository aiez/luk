-- vim: ft=lua ts=2 sw=2 sts=2 et :
-- lib.luk: Lua 1 for .luk programs. End syntax.
-- usage:  L := require(2)
--         abs, argmin = L.abs, L.argmin   -- or use L.abs

-- adds :fmt(...) method to all strings (string.format)
getmetatable("").__index.fmt = string.format

local abs, max, min = math.abs, math.max, math.min
local sqrt, exp, floor = math.sqrt, math.exp, math.floor

local sort = function(t, f) table.sort(t, f); return t end

local of = function(z) return z=="True" or z~="False" and (tonumber(z) or z) end

local sum = function(xs)
  local s = 0
  for _, x in ipairs(xs) do s = s + x end
  return s end

local argmin = function(xs, key)
  local best, bv = xs[1], key(xs[1])
  for i = 2, #xs do
    local v = key(xs[i])
    if v < bv then best, bv = xs[i], v end end
  return best end

local csv = function(file)
  local u = {}
  for ln in io.lines(file) do
    local ln = ln:gsub("^%s+", ""):gsub("%s+$", "")
    if #ln > 0 and ln:sub(1,1) ~= "#" then
      local row = {}
      for x in ln:gmatch("[^,]+") do row[#row+1] = of(x) end
      u[#u+1] = row end end
  return u end

return {abs=abs, max=max, min=min, sqrt=sqrt, exp=exp,
   floor=floor, argmin=argmin, sum=sum, sort=sort,
   of=of, csv=csv}
