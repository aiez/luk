<!-- Copyright (c) 2026 Tim Menzies, MIT License https://opensource.org/licenses/MIT -->
<img align="right" src="https://img.shields.io/badge/Purpose-Tiny·Lua·Transpiler-7b68ee?logo=githubcopilot&logoColor=white" alt="Purpose"> <a href="https://timm.fyi"> <img align="right" src="https://img.shields.io/badge/Author-timm-dc143c?logo=readme&logoColor=white" alt="Author"></a> <img align="right" src="https://img.shields.io/badge/Language-Lua-000080?logo=lua&logoColor=white" alt="Language"><a href="https://choosealicense.com/licenses/mit/"> <img align="right" src="https://img.shields.io/badge/License-MIT-32cd32?logo=open-source-initiative&logoColor=white" alt="License"></a>

### [https://github.com/aiez/luc](https://github.com/aiez/luc)

`luc` is the **`.luc` language**: Lua plus `fn` for local
functions, `@` for return, `$` for local, `elif`, loop
auto-wrapping, and comprehensions. Blocks are Lua's own
(`then`/`do`/`end`), so any Lua is (almost) valid luc and every
`.luc` line maps 1:1 onto its generated Lua. One ~70-line
module, `luc.lua`, does whole-source transpilation; it is a pure
function, with no IO and no side effects.

```bash
git clone https://github.com/aiez/luc && cd luc
./luc fft.luc                 # transpile + run, args pass through
./luc -d fft.luc > fft.lua    # dump generated Lua
make fft.lua                  # same, via Makefile
```

For the optimizer shipped with luc (`fft.luc`) see [fft.md](fft.md).

