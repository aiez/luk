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

-- 1. fn / let / ^ ------------------------------------------------------
CHECK("fn-let-return", [=[
let add = fn(a, b) @a + b end
@add(2, 3)]=], 5)

CHECK("named-fn", [=[
fn double(x) @x * 2 end
@double(21)]=], 42)

CHECK("let-forward-decl", [=[
let f
f = fn(n) if n < 2 then @1 end
  @n * f(n - 1) end
@f(4)]=], 24)

CHECK("let-multi", [=[
let a, b = 2, 3
@a * b]=], 6)

CHECK("return-after-then-else", [=[
let pick = fn(b) if b then @"yes" else @"no" end end
@pick(true)]=], "yes")

CHECK("return-after-do", [=[
let f = fn() for _ = 1, 1 do @7 end end
@f()]=], 7)

CHECK("return-after-semicolon", [=[
let f = fn(x) let y = x * 2; @y end
@f(4)]=], 8)

CHECK("return-multiline-block", [=[
let mul = fn(a)
  let b = a * 2
  @b end
@mul(7)]=], 14)

-- 2. elif / infix ^ ---------------------------------------------------
CHECK("elif-chain", [=[
fn sign(x)
  if x > 0 then @1
  elif x < 0 then @-1
  else @0 end end
@sign(-5)]=], -1)

CHECK("infix-caret", [=[
fn f(x) @x ^ 2 end
@f(3)]=], 9.0)

-- 3. anon fns ----------------------------------------------------------
CHECK("anon-in-call", [=[
let t = {3, 1, 2}
table.sort(t, fn(a, b) @a > b end)
@t[1] ]=], 3)

CHECK("anon-comma-separated", [=[
let fs = {fn(x) @x + 1 end, fn(x) @x * 10 end}
@fs[1](1) + fs[2](2)]=], 22)

CHECK("anon-nested", [=[
let nth = fn(n) @fn(t) @t[n] end end
@nth(2)({4, 5, 6})]=], 5)

CHECK("anon-multiline", [=[
let sorter = fn(a, b)
  if a == b then @false end
  @a < b end
@sorter(1, 2)]=], true)

-- 4. comprehensions ----------------------------------------------------
CHECK("comprehension-filtered", [=[
fn evens(t) @[x for x in t if x % 2 == 0] end
@#evens({1, 2, 3, 4, 6})]=], 3)

CHECK("comprehension-multiline", [=[
let u = [x * 10 for _, x in ipairs({1, 2,
                                 3})]
@u[3] ]=], 30)

CHECK("dict-comprehension", [=[
let d = {v, k for k, v in {a = 1}}
@d[1] ]=], "a")

-- 5. comments, strings, misc sigils ------------------------------------
CHECK("trailing-comments", [=[
fn f()  -- make f
  @1    -- one
end
-- done
@f()]=], 1)

CHECK("string-in-comment", [=[
-- keeps require"x" intact
@1]=], 1)

CHECK("string-colon-space", [=[
let s = "a: b"
@s]=], "a: b")

CHECK("method-colon-untouched", [=[
@("%s!"):format("hi")]=], "hi!")

CHECK("label-untouched", [=[
let x = 0
::top::
x = x + 1
if x < 3 then goto top end
@x]=], 3)

-- 6. error line numbers ------------------------------------------------
CHECKERR("errline-flat", [=[
let x = 1

error("boom")]=], 3)

CHECKERR("errline-in-fn", [=[
fn f()
  if 1 > 0 then
    error("bam") end end
f()]=], 3)

print(("%d/%d pass"):format(n - fails, n))
os.exit(fails == 0 and 0 or 1)
