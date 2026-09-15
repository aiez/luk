<!-- Copyright (c) 2026 Tim Menzies, MIT License https://opensource.org/licenses/MIT -->
<img align="right" src="https://img.shields.io/badge/Purpose-Tiny·Lua·Transpiler-7b68ee?logo=githubcopilot&logoColor=white" alt="Purpose"> <a href="https://timm.fyi"> <img align="right" src="https://img.shields.io/badge/Author-timm-dc143c?logo=readme&logoColor=white" alt="Author"></a> <img align="right" src="https://img.shields.io/badge/Language-Lua-000080?logo=lua&logoColor=white" alt="Language"><a href="https://choosealicense.com/licenses/mit/"> <img align="right" src="https://img.shields.io/badge/License-MIT-32cd32?logo=open-source-initiative&logoColor=white" alt="License"></a>

### [https://github.com/aiez/luk](https://github.com/aiez/luk)

`luk` is the **`.luk` language**: Lua plus `fn`, `^` for return,
`let` locals, `!=`, `elif`, and comprehensions. Blocks are Lua's
own (`then`/`do`/`end`), so any Lua is (almost) valid luk and
every `.luk` line maps 1:1 onto its generated Lua. One ~60-line
module, `luk.lua`, does whole-source transpilation; it is a pure
function, with no IO and no side effects.

```bash
git clone https://github.com/aiez/luk && cd luk
./luk fft.luk                 # transpile + run, args pass through
./luk -d fft.luk > fft.lua    # dump generated Lua
make fft.lua                  # same, via Makefile
```

For the optimizer shipped with luk (`fft.luk`) see [fft.md](fft.md).

**Sections:** [NAME](#name) | [SYNOPSIS](#synopsis) | [LANGUAGE REFERENCE](#language-reference) | [PERFORMANCE](#performance) | [FILES](#files) | [VIM SUPPORT](#vim-support) | [SEE ALSO](#see-also) | [LICENSE](#license) | [AUTHOR](#author)

**Files:** [luk.lua](https://github.com/aiez/luk#file-luk-lua) | [fft.luk](https://github.com/aiez/luk#file-fft-luk) | [lib.luk](https://github.com/aiez/luk#file-lib-luk) | [stats.luk](https://github.com/aiez/luk#file-stats-luk) | [tests.lua](https://github.com/aiez/luk#file-tests-lua) | [fft.md](https://github.com/aiez/luk#file-fft-md) | [luk.rc](https://github.com/aiez/luk#file-luk-rc) | [luk.vim](https://github.com/aiez/luk#file-luk-vim)

## NAME

    luk - .luk-to-Lua transpiler (single-file, no deps)

## SYNOPSIS

    ./luk FILE.luk [args...]     # transpile + run
    ./luk -d FILE.luk            # dump generated Lua
    lua -e 'io.write(require"luk"(io.read"*a"))' <IN.luk >OUT.lua
    -- or programmatically:
    --   local luk = require("luk")
    --   local f   = assert(load(luk(src), "@foo.luk"))

`luk.lua` is only the transpiler. The `luk` runner adds a
`require()` hook, so `.luk` files can require each other:
`require"xx"` loads `xx.luk` if present (transpiled, with real
error line numbers), else falls back to plain Lua. The hook
searches `package.path` with `.lua` swapped for `.luk`, so
installed rocks work too. Pass `"@NAME.luk"` to `load` to keep
error lines pointing at the `.luk` source.

## LANGUAGE REFERENCE

Everything below is whole-source rewriting; strings and comments
are hidden first, so sigils inside them are safe. Every rewrite
stays on its own line, so generated Lua keeps the source's line
numbers exactly and error messages point at real `.luk` lines.

### Keywords

    fn                 -> function
    elif               -> elseif
    !=                 -> ~=     (Lua's not-equal)
    let NAME = EXPR    -> local NAME = EXPR
    let A, B = X, Y    -> local A, B = X, Y

### Return

    ^EXPR              -> return EXPR

`^` means return only at a statement start: start of line, or
after `;`, `then`, `do`, `else`, or a `fn(...)` parameter list.
Infix exponentiation `a ^ b` is untouched.

    let double = fn(z) ^z * 2 end
    let pick   = fn(b) if b then ^"yes" else ^"no" end end

### Functions

`fn` is just `function`, so every Lua shape works, on one line
or many:

    fn double(x) ^x * 2 end           -- named
    let f = fn(a) ^a + 1 end          -- one-liner
    sort(t, fn(a, b) ^a.k < b.k end)  -- mid-expression
    let g = fn(a)                     -- multi-line
      let b = a * 2
      ^b end

House style parks `end` at the end of the last body line:

    fn sign(x)                        function sign(x)
      if x > 0 then ^1                  if x > 0 then return 1
      elif x < 0 then ^-1               elseif x < 0 then return -1
      else ^0 end end                   else return 0 end end
    print(sign(3))                    print(sign(3))

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

### Gotchas

  - `elif`, `fn` and `let` are keywords everywhere: don't use
    them as variable names (or table keys like `{let = 1}`).
  - No compound assignment: write `x = x + 1`, not `x += 1`.
  - No shebang line in `.luk` files (load() rejects `#`).
  - Long strings/comments `[[...]]` and goto labels `::x::`
    pass through untouched.
  - Indentation is not significant; indent however you like.
  - `ft=lua` is survivable -- only `fn`, `^`, `let`, `!=` and
    comprehensions are foreign -- but `ft=luk` + `luk.vim`
    colours them properly. The files' modelines say `ft=luk`.

## PERFORMANCE

Runtime, default mode (depth=4, 16 trees built):

    file       rows    fft.py   fft.lua  fft.luk (transpile+run)
    --------   -----   ------   ------   -----------------------
    auto93     398     0.080s   0.038s   0.035s
    SS-N      53663    9.18s    5.86s    6.15s

Lua 1.5x-2.5x faster than Python. Transpile is whole-source
gsubs, no line pass: ~2ms for a 250-line file, ~90ms for 10,000
lines (~95% of a .luk require; plain .lua parses in ~4ms).
Negligible on any real workload.

## FILES

    luk.lua      .luk -> .lua transpiler (pure fn, no IO)
    tests.lua    transpiler regression tests (lua tests.lua)
    test_*.luk   lib/stats/fft checks (make tests, or
                 ./luk test_lib.luk [NAME...])
    luk          runner: .luk require() hook, transpile + run
    lib.luk      "battery": portable PRNG (srand/rand/any/shuffle),
                 o pretty-print, push, keys/order, nth/lt/gt,
                 keysort, slice, new, deepCopy, path, csv iterator,
                 sum, argmin, of, ...
    stats.luk    non-parametric stats: cliffsDelta, ks, sames,
                 pooledSd, topTier (requires "lib")
    fft.luk      example: multi-objective regression tree
    Makefile     rule:  %.lua: %.luk luk.lua
    sandbox/     retired v0.1 indentation-based dialect (luk2)
                 (v0.3's ":" block syntax is retired too)

## VIM SUPPORT

    syntax: luk.vim (Lua syntax + luk overlay)
    shell with .luk-aware vi: make fsh (see luk.rc)

## SEE ALSO

    fft.md                   help page for the fft.luk app
    https://github.com/aiez/fft       Python sibling project
    https://github.com/aiez/optimiz   example CSVs
    https://github.com/aiez/konfig    shared Makefile

## LICENSE

    MIT. (c) 2026 Tim Menzies.

## AUTHOR

    Tim Menzies <timm@ieee.org>
