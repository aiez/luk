<!-- Copyright (c) 2026 Tim Menzies, MIT License https://opensource.org/licenses/MIT -->
<img align="right" src="https://img.shields.io/badge/Purpose-Tiny·Lua·Transpiler-7b68ee?logo=githubcopilot&logoColor=white" alt="Purpose"> <a href="https://timm.fyi"> <img align="right" src="https://img.shields.io/badge/Author-timm-dc143c?logo=readme&logoColor=white" alt="Author"></a> <img align="right" src="https://img.shields.io/badge/Language-Lua-000080?logo=lua&logoColor=white" alt="Language"><a href="https://choosealicense.com/licenses/mit/"> <img align="right" src="https://img.shields.io/badge/License-MIT-32cd32?logo=open-source-initiative&logoColor=white" alt="License"></a>

### [https://github.com/aiez/luk](https://github.com/aiez/luk)

`luk` is the **`.luk` language**: Lua plus Python-style indented
blocks (`if x:` ... dedent closes it), `fn`, `^` for return,
`:=` locals, `!=`, `elif`, and comprehensions. Explicit
`then/do/else/end` still works, so any Lua is (almost) valid luk.
One ~120-line module, `luk.lua`, does whole-source transpilation
and installs a `require()` hook for `.luk` modules.

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
    --   local lua_src = require("luk")(luk_src)

Requiring `luk` also installs a `require()` hook: `require"xx"`
loads `xx.luk` if present (transpiled, with real error line
numbers), else falls back to plain Lua. `require"xx.luk"` forces
the `.luk` version.

## LANGUAGE REFERENCE

Everything below is whole-source rewriting; strings and comments
are hidden first, so sigils inside them are safe. Generated Lua
keeps the source's line numbers exactly (auto-`end`s are appended
to a block's last code line), so error messages point at real
`.luk` lines.

### Blocks

A line ending in `:` opens a block; the indented body below it is
closed at the dedent (`end` is added for you):

    fn sign(x):                       function sign(x)
      if x > 0:                         if x > 0 then
        ^ 1                               return 1
      elif x < 0:                       elseif x < 0 then
        ^ -1                              return -1
      else:                             else
        ^ 0                               return 0 end end
    print(sign(3))                    print(sign(3))

Headers: `if c:` `elif c:` `else:` `while c:` `for ... :` `do:`
`fn NAME(...):` and `NAME := fn(...):`. Explicit Lua blocks
(`then/do/else/end`) still work and may be mixed freely.

### One-liners

`HEADER: BODY` on one line auto-closes (note the space after `:`):

    if x < lo: ^ lo                   if x < lo then return lo
    elif x > hi: ^ hi                 elseif x > hi then return hi end
    while i < 5: i = i + 1            while i < 5 do i = i + 1 end
    for i = 1, 4: s = s + i           for i = 1, 4 do s = s + i end
    fn double(x): ^ x * 2             function double(x) return x*2 end

A one-liner `if` followed by `elif`/`else` lines continues the
chain; the chain closes at the next non-`else` line.

### Functions

Three anonymous-fn shapes:

    f := fn(a): ^ a + 1               -- one-liner (auto end)
    sort(t, fn(a,b): ^ a.k < b.k)     -- mid-expression one-liner:
                                      --   "end" lands before the
                                      --   unbalanced ")]}" or comma
    g := fn(a):                       -- fn last on the line:
      b := a * 2                      --   full indented body,
      ^ b                             --   n lines, no "end"

### Keywords

    fn                 -> function
    elif               -> elseif
    !=                 -> ~=     (Lua's not-equal)

### Return

    ^ EXPR             -> return EXPR

`^` means return only at a statement start: start of line, or
after `;`, `then`, `do`, `else`, or a `fn(...)` parameter list.
Infix exponentiation `a^b` is untouched.

    double := fn(z): ^ z * 2
    pick   := fn(b): if b then ^ "yes" else ^ "no" end

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

### Gotchas

  - A one-liner's colon needs a space after it: `if x: y`. Method
    calls have no space (`obj:m()`), which is how the two are
    told apart. Never put a space after a method colon.
  - No `repeat:` — write plain Lua `repeat ... until c` (it works
    fine inside colon blocks; `until` needs no special care).
  - `elif` and `fn` are keywords everywhere: don't use them as
    variable names.
  - Statement one-liners don't nest: `if x: if y: z` breaks.
    (One-liner *anonymous fns* do nest and chain fine:
    `{fn(x): ^ x + 1, fn(y): ^ y * 2}`.)
  - Don't indent the line after a one-liner deeper than it.
  - Indent with spaces, consistently; tabs count as one column.
  - A multi-line anonymous fn mid-expression (e.g. as a call's
    first of several arguments) can't use `:` — write explicit
    `fn(x) ... end`, or make the fn the last thing on its line.
  - Lines inside unclosed `(`/`{`/`[` (multi-line tables, calls,
    comprehensions) are never treated as headers or dedents, so
    hanging indents are safe there.
  - goto labels `::x::` pass through untouched, but don't put one
    on the same line as a one-liner.
  - Don't edit `.luk` files under `ft=lua`: Lua *treesitter*
    can't parse colon one-liners, and its error recovery re-pairs
    the quotes around any string on that line -- the rest of the
    file then renders as one giant string (all green). Use
    `ft=luk` + `luk.vim` (regex-based, no such failure); the
    files' modelines already say `ft=luk`.
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
    tests.lua    transpiler regression tests (lua tests.lua)
    test_*.luk   lib/stats/fft checks (make tests, or
                 ./luk test_lib.luk [NAME...])
    luk          runner: transpile + run (./luk FILE.luk)
    lib.luk      "battery": portable PRNG (srand/rand/any/shuffle),
                 o pretty-print, push, keys/order, nth/lt/gt,
                 keysort, slice, new, deepCopy, path, csv iterator,
                 sum, argmin, of, ...
    stats.luk    non-parametric stats: cliffsDelta, ks, sames,
                 pooledSd, topTier (requires "lib")
    fft.luk      example: multi-objective regression tree
    Makefile     rule:  %.lua: %.luk luk.lua
    sandbox/     retired v0.1 indentation-based dialect (luk2)

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
