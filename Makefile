# vim: ts=2 sw=2 sts=2 et :
# knobs only; shared targets live in $(KONFIG)/Makefile
KONFIG ?= ../konfig

APP   := luc
MAIN  := fft.luc
EXT   := luc
LANG  := lua
LINT  := true
TOOLS := lua:run-lua
PKG   := lua gawk neovim tmux

$(KONFIG)/Makefile:
	@test -f $@ || { echo "missing konfig: git clone https://github.com/aiez/konfig $(KONFIG)"; exit 1; }
include $(KONFIG)/Makefile

# ---- transpile rule -----------------------------------------------
# .luc -> .lua via luc.lua library (returns transpile function)
%.lua: %.luc luc.lua
	lua -e 'io.write(require("luc")(io.read("*a")))' < $< > $@

# ---- tests ---------------------------------------------------------
tests: ## transpiler tests, then lib/stats/fft checks
	lua tests.lua
	./luc test_lib.luc
	./luc test_stats.luc
	./luc test_fft.luc

# ---- luc shell: konfig bashrc + luc.rc (vi w/ .luc mode) ------
fsh: ## luc tuned bash (konfig bashrc + luc.rc overlay)
	$(call need,nvim,fsh)
	$(call need,git,fsh)
	$(call konfig)
	@KONFIG=$(abspath $(KONFIG)) APP=$(APP) MAIN=$(MAIN) BANNER=$(abspath $(BANNER)) \
	 bash --rcfile <(cat $(KONFIG)/bashrc luc.rc) -i

# ---- pdf: override konfig's rule, use full path to lua.ssh --------
# Works under GNU Make 3.81 (macOS default) which lacks $(file ...).
LUC_SSH ?= lua.ssh
Cols    ?= 2
Font    ?= 9
Orient  ?= landscape

define pdf_recipe
@mkdir -p $(@D)
@echo "pdfing : $@ ..."
@a2ps -Bj --$(Orient) --line-numbers=1 --highlight-level=heavy \
      --borders=no --pro=color \
      --left-footer="" --right-footer="" --footer="page %p." \
      --pretty-print=$(LUC_SSH) -M letter \
      --font-size=$(Font) --columns=$(Cols) \
      -o - $< 2> >(grep -v '^a2ps:/' >&2) \
  | ps2pdf - $@
@echo "wrote $@"
@open $@
endef

$(HOME)/tmp/%.pdf: %.luc
	$(pdf_recipe)

# also claim konfig's ~/tmp/konfig/%.pdf target (its SSH env-var
# scheme needs Make >= 4.0; this uses the local lua.ssh instead)
$(HOME)/tmp/konfig/%.pdf: %.luc
	$(pdf_recipe)
