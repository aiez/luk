<!-- Copyright (c) 2026 Tim Menzies, MIT License https://opensource.org/licenses/MIT -->

# fft - fast-frugal multi-objective tree

Smallest useful AI/XAI optimization tool. Builds a tiny regression
tree from CSV via greedy min-variance cuts on incremental
Welford μ/σ stats. Written in `.fun` (see [,funny.md](,funny.md)
for the language).

```bash
git clone http://tiny.cc/optimiz && git clone http://tiny.cc/funny
cd funny && make fft.lua lib.lua
lua fft.lua -f ../optimiz/auto93.csv
```

## NAME

    fft - fast-frugal multi-objective regression tree

## SYNOPSIS

    make fft.lua lib.lua                    # transpile
    lua fft.lua [-flag VAL]... [--TEST]     # run

## OPTIONS

    -b bins     numeric bin count            (7)
    -d depth    max tree depth               (4)
    -s seed     random seed                  (1234567891)
    -p p        distance exponent            (2)
    -R Round    display decimals             (2)
    -f file     data file                    (../optimiz/auto93.csv)

CLI overrides match by first letter of each key in `the` table.

## DATA

    CSV with header row. Column-name first/last char encodes:

      first char UPPER  -> numeric column (Num)
      first char lower  -> symbolic column (Sym)
      suffix '+'        -> numeric goal, maximize
      suffix '-'        -> numeric goal, minimize
      suffix '!'        -> symbolic goal (klass)
      suffix 'X'        -> ignore
      else              -> predictor

    Missing values: '?'.

    Example header:

      Clndrs,Volume,HpX,Model,origin,Lbs-,Acc+,Mpg+

## MODES

    (default)    train on -f, tune, show best tree
    --trees      enumerate all candidate trees + err

## TREE OUTPUT

    Each non-leaf line:

      if <col OP val>      then d2h <mean> n=<count>

    Leaf line:

      (indent)             leaf  d2h <mean> n=<count>

    d2h = distance to heaven (lower = better).

## INTERNALS

    Sym  = {symp=true, has={}}             -- value -> count
    Num  = {nump=true, n, mu, m2}          -- Welford running stats
    Data = {names, x, y, goal, cols, rows} -- no metatable

    Helpers in lib.fun:
      argmin, argmax, sum, mean, sort, keys
      of (string -> number/bool/string)
      csv (file -> list of rows)
      abs, max, min, sqrt, exp, floor (math aliases)

## EXIT

    0  success
    >0 Lua error (transpile or runtime)

## SEE ALSO

    ,funny.md                .fun language reference
    http://tiny.cc/semble    Python sibling
    http://tiny.cc/optimiz   example CSVs

## LICENSE

    MIT. (c) 2026 Tim Menzies.

## AUTHOR

    Tim Menzies <timm@ieee.org>
