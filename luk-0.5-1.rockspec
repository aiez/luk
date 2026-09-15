package = "luk"
version = "0.5-1"

source = {
  url = "git+https://github.com/aiez/luk",
}

description = {
  summary  = "tiny .luk -> Lua transpiler (~66 lines, 2 files) + cli + battery",
  detailed = [[
    luk is the .luk language: Lua plus `fn`, `@` for return,
    `let` locals, `elif`, comprehensions, and optional
    Python-style ":" blocks. Explicit then/do/end also works,
    so any Lua is (almost) valid luk, and every .luk line maps
    1:1 onto its generated Lua, which keeps the source's line
    numbers exactly.

    The module is a pure function, no IO and no side effects:
      local luk = require("luk")
      local lua_src = luk(luk_src)
    The bundled "luk" cli adds a require() hook, so .luk files
    can require each other.

    Ships with:
      luk        cli: transpile + run (luk FILE.luk [args...];
                 luk -d FILE.luk dumps the generated Lua)
      lib.luk    battery: portable PRNG, pretty-print, keysort,
                 slice, csv iterator, argmin, ... (require "lib")
      stats.luk  non-parametric stats: cliffsDelta, ks, sames,
                 topTier (require "stats")
      fft.luk    worked example: multi-objective regression tree
      tests      tests.lua + test_*.luk (installed under etc/)
  ]],
  license    = "MIT",
  homepage   = "https://github.com/aiez/luk",
  maintainer = "Tim Menzies <timm@ieee.org>",
}

dependencies = { "lua >= 5.3" }

build = {
  type    = "builtin",
  modules = { luk = "luk.lua", blocks = "blocks.lua" },
  install = {
    bin  = { luk = "luk" },
    lua  = { lib = "lib.luk", stats = "stats.luk", fft = "fft.luk" },
    conf = { "README.md", "tests.lua",
             "test_lib.luk", "test_stats.luk", "test_fft.luk" },
  },
}
