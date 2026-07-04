# TODO

## PDF printing (FIXED locally, konfig still affected)

Was: `make ~/tmp/fft.pdf` / `make ~/tmp/konfig/fft.pdf` fell back
to plain style. GNU Make 3.81 (macOS default) lacks the `$(file <)`
konfig's SSH env-var scheme relies on.

Fixed in luk's Makefile: local pattern rules for BOTH pdf targets
use `--pretty-print=lua.ssh` (cwd file) directly; shared
`pdf_recipe` define. Konfig's own SSH scheme still needs Make >= 4
for other repos.

## ,luk.md doc audit

- [x] tiny.cc/fun -> https://github.com/aiez/luk URLs
- [x] "fun -" title -> "luk -"
- [ ] verify SYNOPSIS code blocks all use `luk` (not `funny`)
- [ ] VIM SUPPORT section: confirm `luk.vim` path is correct

## a2ps rule cleanup

- Konfig's `~/tmp/%.pdf` rule needs `EXT=luk` + `LANG=lua` AND a
  populated `SSH=VARNAME` where the env var contains the .ssh body.
  Currently failing — see above.
