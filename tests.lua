-- tests.lua : luk transpiler regression tests.   usage: lua tests.lua
-- Each CHECK transpiles a snippet, asserts (a) transpiled line count ==
-- source line count (real error lines), (b) running it yields `want`.
package.path = "./?.lua;" .. package.path
local transpile = require"luk"

local n, fails = 0, 0

local function report(name, lua, got, want)
  fails = fails + 1
  print(("FAIL %s: got %s want %s"):format(name, tostring(got),
                                           tostring(want)))
  print("---- generated ----\n" .. lua .. "\n-------------------") end

local function CHECK(name, src, want)
  n = n + 1
  local ok, lua = pcall(transpile, src)
  if not ok then return report(name, "(transpile error)", lua, want) end
  local _, a = src:gsub("\n", "")
  local _, b = lua:gsub("\n", "")
  if a ~= b then
    return report(name, lua, ("lines %d -> %d"):format(a, b), want) end
  local f, err = load(lua, name)
  if not f then return report(name, lua, err, want) end
  local ok2, got = pcall(f)
  if not ok2 or got ~= want then return report(name, lua, got, want) end end

local function CHECKERR(name, src, line)  -- runtime error on given line
  n = n + 1
  local lua = transpile(src)
  local f, err = load(lua, name)
  if not f then return report(name, lua, err, "line " .. line) end
  local ok, msg = pcall(f)
  if ok or not msg:find(":" .. line .. ":") then
    return report(name, lua, msg, "error at line " .. line) end end

-- 1. old end-syntax still valid --------------------------------------
CHECK("old-fn", [=[
add := fn(a, b) ^ a + b end
^ add(2, 3)]=], 5)

CHECK("old-if", [=[
pick := fn(b) if b then ^ "yes" else ^ "no" end end
^ pick(true)]=], "yes")

-- 2. colon blocks -----------------------------------------------------
CHECK("block-if-elif-else", [=[
fn sign(x):
  if x > 0:
    ^ 1
  elif x < 0:
    ^ -1
  else:
    ^ 0
^ sign(-5)]=], -1)

CHECK("block-while", [=[
fn count(k):
  i := 0
  while i < k:
    i = i + 1
  ^ i
^ count(7)]=], 7)

CHECK("block-for", [=[
fn total(t):
  s := 0
  for _, x in ipairs(t):
    s = s + x
  ^ s
^ total({1, 2, 3})]=], 6)

CHECK("block-assigned-anon", [=[
mul := fn(a):
  b := a * 2
  ^ b
^ mul(7)]=], 14)

CHECK("block-nested-dedent", [=[
fn f(n):
  if n > 0:
    if n > 1:
      ^ 2
    ^ 1
  ^ 0
^ f(2) * 100 + f(1) * 10 + f(0)]=], 210)

CHECK("block-do", [=[
x := 1
do:
  x = 2
^ x]=], 2)

-- 3. one-liners --------------------------------------------------------
CHECK("oneliner-if", [=[
fn f(x):
  if x > 0: ^ "pos"
  ^ "neg"
^ f(1) .. f(-1)]=], "posneg")

CHECK("oneliner-chain", [=[
fn clamp(x, lo, hi):
  if x < lo: ^ lo
  elif x > hi: ^ hi
  ^ x
^ clamp(5, 1, 4) + clamp(0, 1, 4) + clamp(2, 1, 4)]=], 7)

CHECK("oneliner-else", [=[
fn f(x):
  if x: ^ 1
  else: ^ 2
^ f(nil)]=], 2)

CHECK("oneliner-while", [=[
i := 0
while i < 5: i = i + 1
^ i]=], 5)

CHECK("oneliner-for", [=[
s := 0
for i = 1, 4: s = s + i
^ s]=], 10)

CHECK("oneliner-named-fn", [=[
fn double(x): ^ x * 2
^ double(21)]=], 42)

CHECK("oneliner-assigned-fn", [=[
triple := fn(x): ^ x * 3
^ triple(5)]=], 15)

-- 4. anon fn mid-expression --------------------------------------------
CHECK("anon-in-call", [=[
t := {3, 1, 2}
table.sort(t, fn(a, b): ^ a > b)
^ t[1] ]=], 3)

CHECK("anon-comma-separated", [=[
fs := {fn(x): ^ x + 1, fn(x): ^ x * 10}
^ fs[1](1) + fs[2](2)]=], 22)

CHECK("anon-multiline-block", [=[
sorter := fn(a, b):
  if a == b: ^ false
  ^ a < b
^ sorter(1, 2)]=], true)

CHECK("anon-nested-oneliner", [=[
nth := fn(n): ^ fn(t): ^ t[n]
^ nth(2)({4, 5, 6})]=], 5)

-- 5. comprehensions unchanged ------------------------------------------
CHECK("comprehension-in-block", [=[
fn evens(t):
  ^ [x for x in t if x % 2 == 0]
^ #evens({1, 2, 3, 4, 6})]=], 3)

CHECK("comprehension-multiline", [=[
u := [x * 10 for _, x in ipairs({1, 2,
                                 3})]
^ u[3] ]=], 30)

CHECK("dict-comprehension", [=[
d := {v, k for k, v in {a = 1}}
^ d[1] ]=], "a")

-- 6. comments, strings, misc sigils --------------------------------------
CHECK("trailing-comments", [=[
fn f():  -- make f
  ^ 1    -- one
-- done
^ f()]=], 1)

CHECK("string-colon-space", [=[
s := "a: b"
^ s]=], "a: b")

CHECK("method-colon-untouched", [=[
^ ("%s!"):format("hi")]=], "hi!")

CHECK("label-untouched", [=[
x := 0
::top::
x = x + 1
if x < 3 then goto top end
^ x]=], 3)

CHECK("not-equal", [=[
^ 1 != 2]=], true)

CHECK("infix-caret", [=[
fn f(x):
  ^ x ^ 2
^ f(3)]=], 9.0)

-- 7. error line numbers --------------------------------------------------
CHECKERR("errline-flat", [=[
x := 1

error("boom")]=], 3)

CHECKERR("errline-in-block", [=[
fn f():
  if 1 > 0:
    error("bam")
f()]=], 3)

print(("%d/%d pass"):format(n - fails, n))
os.exit(fails == 0 and 0 or 1)
