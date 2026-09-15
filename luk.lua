-- luk.lua : whole-source ".luk" -> Lua transpiler. Pure function,
-- no side effects, no IO:
--   local luk = require"luk"
--   local f   = assert(load(luk(src), "@foo.luk"))  -- real err lines
-- The require() hook for .luk modules lives in the "luk" runner.
-- Lua plus five sigils, all pure same-line rewrites:
--   fn=function  elif=elseif  @=return  let NAME=V  comprehensions.
-- Blocks are Lua's own (then/do/end), so every source line maps 1:1
-- onto the generated Lua and error lines always match. "@" is a
-- character Lua never uses, so return needs no context: one rule,
-- and "a ^ b" stays exponentiation.
-- Full guide + gotchas: README "LANGUAGE REFERENCE".

-- PUT is a statement ("_r[#_r+1]=E", "_r[K]=E"), not the element
-- expression E. IFF/FI are the optional "if C then" ... "end".
local function comprehension(put,v,it,c)
  if not v:find"," and not it:find"%(" then
    v,it = "_,"..v, "ipairs("..it..")"
  elseif not it:find"%(" then it = "pairs("..it..")" end
  local iff = c and ("if "..c.." then ") or ""
  local fi  = c and "end " or ""
  return ("(function() local _r={} for %s in %s "..
          "do %s%s %send return _r end)()"):format(v,it,iff,put,fi) end

local function body(n)  -- "E for V in ITER [if C]" -> E,V,ITER,C?
  local e,v,it,c = n:match"^(.-) for (.-) in (.-) if (.+)$"
  if not e then e,v,it = n:match"^(.-) for (.-) in (.+)$" end
  return e,v,it,c end

-- The language is two data tables and a nine-line engine.
-- H: literals hidden before any rewrite (long comments, long
-- strings, "", '', -- ...) so no sigil below looks inside them.
local H = {"(%-%-%[(=*)%[.-%]%2%])", "(%[(=*)%[.-%]%2%])",
           '"[^"\n]*"', "'[^'\n]*'", "%-%-[^\n]*"}

-- R: every rewrite luk does, in order.
local R = {
  {"%f[%w_]elif%f[%W]",      "elseif"},
  {"%f[%w_]fn%f[%W]",        "function"},
  {"@[ \t]*",                "return "},
  {"%f[%w_]let%f[%W]",       "local"},
  {"%b{}", function(m)
     local e,v,it,c = body(m:sub(2,-2))
     local k,ve; if e then k,ve = e:match"^(.-),(.+)$" end
     if k then return comprehension("_r["..k.."]="..ve,v,it,c) end
     return m end},
  {"%b[]", function(m)
     local e,v,it,c = body(m:sub(2,-2))
     if e then return comprehension("_r[#_r+1]="..e,v,it,c) end
     return m end},
}

return function(src)
  local s = {}
  local function hide(m) s[#s+1]=m; return "\3"..#s.."\3" end
  for _,p in ipairs(H) do src = src:gsub(p, hide) end
  for _,p in ipairs(R) do src = src:gsub(p[1],p[2]) end
  while src:find"\3" do      -- unhide; markers nest ("s" inside --)
    src = src:gsub("\3(%d+)\3", function(n) return s[tonumber(n)] end) end
  return src end
