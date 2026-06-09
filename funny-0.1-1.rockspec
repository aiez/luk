package = "funny"
version = "0.1-1"

source = {
  url = "git+https://tiny.cc/funny",
}

description = {
  summary  = "tiny .fun -> Lua transpiler (~115-line filter)",
  detailed = [[
    funny is the .fun language: a tiny indentation-based dialect
    that transpiles to Lua. Same Lua semantics, fewer `end`s,
    Python-style list comprehensions.

    The module returns a single function:
      local funny = require("funny")
      local lua_src = funny(fun_src)

    Worked example (fft.fun, a multi-objective regression tree)
    at http://tiny.cc/funny.
  ]],
  license    = "MIT",
  homepage   = "http://tiny.cc/funny",
  maintainer = "Tim Menzies <timm@ieee.org>",
}

dependencies = { "lua >= 5.3" }

build = {
  type    = "builtin",
  modules = { funny = "funny.lua" },
  install = { conf = { ",funny.md" } },
}
