#!/usr/bin/env lua
-- fft.fun: fast-frugal multi-objective tree.
-- (c) 2026, Tim Menzies <timm@ieee.org>, MIT license
--
-- Options:
--   -s seed     seed=1234567891
--   -p p        distance exponent  p=2
--   -b bins     bins=7
--   -d depth    depth=4
--   -R Round    Round=2
--   -f file     file=../optimiz/auto93.csv

local BIG  = 1E32
local L  = require("lib")
local abs, argmin, of, csv, sort  = L.abs, L.argmin, L.of, L.csv, L.sort

local the  = {seed=1234567891, p=2, bins=7, depth=4, Round=2,
        file="../optimiz/auto93.csv"}

-- forward decls (so closures can reference)
local add, adds, disty, distys, qty, grows, show

-- 1. Columns ------------------------------------------------
local Sym  = function() return  {symp=true, has={}} end
local Num  = function(n, mu, m2)
  return  {nump=true, n=n or 0, mu=mu or 0, m2=m2 or 0} end

local sd  = function(num)
  if (num.n < 2) then return  0 end
  return  math.sqrt(math.max(0, num.m2) / (num.n - 1)) end

local welford  = function(num, v, w)
  local n, mu, m2  = num.n, num.mu, num.m2
  n = n + w
  if (n <= 0) then return  Num() end
  local d  = v - mu
  mu = mu + w * d / n
  return  Num(n, mu, m2 + w * d * (v - mu)) end

local norm  = function(num, v)
  local z  = (v - num.mu) / (sd(num) + 1/BIG)
  return  1 / (1 + math.exp(-1.7 * math.max(-3, math.min(3, z)))) end

local merge  = function(i, j, w)
  local w  = w or 1
  if (i.symp) then
    local out  = Sym()
    for _, p in ipairs({{i,1}, {j,w}}) do
      for k, vv in pairs(p[1].has) do
        out.has[k] = (out.has[k] or 0) + p[2] * vv end end
    return  out end
  local n  = i.n + w * j.n
  if (n <= 0) then return  Num() end
  local mu  = (i.n*i.mu + w * j.n * j.mu) / n
  local d   = j.mu - i.mu
  local m2  = i.m2 + w*j.m2 + w*d*d*i.n*j.n / n
  return  Num(n, mu, m2) end

-- 2. Data ---------------------------------------------------
local Data  = function(src)
  local it  = setmetatable({names={}, klass=nil, x={}, y={},
                       goal={}, cols={}, rows={}}, DATA_MT)
  local roles  = function(names)
    it.names = names
    for at, s in ipairs(names) do
      local z  = s:sub(-1)
      local first  = s:sub(1,1)
      if (first == first:lower()) then
        it.cols[at] = Sym()
      else
        it.cols[at] = Num() end
      if (z == "-" or z == "+" or z == "!") then
        table.insert(it.y, at)
        it.goal[at] = (z == "+") and 1 or 0
      elseif (z ~= "X") then table.insert(it.x, at) end
      if (z == "!") then it.klass = at end end end
  roles(src[1])
  for i = 2, #src do it = add(it, src[i]) end
  return  it end

