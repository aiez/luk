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

BIG := 1E32
L := require("lib")
abs, argmin, of, csv, sort := L.abs, L.argmin, L.of, L.csv, L.sort

the := {seed=1234567891, p=2, bins=7, depth=4, Round=2,
        file="../optimiz/auto93.csv"}

-- forward decls (so closures can reference)
local add, adds, disty, distys, qty, grows, show

-- 1. Columns ------------------------------------------------
Sym := fun(): ! {symp=true, has={}}
Num := fun(n, mu, m2):
  ! {nump=true, n=n or 0, mu=mu or 0, m2=m2 or 0}

sd := fun(num):
  if (num.n < 2): ! 0
  ! math.sqrt(math.max(0, num.m2) / (num.n - 1))

welford := fun(num, v, w):
  n, mu, m2 := num.n, num.mu, num.m2
  n += w
  if (n <= 0): ! Num()
  d := v - mu
  mu += w * d / n
  ! Num(n, mu, m2 + w * d * (v - mu))

norm := fun(num, v):
  z := (v - num.mu) / (sd(num) + 1/BIG)
  ! 1 / (1 + math.exp(-1.7 * math.max(-3, math.min(3, z))))

merge := fun(i, j, w):
  w := w or 1
  if (i.symp):
    out := Sym()
    for _, p in ipairs({{i,1}, {j,w}}):
      for k, vv in pairs(p[1].has):
        out.has[k] = (out.has[k] or 0) + p[2] * vv
    ! out
  n := i.n + w * j.n
  if (n <= 0): ! Num()
  mu := (i.n*i.mu + w * j.n * j.mu) / n
  d  := j.mu - i.mu
  m2 := i.m2 + w*j.m2 + w*d*d*i.n*j.n / n
  ! Num(n, mu, m2)

-- 2. Data ---------------------------------------------------
Data := fun(src):
  it := setmetatable({names={}, klass=nil, x={}, y={},
                       goal={}, cols={}, rows={}}, DATA_MT)
  roles := fun(names):
    it.names = names
    for at, s in ipairs(names):
      z := s:sub(-1)
      first := s:sub(1,1)
      if (first == first:lower()):
        it.cols[at] = Sym()
      else:
        it.cols[at] = Num()
      if (z == "-" or z == "+" or z == "!"):
        table.insert(it.y, at)
        it.goal[at] = (z == "+") and 1 or 0
      elseif (z ~= "X"): table.insert(it.x, at)
      if (z == "!"): it.klass = at
  roles(src[1])
  for i = 2, #src: it = add(it, src[i])
  ! it

add = fun(it, v):
  if (v == "?"): ! it
  if (it.symp):
    it.has[v] = (it.has[v] or 0) + 1
  elseif (it.nump):
    it = welford(it, v, 1)
  else:
    table.insert(it.rows, v)
    it.cols = [add(it.cols[at], x) for at, x in ipairs(v)]
  ! it

adds = fun(src, it):
  it := it or Num()
  for _, x in ipairs(src): it = add(it, x)
  ! it

