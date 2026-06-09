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
	@test -f $@ || { echo "missing konfig: git clone http://tiny.cc/konfig $(KONFIG)"; exit 1; }
-include $(KONFIG)/Makefile

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

# ---- pdf via a2ps using shared lua.ssh sheet ----------------------
# .luk has no native a2ps sheet; reuse lua.ssh (treat .luk as Lua-ish)
SSH_DIR ?= $(HOME)/gits/timm/lua/etc
A2PS_OPT ?= --no-default-settings --landscape --columns=2 \
            --font-size=9 --line-numbers=1 --pretty-print=lua

$(HOME)/tmp/%.pdf: %.luk
	@mkdir -p $(HOME)/tmp
	@TMP=$$(mktemp -d) && \
	  a2ps $(A2PS_OPT) --style-sheet-path=$(SSH_DIR) \
	       -o $$TMP/$*.ps $< && \
	  ps2pdf $$TMP/$*.ps $@ && rm -rf $$TMP
	@echo "wrote $@"
