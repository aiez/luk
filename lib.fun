-- lib.fun: Lua "battery" for .fun programs.
-- usage:  L := require("lib")
--         abs, argmin = L.abs, L.argmin   -- or use L.abs etc.

-- adds :fmt(...) method to all strings (alias for string.format)
getmetatable("").__index.fmt = string.format

abs := math.abs
max := math.max
min := math.min
sqrt := math.sqrt
exp := math.exp
floor := math.floor

argmin := fun(xs, key):
  best := xs[1]
  bv := key(best)
  for i = 2, #xs:
    v := key(xs[i])
    if (v < bv): best, bv = xs[i], v
  ! best

argmax := fun(xs, key):
  best := xs[1]
  bv := key(best)
  for i = 2, #xs:
    v := key(xs[i])
    if (v > bv): best, bv = xs[i], v
  ! best

sum := fun(xs):
  s := 0
  for _, x in ipairs(xs):
    s += x
  ! s

mean := fun(xs): ! sum(xs) / #xs

sort := fun(t, f): table.sort(t, f); ! t

keys := fun(t): ! sort([k for k, _ in pairs(t)])

of := fun(z): ! z=="True" or z~="False" and (tonumber(z) or z)

csv := fun(file):
  out := {}
  for ln in io.lines(file):
    ln := ln:gsub("^%s+", ""):gsub("%s+$", "")
    if (#ln > 0 and ln:sub(1,1) ~= "#"):
      row := {}
      for x in ln:gmatch("[^,]+"): row[#row+1] = of(x)
      out[#out+1] = row
  ! out

! {abs=abs, max=max, min=min, sqrt=sqrt, exp=exp, floor=floor,
   argmin=argmin, argmax=argmax, sum=sum, mean=mean,
   sort=sort, keys=keys, of=of, csv=csv}
