-- luk2.lua : RETIRED indentation-based ".luk" -> Lua transpiler.
-- (was luk.lua v0.1; replaced by the end-syntax luk.lua upstairs)
-- Returns transpile fn.
-- fun=function  ^=return  let NAME=V  ->  local NAME=V
-- if (c): elseif (c): else: for X in Y: while c: fun(a):
-- Body after ":" = one-liner (auto end). Indent block ends on outdent.
-- [e for v in xs] / [e for v in xs if c] = comprehension.

local function comprehension(e,v,i,c)
  if not v:find"," and not i:find"%(" then
    v,i = "_,"..v, "ipairs("..i..")"
  elseif not i:find"%(" then i = "pairs("..i..")" end
  local g = c and ("if "..c.." then ") or ""
  local z = c and "end " or ""
  return ("(function() local _r={} for %s in %s "..
          "do %s_r[#_r+1]=%s %send return _r end)()"
         ):format(v,i,g,e,z) end

local function oneLiner(r)
  if not r:find":%s+%S" or r:find"%f[%w_]end%f[%W]" then
    return false end
  local t = r:gsub("^%s+","")
  return t:match"^if%s*%(" or t:match"^elseif%s*%("
      or t:match"^else%s*:" or t:match"^for%s"
      or t:match"^while%s"  or t:match"^let%s.-=%s*fun%s*%("
      or t:match"^[%w_.%[%]\"'%-]+%s*=%s*fun%s*%(" end

local function opensBlock(s)
  if s:match"%f[%w_]then%s*$" or s:match"%f[%w_]do%s*$" then
    return true end
  local t = s:gsub("^%s+","")
  return t:match"^local%s+[%w_.,%s]+%s*=%s*function%b()%s*$"
      or t:match"^[%w_.%[%]\"'%-]+%s*=%s*function%b()%s*$"
      or t:match"^return%s+function%b()%s*$" end

local function cont(r) return r:match"^%s*else" end
local function ind(s) return #(s:match"^%s*":gsub("\t","  ")) end

local function line(b)
  if b:match"^%s*%-%-" or b:match"^%s*$" or b:match"^#!" then
    return b end
  local s, c = {}, ""
  local function hide(m) s[#s+1]=m; return "\3"..#s.."\3" end
  local R = {
    {'%[%[.-%]%]', hide},
    {'"[^"]*"',    hide},
    {"'[^']*'",    hide},
    {"(%s*%-%-.*)$", function(x) c=x; return "" end},
    {"^(%s*)let%f[%W]%s+([%w_][%w_,%s]-)%s*=", "%1local %2 ="},
    {"^(%s*)([%w_.]+)%s*([%+%-%*/])=%s+",
                                      "%1%2 = %2 %3 "},
    {"%f[%w_]fun%f[%W]",              "function"},
    {"%f[%w_]if%s+(.+)%s*:%s*$",      "if %1 then"},
    {"%f[%w_]if%s+(.+)%s*:(%s)",      "if %1 then%2"},
    {"%f[%w_]elseif%s+(.+)%s*:%s*$",  "elseif %1 then"},
    {"%f[%w_]elseif%s+(.+)%s*:(%s)",  "elseif %1 then%2"},
    {"(%f[%w_]for%s.+)%s*:%s*$",      "%1 do"},
    {"(%f[%w_]for%s.+)%s*:(%s)",      "%1 do%2"},
    {"(%f[%w_]while%s.+)%s*:%s*$",    "%1 do"},
    {"(%f[%w_]while%s.+)%s*:(%s)",    "%1 do%2"},
    {"function%s*(%b())%s*:%s*$",     "function%1"},
    {"function%s*(%b())%s*:(%s)",     "function%1%2"},
    {"(%f[%w_]else)%s*:%s*$",         "%1"},
    {"(%f[%w_]else)%s*:(%s)",         "%1%2"},
    {"!=",                            "~="},
    {"^(%s*)%^%s*",                   "%1return "},
    {"(;%s*)%^%s*",                   "%1return "},
    {"(%f[%w_]then%f[%W]%s*)%^%s*",   "%1return "},
    {"(%f[%w_]do%f[%W]%s*)%^%s*",     "%1return "},
    {"(%f[%w_]else%f[%W]%s*)%^%s*",   "%1return "},
    {"(function%s*%b()%s*)%^%s*",     "%1return "},
    {"%b[]", function(m)
       local n = m:sub(2,-2)
       local e,v,i,k = n:match"^(.-) for (.-) in (.-) if (.+)$"
       if e then return comprehension(e,v,i,k) end
       e,v,i = n:match"^(.-) for (.-) in (.+)$"
       if e then return comprehension(e,v,i) end
       return m end},
    {"\3(%d+)\3", function(n) return s[tonumber(n)] end},
  }
  for _,p in ipairs(R) do b = b:gsub(p[1], p[2]) end
  return b..c end

return function(src)
  local out, stk = {}, {}
  local function close(i)
    while #stk>0 and stk[#stk] >= i do
      stk[#stk] = nil
      local k = #out
      while k>0 and (out[k]:match"^%s*$"
                  or out[k]:match"^%s*%-%-") do k = k-1 end
      if k>0 then out[k] = out[k] .. " end"
      else        out[#out+1] = "end" end end end
  for r0 in (src.."\n"):gmatch"([^\n]*)\n" do
    local r = r0
    if r:match"^%s*$" then out[#out+1] = r
    elseif r:match"^%s*%-%-" then close(ind(r)); out[#out+1] = r
    else
      local i, c = ind(r), cont(r)
      close(c and i+1 or i)
      if oneLiner(r) and not c and not r:match"%f[%w_]end%s*$" then
        r = r .. " end" end
      r = line(r)
      out[#out+1] = r
      if opensBlock(r) and not c then stk[#stk+1] = i end end end
  close(-1)
  return table.concat(out, "\n") end
