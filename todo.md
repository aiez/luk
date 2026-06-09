# TODO

## PDF printing broken

`make ~/tmp/fft.pdf` falls back to plain style — no Lua syntax color.

Root cause: GNU Make 3.81 (macOS default) lacks `$(file < FILE)` (added
in Make 4.0). The `export LUASSH := $(file < lua.ssh)` returns empty,
so konfig's pdf rule writes an empty `lua.ssh` and a2ps errors out.

**Fixes (pick one):**

- Install newer Make (`brew install make`, use `gmake`).
- Read lua.ssh in the recipe via shell, not Make's `$(file ...)`:

      $(HOME)/tmp/%.pdf: %.luk
          LUASSH="$$(cat $(LUK_SSH))" $(MAKE) -f $(KONFIG)/Makefile $@

- Symlink/copy `lua.ssh` system-wide:

      sudo cp $(HOME)/gits/timm/lua/etc/lua.ssh \
        /opt/homebrew/opt/a2ps/share/a2ps/sheets/

## ,luk.md doc audit

- [x] tiny.cc/fun -> tiny.cc/luk URLs
- [x] "fun -" title -> "luk -"
- [ ] verify SYNOPSIS code blocks all use `luk` (not `funny`)
- [ ] VIM SUPPORT section: confirm `luk.vim` path is correct

## a2ps rule cleanup

- Konfig's `~/tmp/%.pdf` rule needs `EXT=luk` + `LANG=lua` AND a
  populated `SSH=VARNAME` where the env var contains the .ssh body.
  Currently failing — see above.
