<!-- Copyright (c) 2026 Tim Menzies, MIT License https://opensource.org/licenses/MIT -->
<img xalign="right" src="https://img.shields.io/badge/Purpose-Tiny·Lua·Transpiler-7b68ee?logo=githubcopilot&logoColor=white" alt="Purpose"> <a href="https://timm.fyi"> <img xalign="right" src="https://img.shields.io/badge/Author-timm-dc143c?logo=readme&logoColor=white" alt="Author"></a> <img xalign="right" src="https://img.shields.io/badge/Language-Lua-000080?logo=lua&logoColor=white" alt="Language"><a href="https://choosealicense.com/licenses/mit/"> <img xalign="right" src="https://img.shields.io/badge/License-MIT-32cd32?logo=open-source-initiative&logoColor=white" alt="License"></a>

### [http://tiny.cc/luk](http://tiny.cc/luk)

<a href="http://tiny.cc/luk"><img align="right" src="https://tiny.cc/tiny/qr-image/tiny.cc~luk~l~150.png" alt="QR"></a>

`luk` is the **`.luk` language**: a tiny indentation-based dialect that transpiles to Lua via `luk.lua` (~100-line module). `luk.lua` returns a single function: `local lua_src = require("luk")(fun_src)`. Same Lua semantics, fewer `end`s, Python-style list comprehensions.

```bash
git clone http://tiny.cc/luk && cd luk
# transpile (luk.lua is a module; one-liner driver):
lua -e 'io.write(require("luk")(io.read("*a")))' < my.luk > my.lua
lua my.lua                            # run
make my.lua                           # via Makefile
```

For the optimizer shipped with luk (`fft.luk`) see [fft.md](fft.md).

## NAME

    luk - .luk-to-Lua transpiler (single-file, no deps)

## SYNOPSIS

    lua -e 'io.write(require"luk"(io.read"*a"))' <IN.luk >OUT.lua
    -- or programmatically:
    --   local lua_src = require("luk")(fun_src)

## LANGUAGE REFERENCE

### Keywords (whole-word substitution)

    fun                -> function
    !                  -> return
    !=                 -> ~=     (Lua's not-equal)

### Local declarations

    NAME := EXPR       -> local NAME = EXPR
    A, B := X, Y       -> local A, B = X, Y

### Compound assignment (start of line)

    X += V             -> X = X + V
    X -= V             -> X = X - V
    X *= V             -> X = X * V
    X /= V             -> X = X / V

### Block openers (use ":" at EOL or before body)

    if (cond):         -> if cond then
    elseif (cond):     -> elseif cond then
    else:              -> else
    for X in Y:        -> for X in Y do
    for i = a, b:      -> for i = a, b do
    while cond:        -> while cond do
    fun (args):        -> function(args)
    NAME := fun (a):   -> local NAME = function(a)

### Block bodies

  - Same line after `:` = one-liner, auto-appends ` end`.
  - Indented next lines = multi-line; outdent emits ` end`.
  - Continuation lines starting with `else`/`elseif`
    do NOT trigger the outdent close.
  - Lone ` end` lines are folded onto the previous code line
    (skipping blank lines and comments).
  - Inline anonymous `fun` in expressions needs explicit `end`:

        cb := fun (x): ! x*2 end

### List comprehensions (Python-style, inside `[ ]`)

    [EXPR for V in ITER]
    [EXPR for V in ITER if COND]
    [EXPR for K,V in ITER]            -- 2 loop vars -> pairs

  ITER auto-wrapping inside comprehensions:

    - 1 var, no "(" in ITER  -> ipairs(ITER)
    - 2 vars, no "(" in ITER -> pairs(ITER)
    - else passed through as-is

### Misc

  - Strings/comments are hidden during substitution, so sigils
    inside them are safe: `print("hi!")` stays untouched.
  - Shebang `#!...` at top is rewritten to `--...`.

## PERFORMANCE

Runtime, default mode (depth=4, 16 trees built):

    file       rows    fft.py   fft.lua  fft.luk (transpile+run)
    --------   -----   ------   ------   -----------------------
    auto93     398     0.080s   0.032s   0.039s
    SS-N      53663    9.18s    6.24s    6.11s

Lua 1.5x-2.5x faster than Python. Transpile overhead ~7ms
(constant, negligible on any real workload).

## FILES

    luk.lua      .luk -> .lua transpiler (filter)
    lib.luk      "battery" helpers (argmin, sum, csv, of, ...)
    fft.luk      example: multi-objective regression tree
    Makefile     rule:  %.lua: %.luk luk.lua

## VIM SUPPORT

    syntax: http://tiny.cc/timm-lua  -> etc/syntax/luk.vim
    nvim init at etc/nvimluk.lua.

## SEE ALSO

    fft.md                   help page for the fft.lua app
    http://tiny.cc/semble    Python sibling project
    http://tiny.cc/optimiz   example CSVs
    http://tiny.cc/konfig    shared Makefile

## LICENSE

    MIT. (c) 2026 Tim Menzies.

## AUTHOR

    Tim Menzies <timm@ieee.org>