-- 3. Discretization ----------------------------------------
cutsSyms := fun(bins, tot, hi, at):
  out := {}
  for k, l in pairs(bins):
    score := l.m2 + merge(tot, l, -1).m2
    out[#out+1] = {score=score, at=at, lo=hi[k], hi=hi[k], leaf=l}
  ! out

cutsNums := fun(bins, tot, hi, at):
  out := {}
  ks := sort([k for k, _ in pairs(bins)])
  l := Num()
  for j = 1, #ks - 1:
    k := ks[j]
    l = merge(l, bins[k])
    score := l.m2 + merge(tot, l, -1).m2
    out[#out+1] = {score=score, at=at, lo=-BIG, hi=hi[k], leaf=l}
  ! out

cuts := fun(data, rows, y):
  out, ys := {}, [y(r) for _, r in ipairs(rows)]
  for _, at in ipairs(data.x):
    c := data.cols[at]
    tot, bins, hi := Num(), {}, {}
    for i, r in ipairs(rows):
      v := r[at]
      if (v ~= "?"):
        k := (c.symp and v)
              or math.floor(the.bins * norm(c, v))
        bins[k] = add(bins[k] or Num(), ys[i])
        tot     = add(tot, ys[i])
        if (c.symp):
          hi[k] = v
        else:
          hi[k] = math.max(hi[k] or -BIG, v)
    inner := (c.symp and cutsSyms or cutsNums)(bins, tot, hi, at)
    for _, x in ipairs(inner): out[#out+1] = x
  ! out

-- 4. Build a tree ------------------------------------------
disty = fun(data, row):
  p, s := the.p, 0
  for _, at in ipairs(data.y):
    s += abs(norm(data.cols[at], row[at]) - data.goal[at]) ^ p
  ! (s / #data.y) ^ (1 / p)

distys = fun(data, rows):
  ys := [disty(data, r) for _, r in ipairs(rows)]
  ! adds(ys)

has := fun(v, lo, hi): ! v == "?" or (lo <= v and v <= hi)

rest := fun(rows, at, lo, hi):
  ! [r for _, r in ipairs(rows) if not has(r[at], lo, hi)]

splits := fun(data, y, root):
  out := {}
  floor := (#root.rows) ^ 0.33
  all := cuts(data, data.rows, y)
  cs := [c for _, c in ipairs(all) if c.leaf.n > floor]
  if (#cs == 0): ! out
  sort(cs, fun(a,b): ! a.leaf.mu < b.leaf.mu end)
  for bit, c in ipairs({cs[1], cs[#cs]}):
    no := rest(data.rows, c.at, c.lo, c.hi)
    if (#no > 0):
      out[#out+1] = {bit=bit-1,
                     nd={at=c.at, lo=c.lo, hi=c.hi, left=c.leaf},
                     no=no}
  ! out

grows = fun(data, y, root, d):
  d := d or 0
  out := {}
  if (d < the.depth):
    for _, sp in ipairs(splits(data, y, root)):
      child := {data.names}
      for _, r in ipairs(sp.no): table.insert(child, r)
      for _, br in ipairs(grows(Data(child), y, root, d+1)):
        out[#out+1] = {bias=tostring(sp.bit) .. br.bias,
                       tree={at=sp.nd.at, lo=sp.nd.lo,
                             hi=sp.nd.hi, left=sp.nd.left,
                             right=br.tree}}
  if (#out == 0):
    ys := [y(r) for _, r in ipairs(data.rows)]
    out[#out+1] = {bias="", tree=adds(ys)}
  ! out

-- 5. Use a tree --------------------------------------------
predict := fun(t, row):
  while (not t.nump):
    if (has(row[t.at], t.lo, t.hi)):
      t = t.left
    else:
      t = t.right
  ! t.mu

tune := fun(cands, rows, y):
  err := fun(t):
    e := 0
    for _, r in ipairs(rows):
      e += abs(y(r) - predict(t, r))
    ! e / #rows
  ! argmin(cands, err)

show = fun(data, t):
  if (t.nump):
    print(("%-33s leaf  d2h %.2f n=%d"):fmt("", t.mu, t.n))
    ! nil
  nm := data.names[t.at]
  c := ""
  if (t.lo == t.hi):
    c = ("%s == %s"):fmt(nm, tostring(t.lo))
  elseif (t.lo == -BIG):
    c = ("%s <= %s"):fmt(nm, tostring(qty(t.hi)))
  else:
    c = ("%s >= %s"):fmt(nm, tostring(qty(t.lo)))
  lf := t.left
  print(("if %-30s then d2h %.2f n=%d"):fmt(c, lf.mu, lf.n))
  show(data, t.right)

-- 6. IO ----------------------------------------------------
qty = fun(v):
  if (type(v) == "number"):
    if (math.floor(v) == v): ! math.floor(v)
    ! tonumber(("%."..the.Round.."f"):fmt(v))
  ! v

-- 7. Tests/demos -------------------------------------------
test_main := fun():
  data := Data(csv(the.file))
  y    := fun(r): ! disty(data, r) end
  cands := {}
  for _, b in ipairs(grows(data, y, data)):
    table.insert(cands, b.tree)
  show(data, tune(cands, data.rows, y))

test_trees := fun():
  data  := Data(csv(the.file))
  y     := fun(r): ! disty(data, r) end
  trees := grows(data, y, data)
  for i, bt in ipairs(trees):
    bias, t := bt.bias, bt.tree
    e := 0
    for _, r in ipairs(data.rows):
      e += abs(y(r) - predict(t, r))
    e = e / #data.rows
    print(("===== tree %2d   bias %-5s   err %.3f ====="):fmt(
      i, bias, e))
    show(data, t)
    print()

-- 8. Start-up ----------------------------------------------
for i = 1, #arg - 1:
  for k, _ in pairs(the):
    if (arg[i] == "-" .. k:sub(1,1)):
      the[k] = of(arg[i+1])

math.randomseed(the.seed)

mode := "main"
for _, a in ipairs(arg):
  if (a == "--trees"): mode = "trees"
if (mode == "trees"):
  test_trees()
else:
  test_main()
