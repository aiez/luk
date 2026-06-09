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

# ---- pdf via konfig's ~/tmp/%.pdf rule -----------------------------
# Inject lua.ssh content into env var LUASSH; konfig writes it to a
# temp ~/.a2ps/lua.ssh and invokes a2ps --pretty-print=lua.
export LUASSH := $(file < $(HOME)/gits/timm/lua/etc/lua.ssh)
SSH := LUASSH
