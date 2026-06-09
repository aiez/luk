# vim: ts=2 sw=2 sts=2 et :
# knobs only; shared targets live in $(KONFIG)/Makefile
KONFIG ?= ../konfig

APP   := funny
MAIN  := fft.fun
EXT   := fun
LANG  := lua
LINT  := true
TOOLS := lua:run-lua
PKG   := lua gawk neovim tmux

$(KONFIG)/Makefile:
	@test -f $@ || { echo "missing konfig: git clone http://tiny.cc/konfig $(KONFIG)"; exit 1; }
-include $(KONFIG)/Makefile

# ---- transpile rule -----------------------------------------------
# .fun -> .lua via funny.lua library (returns transpile function)
%.lua: %.fun funny.lua
	lua -e 'io.write(require("funny")(io.read("*a")))' < $< > $@

# ---- funny shell: konfig bashrc + funny.rc (vi w/ .fun mode) ------
fsh: ## funny tuned bash (konfig bashrc + funny.rc overlay)
	$(call need,nvim,fsh)
	$(call need,git,fsh)
	$(call konfig)
	@KONFIG=$(abspath $(KONFIG)) APP=$(APP) MAIN=$(MAIN) BANNER=$(abspath $(BANNER)) \
	 bash --rcfile <(cat $(KONFIG)/bashrc funny.rc) -i