**Sections:** [NAME](#name) | [SYNOPSIS](#synopsis) | [LANGUAGE REFERENCE](#language-reference) | [PERFORMANCE](#performance) | [FILES](#files) | [SEE ALSO](#see-also) | [LICENSE](#license) | [AUTHOR](#author)

**Files:** [luc.lua](https://github.com/aiez/luc#file-luc-lua) | [fft.luc](https://github.com/aiez/luc#file-fft-luc) | [lib.luc](https://github.com/aiez/luc#file-lib-luc) | [stats.luc](https://github.com/aiez/luc#file-stats-luc) | [tests.lua](https://github.com/aiez/luc#file-tests-lua) | [fft.md](https://github.com/aiez/luc#file-fft-md) | [luc.rc](https://github.com/aiez/luc#file-luc-rc)

## NAME

    luc - .luc-to-Lua transpiler (single-file, no deps)

Runs on Lua 5.1+, LuaJIT included. (The `luc` runner polyfills
`package.searchpath` and string-accepting `load`, which 5.1
lacks. `goto` labels pass through untouched but need 5.2+.)

## SYNOPSIS

    ./luc FILE.luc [args...]     # transpile + run
    ./luc -d FILE.luc            # dump generated Lua
    lua -e 'io.write(require"luc"(io.read"*a"))' <IN.luc >OUT.lua
    -- or programmatically:
    --   local luc = require("luc")
    --   local f   = assert(load(luc(src), "@foo.luc"))

`luc.lua` is only the transpiler. The `luc` runner adds a
`require()` hook, so `.luc` files can require each other:
`require"xx"` loads `xx.luc` if present (transpiled, with real
error line numbers), else falls back to plain Lua. The hook
searches `package.path` with `.lua` swapped for `.luc`, so
installed rocks work too. Pass `"@NAME.luc"` to `load` to keep
error lines pointing at the `.luc` source.

## LANGUAGE REFERENCE

Everything below is whole-source rewriting; strings and comments
are hidden first, so sigils inside them are safe. Every rewrite
stays on its own line, so generated Lua keeps the source's line
numbers exactly and error messages point at real `.luc` lines.

### Keywords

    elif               -> elseif

### Local and return

    $NAME = EXPR       -> local NAME = EXPR
    $A, B = X, Y       -> local A, B = X, Y
    $A, B              -> local A, B   (forward declaration)
    @EXPR              -> return EXPR

Lua uses neither `$` nor `@`, so local and return need no context
-- one rule each, no statement-position analysis, and `a ^ b` is
still exponentiation:

    fn double(z) @z * 2 end
    fn pick(b) if b then @"yes" else @"no" end end
    fn sd(t) @var(t) ^ 0.5 end

### Functions

**`fn` defaults to local.** A name after it gives Lua's `local
function`; with no name it is a plain anonymous `function`:

    fn NAME(...)       -> local function NAME(...)
    fn(...)            -> function(...)

Want a global? Write Lua's own `function`, which luc never
touches. Globals are then always deliberate, and the accidental
ones Lua is famous for cannot happen:

    fn sd(t) @var(t) ^ 0.5 end        -- local  (house style)
    function sd(t) @var(t) ^ 0.5 end  -- global (opt in)

Since `local function NAME` binds the name before the body, a
recursive function needs no forward declaration. Every other Lua
shape still works, on one line or many:

    $f = fn(a) @a + 1 end             -- local lambda
    sort(t, fn(a, b) @a.k < b.k end)  -- mid-expression
    fn nth(n) @fn(t) @t[n] end end    -- local, returns a closure
    t.m = fn(s) @s .. "!" end         -- table field (cannot be local)
    fn t:m(s) @s .. "!" end           -- same, method form
    $g = fn(a)                        -- multi-line
      $b = a * 2
      @b end

A name is needed for the `local` form, so a dotted or colon name
(`fn t.m(...)`, `fn t:m(...)`) falls through to `function` -- the
only thing Lua allows there.

### Loops

`for` auto-wraps its iterable the same way comprehensions do, so
one rule covers both:

    for V in ITER do              -> for _,V in ipairs(ITER) do
    for K, V in ITER do           -> for K, V in pairs(ITER) do
    for I, V in ipairs(ITER) do   -> untouched (has a "(")
    for I = 1, N do               -> untouched (numeric for)

Practical rule:

    - array, in order      -> for x in t       (1 var -> ipairs)
                              guaranteed 1..n, stops at first nil
    - dict, order moot     -> for k, v in t    (2 vars -> pairs)
    - array, need index    -> for i, x in ipairs(t)
                              written out; the "(" rule leaves it alone

`pairs` order is undefined (see Comprehensions below), so reach
for the 1-var form or explicit `ipairs` whenever order matters.

House style parks `end` at the end of the last body line:

    fn sign(x)                        local function sign(x)
      if x > 0 then @1                  if x > 0 then return 1
      elif x < 0 then @-1               elseif x < 0 then return -1
      else @0 end end                   else return 0 end end
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

  Limits:

    - The wrapper is chosen by comma count, not by what ITER
      holds. Two vars means `pairs`, whose order Lua leaves
      undefined: `{[1]=10,[2]=20,[3]=30}` yields keys 3,1,2 on
      Lua 5.5 and 1,2,3 on LuaJIT. For a list in order use one
      var (`ipairs`), or spell out `ipairs(ITER)` if you also
      need the index.
    - A dict comprehension's key expression must not contain a
      bare comma: `{f(a,b), v for ...}` splits at the wrong one.
    - Comprehensions do not nest. `[[y for y in r] for r in rows]`
      fails: the `for`/`in` split takes the *inner* `for`, so the
      outer one never forms. Name the inner one instead:

          fn each(r) @[y * 10 for y in r] end
          $x = [each(r) for r in rows]

### Gotchas

  - `elif` and `fn` are keywords everywhere: don't use them as
    variable names (or table keys like `{fn = 1}`).
  - `fn NAME(...)` is local. For a global, write Lua's own
    `function NAME(...)`.
  - `$` and `@` are sigils everywhere outside strings and
    comments, so a bare `$` cannot appear in code. In literals
    they are safe: `s:gsub("^%$DOOT", ...)` is untouched.
  - No compound assignment: write `x = x + 1`, not `x += 1`.
  - No shebang line in `.luc` files (load() rejects `#`).
  - Long strings/comments `[[...]]` and goto labels `::x::`
    pass through untouched.
  - Indentation is not significant; indent however you like.
  - `.luc` files carry a `ft=lua` modeline and Lua's own syntax
    covers them: only `fn`, `@`, `$` and comprehensions are
    foreign, and none of them upsets the parser.

## PERFORMANCE

Runtime, default mode (depth=4, 16 trees built):

    file       rows    fft.py   fft.lua  fft.luc (transpile+run)
    --------   -----   ------   ------   -----------------------
    auto93     398     0.080s   0.038s   0.035s
    SS-N      53663    9.18s    5.86s    6.15s

Lua 1.5x-2.5x faster than Python. Transpile is whole-source
gsubs, no line pass: ~1.2ms for a 250-line file, ~50ms for
10,000 lines. A .luc require costs ~1.7ms where the same .lua
parses in ~0.3ms, so transpiling is ~70% of it -- and still
negligible on any real workload.

## FILES

    luc.lua      .luc -> .lua transpiler (pure fn, no IO)
    tests.lua    transpiler regression tests (lua tests.lua)
    test_*.luc   lib/stats/fft checks (make tests, or
                 ./luc test_lib.luc [NAME...])
    luc          runner: .luc require() hook, transpile + run
    lib.luc      "battery": portable PRNG (srand/rand/any/shuffle),
                 o pretty-print, push, keys/order, nth/lt/gt,
                 keysort, slice, new, deepCopy, path, csv iterator,
                 sum, argmin, of, ...
    stats.luc    non-parametric stats: cliffsDelta, ks, sames,
                 pooledSd, topTier (requires "lib")
    fft.luc      example: multi-objective regression tree
    Makefile     rule:  %.lua: %.luc luc.lua
    sandbox/     luc2.lua: the retired v0.1 transpiler, 94 code
                 lines, with Python-style ":" blocks and indent
                 sensitivity. Dropped: measured against explicit
                 then/do/end it saved 3% of source bytes and zero
                 lines, for 26 lines of parser. Kept as history.

## SEE ALSO

    fft.md                   help page for the fft.luc app
    https://github.com/aiez/fft       Python sibling project
    https://github.com/aiez/optimiz   example CSVs
    https://github.com/aiez/konfig    shared Makefile

## LICENSE

    MIT. (c) 2026 Tim Menzies.

## AUTHOR

    Tim Menzies <timm@ieee.org>
