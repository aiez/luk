<!-- Copyright (c) 2026 Tim Menzies, MIT License https://opensource.org/licenses/MIT -->
<img align="right" src="https://img.shields.io/badge/Purpose-Tiny·Lua·Transpiler-7b68ee?logo=githubcopilot&logoColor=white" alt="Purpose"> <a href="https://timm.fyi"> <img align="right" src="https://img.shields.io/badge/Author-timm-dc143c?logo=readme&logoColor=white" alt="Author"></a> <img align="right" src="https://img.shields.io/badge/Language-Lua-000080?logo=lua&logoColor=white" alt="Language"><a href="https://choosealicense.com/licenses/mit/"> <img align="right" src="https://img.shields.io/badge/License-MIT-32cd32?logo=open-source-initiative&logoColor=white" alt="License"></a>

### [https://github.com/aiez/luk](https://github.com/aiez/luk)

`luk` is the **`.luk` language**: Lua plus `fn`, `^` for return,
`:=` locals, `!=`, and Python-style comprehensions. Blocks stay
pure Lua (`then/do/else/end`), so any Lua is (almost) valid luk.
One ~70-line module, `luk.lua`, does whole-source transpilation
and installs a `require()` hook for `.luk` modules.

```bash
git clone https://github.com/aiez/luk && cd luk
./luk fft.luk                 # transpile + run, args pass through
./luk -d fft.luk > fft.lua    # dump generated Lua
make fft.lua                  # same, via Makefile
```

For the optimizer shipped with luk (`fft.luk`) see [fft.md](fft.md).

**Sections:** [NAME](#name) | [SYNOPSIS](#synopsis) | [LANGUAGE REFERENCE](#language-reference) | [PERFORMANCE](#performance) | [FILES](#files) | [VIM SUPPORT](#vim-support) | [SEE ALSO](#see-also) | [LICENSE](#license) | [AUTHOR](#author)

**Files:** [luk.lua](https://github.com/aiez/luk#file-luk-lua) | [fft.luk](https://github.com/aiez/luk#file-fft-luk) | [lib.luk](https://github.com/aiez/luk#file-lib-luk) | [fft.lua](https://github.com/aiez/luk#file-fft-lua) | [lib.lua](https://github.com/aiez/luk#file-lib-lua) | [fft.md](https://github.com/aiez/luk#file-fft-md) | [luk.rc](https://github.com/aiez/luk#file-luk-rc) | [luk.vim](https://github.com/aiez/luk#file-luk-vim)

## NAME

    luk - .luk-to-Lua transpiler (single-file, no deps)

## SYNOPSIS

    ./luk FILE.luk [args...]     # transpile + run
    ./luk -d FILE.luk            # dump generated Lua
    lua -e 'io.write(require"luk"(io.read"*a"))' <IN.luk >OUT.lua
    -- or programmatically:
    --   local lua_src = require("luk")(luk_src)

Requiring `luk` also installs a `require()` hook: `require"xx"`
loads `xx.luk` if present (transpiled, with real error line
numbers), else falls back to plain Lua. `require"xx.luk"` forces
the `.luk` version.

## LANGUAGE REFERENCE

Blocks are pure Lua: `if c then ... else ... end`,
`for ... do ... end`, `while ... do ... end`. Everything below is
whole-source token rewriting; strings and comments are hidden
first, so sigils inside them are safe.

### Keywords

    fn                 -> function
    !=                 -> ~=     (Lua's not-equal)

### Return

    ^ EXPR             -> return EXPR

`^` means return only at a statement start: start of line, or
after `;`, `then`, `do`, `else`, or a `fn(...)` parameter list.
Infix exponentiation `a^b` is untouched.

    double := fn(z) ^ z * 2 end
    pick   := fn(b) if b then ^ "yes" else ^ "no" end end

### Local declarations

    NAME := EXPR       -> local NAME = EXPR
    A, B := X, Y       -> local A, B = X, Y

### Comprehensions (may span lines; no nesting)

    [EXPR for V in ITER]              -- list
    [EXPR for V in ITER if COND]
    {K, V for K, V in ITER}           -- dict
    {K, V for K, V in ITER if COND}

  ITER auto-wrapping:

    - 1 var, no "(" in ITER  -> ipairs(ITER)
    - 2 vars, no "(" in ITER -> pairs(ITER)
    - else passed through as-is

  Limit: a dict comprehension's key expression must not contain
  a bare comma.

### Misc

  - No compound assignment: write `x = x + 1`, not `x += 1`.
  - No shebang line in `.luk` files (load() rejects `#`).
  - Long strings/comments `[[...]]` pass through untouched.

## PERFORMANCE

Runtime, default mode (depth=4, 16 trees built):

    file       rows    fft.py   fft.lua  fft.luk (transpile+run)
    --------   -----   ------   ------   -----------------------
    auto93     398     0.080s   0.038s   0.035s
    SS-N      53663    9.18s    5.86s    6.15s

Lua 1.5x-2.5x faster than Python. Transpile is whole-source
gsub, ~1ms for a 250-line file: negligible on any real workload.

## FILES

    luk.lua      .luk -> .lua transpiler + require() hook
    luk          runner: transpile + run (./luk FILE.luk)
    lib.luk      "battery" helpers (argmin, sum, csv, of, ...)
    fft.luk      example: multi-objective regression tree
    Makefile     rule:  %.lua: %.luk luk.lua
    sandbox/     retired v0.1 indentation-based dialect (luk2)

## VIM SUPPORT

    syntax: luk.vim (Lua syntax + luk overlay)
    shell with .luk-aware vi: make fsh (see luk.rc)

## SEE ALSO

    fft.md                   help page for the fft.lua app
    https://github.com/aiez/fft       Python sibling project
    https://github.com/aiez/optimiz   example CSVs
    https://github.com/aiez/konfig    shared Makefile

## LICENSE

    MIT. (c) 2026 Tim Menzies.

## AUTHOR

    Tim Menzies <timm@ieee.org>
