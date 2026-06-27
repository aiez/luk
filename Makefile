# vim: ts=2 sw=2 sts=2 et :
# knobs only; shared targets live in $(KONFIG)/Makefile
KONFIG ?= ../konfig

APP   := luk
MAIN  := fft.luk
EXT   := luk
LANG  := lua
LINT  := true
TOOLS := lua:run-lua
PKG   := lua gawk neovim tmux

$(KONFIG)/Makefile:
	@test -f $@ || { echo "missing konfig: git clone https://github.com/aiez/konfig $(KONFIG)"; exit 1; }
include $(KONFIG)/Makefile

# ---- transpile rule -----------------------------------------------
# .luk -> .lua via luk.lua library (returns transpile function)
%.lua: %.luk luk.lua
	lua -e 'io.write(require("luk")(io.read("*a")))' < $< > $@

# ---- luk shell: konfig bashrc + luk.rc (vi w/ .luk mode) ------
fsh: ## luk tuned bash (konfig bashrc + luk.rc overlay)
	$(call need,nvim,fsh)
	$(call need,git,fsh)
	$(call konfig)
	@KONFIG=$(abspath $(KONFIG)) APP=$(APP) MAIN=$(MAIN) BANNER=$(abspath $(BANNER)) \
	 bash --rcfile <(cat $(KONFIG)/bashrc luk.rc) -i

# ---- pdf: override konfig's rule, use full path to lua.ssh --------
# Works under GNU Make 3.81 (macOS default) which lacks $(file ...).
LUK_SSH ?= lua.ssh
Cols    ?= 2
Font    ?= 9
Orient  ?= landscape

$(HOME)/tmp/%.pdf: %.luk
	@mkdir -p $(HOME)/tmp
	@echo "pdfing : $@ ..."
	@a2ps -Bj --$(Orient) --line-numbers=1 --highlight-level=heavy \
	      --borders=no --pro=color \
	      --left-footer="" --right-footer="" --footer="page %p." \
	      --pretty-print=$(LUK_SSH) -M letter \
	      --font-size=$(Font) --columns=$(Cols) \
	      -o - $< 2> >(grep -v '^a2ps:/' >&2) \
	  | ps2pdf - $@
	@echo "wrote $@"
	@open $@
