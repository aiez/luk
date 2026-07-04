package = "luk"
version = "0.2-1"

source = {
  url = "git+https://github.com/aiez/luk",
}

description = {
  summary  = "tiny .luk -> Lua transpiler (~70-line module)",
  detailed = [[
    luk is the .luk language: Lua plus `fn`, `^` for return,
    `:=` locals, `!=`, and Python-style comprehensions. Blocks
    stay pure Lua (then/do/else/end).

    The module returns a single function and installs a
    require() hook for .luk modules:
      local luk = require("luk")
      local lua_src = luk(luk_src)

    Worked example (fft.luk, a multi-objective regression tree)
    at https://github.com/aiez/luk.
  ]],
  license    = "MIT",
  homepage   = "https://github.com/aiez/luk",
  maintainer = "Tim Menzies <timm@ieee.org>",
}

dependencies = { "lua >= 5.3" }

build = {
  type    = "builtin",
  modules = { luk = "luk.lua" },
  install = { conf = { ",luk.md", "luk.vim" } },
}
