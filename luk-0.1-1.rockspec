package = "luk"
version = "0.1-1"

source = {
  url = "git+https://tiny.cc/luk",
}

description = {
  summary  = "tiny .luk -> Lua transpiler (~100-line module)",
  detailed = [[
    luk is the .luk language: a tiny indentation-based dialect
    that transpiles to Lua. Same Lua semantics, fewer `end`s,
    Python-style list comprehensions.

    The module returns a single function:
      local luk = require("luk")
      local lua_src = luk(fun_src)

    Worked example (fft.luk, a multi-objective regression tree)
    at http://tiny.cc/luk.
  ]],
  license    = "MIT",
  homepage   = "http://tiny.cc/luk",
  maintainer = "Tim Menzies <timm@ieee.org>",
}

dependencies = { "lua >= 5.3" }

build = {
  type    = "builtin",
  modules = { luk = "luk.lua" },
  install = { conf = { ",luk.md", "luk.vim" } },
}