add = function(it, v)
  if (v == "?") then return  it end
  if (it.symp) then
    it.has[v] = (it.has[v] or 0) + 1
  elseif (it.nump) then
    it = welford(it, v, 1)
  else
    table.insert(it.rows, v)
    it.cols = (function() local _r={} for at, x in ipairs(v) do _r[#_r+1]=add(it.cols[at], x) end return _r end)() end
  return  it end

adds = function(src, it)
  local it  = it or Num()
  for _, x in ipairs(src) do it = add(it, x) end
  return  it end

-- 3. Discretization ----------------------------------------
local cutsSyms  = function(bins, tot, hi, at)
  local out  = {}
  for k, l in pairs(bins) do
    local score  = l.m2 + merge(tot, l, -1).m2
    out[#out+1] = {score=score, at=at, lo=hi[k], hi=hi[k], leaf=l} end
  return  out end

local cutsNums  = function(bins, tot, hi, at)
  local out  = {}
  local ks  = sort((function() local _r={} for k, _ in pairs(bins) do _r[#_r+1]=k end return _r end)())
  local l  = Num()
  for j = 1, #ks - 1 do
    local k  = ks[j]
    l = merge(l, bins[k])
    local score  = l.m2 + merge(tot, l, -1).m2
    out[#out+1] = {score=score, at=at, lo=-BIG, hi=hi[k], leaf=l} end
  return  out end

local cuts  = function(data, rows, y)
  local out, ys  = {}, (function() local _r={} for _, r in ipairs(rows) do _r[#_r+1]=y(r) end return _r end)()
  for _, at in ipairs(data.x) do
    local c  = data.cols[at]
    local tot, bins, hi  = Num(), {}, {}
    for i, r in ipairs(rows) do
      local v  = r[at]
      if (v ~= "?") then
        local k  = (c.symp and v)
              or math.floor(the.bins * norm(c, v))
        bins[k] = add(bins[k] or Num(), ys[i])
        tot     = add(tot, ys[i])
        if (c.symp) then
          hi[k] = v
        else
          hi[k] = math.max(hi[k] or -BIG, v) end end end
    local inner  = (c.symp and cutsSyms or cutsNums)(bins, tot, hi, at)
    for _, x in ipairs(inner) do out[#out+1] = x end end
  return  out end

-- 4. Build a tree ------------------------------------------
disty = function(data, row)
  local p, s  = the.p, 0
  for _, at in ipairs(data.y) do
    s = s + abs(norm(data.cols[at], row[at]) - data.goal[at]) ^ p end
  return  (s / #data.y) ^ (1 / p) end

distys = function(data, rows)
  local ys  = (function() local _r={} for _, r in ipairs(rows) do _r[#_r+1]=disty(data, r) end return _r end)()
  return  adds(ys) end

local has  = function(v, lo, hi) return  v == "?" or (lo <= v and v <= hi) end

local rest  = function(rows, at, lo, hi)
  return  (function() local _r={} for _, r in ipairs(rows) do if not has(r[at], lo, hi) then _r[#_r+1]=r end end return _r end)() end

local splits  = function(data, y, root)
  local out  = {}
  local floor  = (#root.rows) ^ 0.33
  local all  = cuts(data, data.rows, y)
  local cs  = (function() local _r={} for _, c in ipairs(all) do if c.leaf.n > floor then _r[#_r+1]=c end end return _r end)()
  if (#cs == 0) then return  out end
  sort(cs, function(a,b) return  a.leaf.mu < b.leaf.mu end)
  for bit, c in ipairs({cs[1], cs[#cs]}) do
    local no  = rest(data.rows, c.at, c.lo, c.hi)
    if (#no > 0) then
      out[#out+1] = {bit=bit-1,
                     nd={at=c.at, lo=c.lo, hi=c.hi, left=c.leaf},
                     no=no} end end
  return  out end

grows = function(data, y, root, d)
  local d  = d or 0
  local out  = {}
  if (d < the.depth) then
    for _, sp in ipairs(splits(data, y, root)) do
      local child  = {data.names}
      for _, r in ipairs(sp.no) do table.insert(child, r) end
      for _, br in ipairs(grows(Data(child), y, root, d+1)) do
        out[#out+1] = {bias=tostring(sp.bit) .. br.bias,
                       tree={at=sp.nd.at, lo=sp.nd.lo,
                             hi=sp.nd.hi, left=sp.nd.left,
                             right=br.tree}} end end end
  if (#out == 0) then
    local ys  = (function() local _r={} for _, r in ipairs(data.rows) do _r[#_r+1]=y(r) end return _r end)()
    out[#out+1] = {bias="", tree=adds(ys)} end
  return  out end

-- 5. Use a tree --------------------------------------------
local predict  = function(t, row)
  while (not t.nump) do
    if (has(row[t.at], t.lo, t.hi)) then
      t = t.left
    else
      t = t.right end end
  return  t.mu end

local tune  = function(cands, rows, y)
  local err  = function(t)
    local e  = 0
    for _, r in ipairs(rows) do
      e = e + abs(y(r) - predict(t, r)) end
    return  e / #rows end
  return  argmin(cands, err) end

show = function(data, t)
  if (t.nump) then
    print(("%-33s leaf  d2h %.2f n=%d"):fmt("", t.mu, t.n))
    return  nil end
  local nm  = data.names[t.at]
  local c  = ""
  if (t.lo == t.hi) then
    c = ("%s == %s"):fmt(nm, tostring(t.lo))
  elseif (t.lo == -BIG) then
    c = ("%s <= %s"):fmt(nm, tostring(qty(t.hi)))
  else
    c = ("%s >= %s"):fmt(nm, tostring(qty(t.lo))) end
  local lf  = t.left
  print(("if %-30s then d2h %.2f n=%d"):fmt(c, lf.mu, lf.n))
  show(data, t.right) end

-- 6. IO ----------------------------------------------------
qty = function(v)
  if (type(v) == "number") then
    if (math.floor(v) == v) then return  math.floor(v) end
    return  tonumber(("%."..the.Round.."f"):fmt(v)) end
  return  v end

-- 7. Tests/demos -------------------------------------------
local test_main  = function()
  local data  = Data(csv(the.file))
  local y     = function(r) return  disty(data, r) end
  local cands  = {}
  for _, b in ipairs(grows(data, y, data)) do
    table.insert(cands, b.tree) end
  show(data, tune(cands, data.rows, y)) end

local test_trees  = function()
  local data   = Data(csv(the.file))
  local y      = function(r) return  disty(data, r) end
  local trees  = grows(data, y, data)
  for i, bt in ipairs(trees) do
    local bias, t  = bt.bias, bt.tree
    local e  = 0
    for _, r in ipairs(data.rows) do
      e = e + abs(y(r) - predict(t, r)) end
    e = e / #data.rows
    print(("===== tree %2d   bias %-5s   err %.3f ====="):fmt(
      i, bias, e))
    show(data, t)
    print() end end

-- 8. Start-up ----------------------------------------------
for i = 1, #arg - 1 do
  for k, _ in pairs(the) do
    if (arg[i] == "-" .. k:sub(1,1)) then
      the[k] = of(arg[i+1]) end end end

math.randomseed(the.seed)

local mode  = "main"
for _, a in ipairs(arg) do
  if (a == "--trees") then mode = "trees" end end
if (mode == "trees") then
  test_trees()
else
  test_main() end
