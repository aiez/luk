-- luk.lua : whole-source ".luk" -> Lua transpiler. One file, two modes:
--   require"luk"             -> installs require() hook for .luk modules
--                               (chunk name @foo.luk = real error lines),
--                               returns the transpile fn
--   lua luk.lua <in >out     -> stdin/stdout filter
-- Not line-based. Blocks stay pure Lua (then/do/else/end).
-- fn=function  "!=" = ~=   NAME:=V -> local NAME=V
-- ^ = return, only at statement start: line start, or after
-- ";" / "then" / "do" / "else" / "function(...)". Infix a^b untouched.
-- [e for v in xs] / [e for v in xs if c]     = list comprehension
-- {k,v for k,v in xs} / {.. if c}            = dict comprehension
-- Comprehensions may span lines. Limits: no nesting them;
-- dict key expr must not contain a bare comma.

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

local function transpile(src)
  local s = {}
  local function hide(m) s[#s+1]=m; return "\3"..#s.."\3" end
  local R = {
    {"(%-%-%[(=*)%[.-%]%2%])", hide},   -- long comments
    {"(%[(=*)%[.-%]%2%])",     hide},   -- long strings
    {'"[^"\n]*"',              hide},
    {"'[^'\n]*'",              hide},
    {"%-%-[^\n]*",             hide},   -- line comments
    {"!=",                     "~="},
    {"%f[%w_]fn%f[%W]",        "function"},
    {"(\n[ \t]*)%^[ \t]*",     "%1return "},
    {"(;[ \t]*)%^[ \t]*",      "%1return "},
    {"(%f[%w_]then%f[%W][ \t]*)%^[ \t]*",       "%1return "},
    {"(%f[%w_]do%f[%W][ \t]*)%^[ \t]*",         "%1return "},
    {"(%f[%w_]else%f[%W][ \t]*)%^[ \t]*",       "%1return "},
    {"(function[%w_.: \t]*%b()[ \t]*)%^[ \t]*", "%1return "},
    {"([^%w_.])([%w_][%w_, \t]*):=", "%1local %2="},
    {"%b{}", function(m)
       local e,v,i,c = body(m:sub(2,-2))
       local k,ve; if e then k,ve = e:match"^(.-),(.+)$" end
       if k then return comprehension("_r["..k.."]="..ve,v,i,c) end
       return m end},
    {"%b[]", function(m)
       local e,v,i,c = body(m:sub(2,-2))
       if e then return comprehension("_r[#_r+1]="..e,v,i,c) end
       return m end},
    {"\3(%d+)\3", function(n) return s[tonumber(n)] end},
  }
  src = "\n"..src
  for _,p in ipairs(R) do src = src:gsub(p[1],p[2]) end
  return src:sub(2) end

if ... then                        -- require"luk": add .luk loader
  table.insert(package.searchers or package.loaders, 2, function(name)
    name = name:gsub("%.luk$", "")   -- allow require"xx.luk"
    local path, err = package.searchpath(
      name, (package.path:gsub("%.lua", ".luk")))
    if not path then return err end
    local f = assert(io.open(path))
    local src = f:read"*a"; f:close()
    return assert(load(transpile(src), "@"..path)), path end)
  return transpile
else                               -- lua luk.lua <IN.luk >OUT.lua
  io.write(transpile(io.read"*a")) end
