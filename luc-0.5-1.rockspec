package = "luc"
version = "0.5-1"

source = {
  url = "git+https://github.com/aiez/luc",
}

description = {
  summary  = "tiny .luc -> Lua transpiler (~70-line module) + cli + battery",
  detailed = [[
    luc is the .luc language: Lua plus `fn` for local functions,
    `@` for return, `$` for local, `elif`, loop auto-wrapping,
    and comprehensions. Blocks are Lua's
    own (then/do/end), so any Lua is (almost) valid luc, and
    every .luc line maps 1:1 onto its generated Lua, which
    keeps the source's line numbers exactly.

    The module is a pure function, no IO and no side effects:
      local luc = require("luc")
      local lua_src = luc(luc_src)
    The bundled "luc" cli adds a require() hook, so .luc files
    can require each other.

    Ships with:
      luc        cli: transpile + run (luc FILE.luc [args...];
                 luc -d FILE.luc dumps the generated Lua)
      lib.luc    battery: portable PRNG, pretty-print, keysort,
                 slice, csv iterator, argmin, ... (require "lib")
      stats.luc  non-parametric stats: cliffsDelta, ks, sames,
                 topTier (require "stats")
      fft.luc    worked example: multi-objective regression tree
      tests      tests.lua + test_*.luc (installed under etc/)
  ]],
  license    = "MIT",
  homepage   = "https://github.com/aiez/luc",
  maintainer = "Tim Menzies <timm@ieee.org>",
}

dependencies = { "lua >= 5.1" }

build = {
  type    = "builtin",
  modules = { luc = "luc.lua" },
  install = {
    bin  = { luc = "luc" },
    lua  = { lib = "lib.luc", stats = "stats.luc", fft = "fft.luc" },
    conf = { "README.md", "tests.lua",
             "test_lib.luc", "test_stats.luc", "test_fft.luc" },
  },
}
