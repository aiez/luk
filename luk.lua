-- luk.lua : whole-source ".luk" -> Lua transpiler. One file, two modes:
--   require"luk"             -> installs require() hook for .luk modules
--                               (chunk name @foo.luk = real error lines),
--                               returns the transpile fn
--   lua luk.lua <in >out     -> stdin/stdout filter
-- Python-style blocks: a line ending ":" opens one; the indented body
-- closes at dedent ("end" lands on the block's last code line, so
-- error lines always match the source). One-liners use colon-space:
--   if x: ^y     fn(a): ^a*2     elif c: z
-- fn=function  elif=elseif  !=  ^=return  NAME:=V  comprehensions.
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

local function split(s, ln)  -- line -> code, trailing hidden comment
  local a, b, n = ln:match"^(.-)([ \t]*\3(%d+)\3[ \t]*)$"
  if a and s[tonumber(n)]:find"^%-%-" then return a, b end
  return ln, "" end

local heads = {["if"]="then", ["elseif"]="then", elif="then",
               ["while"]="do", ["for"]="do", ["else"]="", ["do"]=""}

local FN = "(%f[%w_]fn%f[%W][%w_.: \t]*%b())[ \t]*:[ \t]([^\n]*)"
local function fnliner(s)         -- one-liner "fn(..): B": insert " end"
  return function(head, rest)     -- before unbalanced )]} or bare ","
    local code, tail = split(s, rest)
    code = code:gsub(FN, fnliner(s))       -- serial / nested anon fns
    local d = 0
    for j = 1, #code do
      local ch = code:sub(j, j)
      d = d + (ch:find"[%(%[{]" and 1 or ch:find"[%)%]}]" and -1 or 0)
      if d < 0 or (d == 0 and ch == ",") then
        return head.." "..code:sub(1, j-1).." end"..code:sub(j)..tail end end
    return head.." "..code.." end"..tail end end

local function blocks(src, s)     -- ":" headers -> then/do + auto-end
  local out, stk, d = {}, {}, 0
  local function close(i)         -- pop blocks indented >= i; each pop
    while #stk > 0 and stk[#stk] >= i do   -- appends " end" to the
      stk[#stk] = nil                      -- last code line so far
      for k = #out, 1, -1 do
        local a, b = split(s, out[k])
        if a:find"%S" then out[k] = a.." end"..b; break end end end end
  for ln in (src.."\n"):gmatch"([^\n]*)\n" do
    local code, tail = split(s, ln)
    if d == 0 and code:find"%S" then
      local ind = #code:match"^[ \t]*"
      local w = code:match"^[ \t]*([%w_]*)"
      local cont = w=="else" or w=="elseif" or w=="elif"
      close(cont and ind+1 or ind)
      local hdr = code:match"^(.-[^:]):$"       -- "if x:" block header
      local a, b = code:match"^(.-):[ \t]+(%S.*)$"  -- "if x: y" one-liner
      local open = hdr and hdr.." "..(heads[w] or "")
                or heads[w] and a and a.." "..heads[w].." "..b
      if open then
        code = open
        if not cont then stk[#stk+1] = ind end end end
    for br in code:gmatch"[%(%)%[%]{}]" do
      d = d + (br:find"[%(%[{]" and 1 or -1) end
    out[#out+1] = code..tail end
  close(0)
  return table.concat(out, "\n") end

local function transpile(src)
  local s = {}
  local function hide(m) s[#s+1]=m; return "\3"..#s.."\3" end
  local H = {           -- long comments, long strings, "", '', -- ...
    {"(%-%-%[(=*)%[.-%]%2%])", hide}, {"(%[(=*)%[.-%]%2%])", hide},
    {'"[^"\n]*"', hide}, {"'[^'\n]*'", hide}, {"%-%-[^\n]*", hide}}
  local R = {
    {"!=",                     "~="},
    {"%f[%w_]elif%f[%W]",      "elseif"},
    {FN,                       fnliner(s)},
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
  for _,p in ipairs(H) do src = src:gsub(p[1],p[2]) end
  src = "\n"..blocks(src, s)
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
