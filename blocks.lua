-- blocks.lua : optional stage 1 for luk -- Python-style blocks.
--   a line ending ":" opens a block; the body is the lines indented
--   under it; the dedent closes it ("if (x):" -> "if (x) then ... end")
--   a "KEYWORD ...: BODY" one-liner opens and closes on its own line
-- luk.lua requires this and runs it on hidden source (strings and
-- comments already swapped for \3N\3 markers), so a ":" inside either
-- is never a header. A file with no line ending ":" comes back
-- unchanged, so explicit then/do/end stays valid.
--
-- This is the one part of luk that is a parser, not a rewrite: it
-- walks lines carrying an indent stack, where luk.lua is whole-source
-- gsubs over two data tables. Kept separate so the contrast is
-- readable. Line numbers survive: "end" is prepended to the dedent
-- line, never appended to the block's last line.

local heads = {["if"]="then", elif="then", ["while"]="do",
               ["for"]="do", ["else"]="", ["do"]=""}
local cont = {elif=1, ["else"]=1}   -- continue a chain, don't reopen

return function(src)
  local out, stk, d = {}, {}, 0
  for ln in (src.."\n"):gmatch"([^\n]*)\n" do
    if d == 0 and ln:find"%S" then         -- d>0: inside ( [ { , so
      local ind, w = ln:match"^([ \t]*)([%w_]*)"   -- hanging indents
      local pre, lim = "", #ind + (cont[w] and 1 or 0)   -- are safe
      while #stk > 0 and stk[#stk] >= lim do
        stk[#stk] = nil; pre = pre.."end " end
      local c, t = ln:match"^(.-)([ \t]*\3%d+\3)$"  -- hidden comment
      c = c or ln; t = t or ""                      -- at end of line
      local hdr = c:match"^(.*[^:]):$"              -- "if (x):"
      local a, b = c:match"^(.-):[ \t]+(%S.*)$"     -- "if (x): y"
      local open = hdr and hdr.." "..(heads[w] or "")
                or heads[w] and a and a.." "..heads[w].." "..b
      if open then
        c = open
        if not cont[w] then stk[#stk+1] = #ind end end
      ln = ind..pre..c:sub(#ind+1)..t end
    for br in ln:gmatch"[%(%)%[%]{}]" do
      d = d + (br:find"[%(%[{]" and 1 or -1) end
    out[#out+1] = ln end
  if #stk > 0 then out[#out+1] = ("end "):rep(#stk) end
  return table.concat(out, "\n") end
