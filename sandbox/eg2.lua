-- eg2.luk : luk2 smoke test. Every feature once.
local n = 0
local ok = function(test, msg)
  n = n + 1
  if test then print("ok  " .. n .. " " .. msg)
  else print("FAIL" .. n .. " " .. msg) os.exit(1) end
end

-- := local
local x, y = 10, 20
ok(x == 10 and y == 20, ":= multi")

-- fn + ^ one-liner body (return after param list)
local double = function(z) return z * 2 end
ok(double(21) == 42, "fn / ^ after params")

-- ^ at line start
local triple = function(z)
  return z * 3
end
ok(triple(5) == 15, "^ line start")

-- ^ after then / else
local pick = function(b) if b then return "yes" else return "no" end end
ok(pick(true) == "yes" and pick(false) == "no", "^ then/else")

-- ^ after ;
local bump = function() local q = 1; return q + 1 end
ok(bump() == 2, "^ after ;")

-- infix exponent untouched
ok(2^10 == 1024 and (2+1)^2 == 9, "a^b exponent survives")

-- != is ~=
ok(1 ~= 2, "!= not-equal")

-- strings untouched
local msg = "fn ^ := [a for b in c] != all safe here"
ok(#msg == 39, "sigils hidden in strings")

-- long string, multi-line, sigils at line start inside
local raw = [[
^ fn :=
]]
ok(raw:find("fn :=", 1, true) ~= nil, "long string untouched")

-- plain tables + indexing pass through
local t = {10, 20, 30}
ok(t[2] == 20, "table / index pass-through")

-- list comprehension
local sq = (function() local _r={} for _,v in ipairs(t) do _r[#_r+1]=v * v end return _r end)()
ok(sq[3] == 900, "list comp")

-- list comp + if
local big = (function() local _r={} for _,v in ipairs(t) do if v > 15 then _r[#_r+1]=v end end return _r end)()
ok(#big == 2 and big[1] == 20, "list comp if")

-- multi-line list comp
local longer = (function() local _r={} for _,v in ipairs(t
          ) do if v > 10 then _r[#_r+1]=v + 1
           end end return _r end)()
ok(#longer == 2 and longer[2] == 31, "multi-line comp")

-- dict comprehension
local inv = (function() local _r={} for k, v in pairs(t) do _r[v]= k end return _r end)()
ok(inv[30] == 3, "dict comp")

-- dict comp + if
local some = (function() local _r={} for k, v in pairs(t) do if v ~= 20 then _r[k]= v * 2 end end return _r end)()
ok(some[1] == 20 and some[2] == nil and some[3] == 60, "dict comp if")

print("all pass")
