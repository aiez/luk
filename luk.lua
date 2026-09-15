-- luk.lua : whole-source ".luk" -> Lua transpiler. Pure function,
-- no side effects, no IO:
--   local luk = require"luk"
--   local f   = assert(load(luk(src), "@foo.luk"))  -- real err lines
-- The require() hook for .luk modules lives in the "luk" runner.
-- Lua plus five sigils, all pure same-line rewrites:
--   fn=function  elif=elseif  !=  ^=return  let NAME=V  comprehensions.
-- Blocks are Lua's own (then/do/end), so every source line maps 1:1
-- onto the generated Lua and error lines always match.
-- Full guide + gotchas: README "LANGUAGE REFERENCE".

local function comprehension(a,v,i,c)
  if not v:find"," and not i:find"%(" then
    v,i = "_,"..v, "ipairs("..i..")"
  elseif not i:find"%(" then i = "pairs("..i..")" end
  local g = c and ("if "..c.." then ") or ""
  local z = c and "end " or ""
  return ("(function() local _r={} for %s in %s "..
          "do %s%s %send return _r end)()"):format(v,i,g,a,z) end

local function body(n)  -- "E for V in I [if C]" -> E,V,I,C?
  local e,v,i,c = n:match"^(.-) for (.-) in (.-) if (.+)$"
  if not e then e,v,i = n:match"^(.-) for (.-) in (.+)$" end
  return e,v,i,c end

return function(src)
  local s = {}
  local function hide(m) s[#s+1]=m; return "\3"..#s.."\3" end
  local H = {           -- long comments, long strings, "", '', -- ...
    {"(%-%-%[(=*)%[.-%]%2%])", hide}, {"(%[(=*)%[.-%]%2%])", hide},
    {'"[^"\n]*"', hide}, {"'[^'\n]*'", hide}, {"%-%-[^\n]*", hide}}
  local R = {
    {"!=",                     "~="},
    {"%f[%w_]elif%f[%W]",      "elseif"},
    {"%f[%w_]fn%f[%W]",        "function"},
    {"(\n[ \t]*)%^[ \t]*",     "%1return "},
    {"(;[ \t]*)%^[ \t]*",      "%1return "},
    {"(%f[%w_]then%f[%W][ \t]*)%^[ \t]*",       "%1return "},
    {"(%f[%w_]do%f[%W][ \t]*)%^[ \t]*",         "%1return "},
    {"(%f[%w_]else%f[%W][ \t]*)%^[ \t]*",       "%1return "},
    {"(function[%w_.: \t]*%b()[ \t]*)%^[ \t]*", "%1return "},
    {"%f[%w_]let[ \t]+([%w_][%w_, \t]-)([ \t]*=)", "local %1%2"},
    {"%b{}", function(m)
       local e,v,i,c = body(m:sub(2,-2))
       local k,ve; if e then k,ve = e:match"^(.-),(.+)$" end
       if k then return comprehension("_r["..k.."]="..ve,v,i,c) end
       return m end},
    {"%b[]", function(m)
       local e,v,i,c = body(m:sub(2,-2))
       if e then return comprehension("_r[#_r+1]="..e,v,i,c) end
       return m end},
  }
  for _,p in ipairs(H) do src = src:gsub(p[1],p[2]) end
  src = "\n"..src            -- so "^" can start line 1
  for _,p in ipairs(R) do src = src:gsub(p[1],p[2]) end
  while src:find"\3" do      -- unhide; markers nest ("s" inside --)
    src = src:gsub("\3(%d+)\3", function(n) return s[tonumber(n)] end) end
  return src:sub(2) end
