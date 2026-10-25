# Releases upstream WebAssembly builds, unmodified, with their licence files.
#
#   nix-shell -p curl unzip --run make
#
# Each upstream archive is pinned by sha256 in sources.lock. Every module is
# copied without modification and stays under its upstream licence; only the
# file names change, so that one release can hold them all.
# `make clean` removes build/ and dist/.

CURL ?= curl -fL

LOCK := sources.lock
DOWNLOADS := build/downloads
DIST := dist
MODULES := pandoc.wasm harper.wasm
FILES := $(MODULES) pandoc-COPYING.md pandoc-COPYRIGHT harper-LICENSE

# lock_field NAME COLUMN prints one column of the sources.lock row called NAME.
lock_field = $(shell awk -v n='$(1)' '$$1 == n { print $$$(2) }' $(LOCK))

.PHONY: all release clean

.SECONDARY:

all: $(addprefix $(DIST)/,$(FILES)) $(DIST)/SHA256SUMS

# Download an archive, refuse it unless its sha256 matches sources.lock.
$(DOWNLOADS)/%:
	mkdir -p $(@D)
	$(CURL) -o $@.part '$(call lock_field,$*,2)'
	got=$$(sha256sum $@.part | cut -d' ' -f1); \
	want='$(call lock_field,$*,3)'; \
	if [ "$$got" != "$$want" ]; then rm -f $@.part; echo "$*: sha256 $$got does not match sources.lock" >&2; exit 1; fi
	mv $@.part $@

# Pandoc's official WebAssembly build, from its release.
build/pandoc: $(DOWNLOADS)/pandoc-wasm
	rm -rf $@ && mkdir -p $@
	unzip -j -o $< pandoc-wasm/pandoc.wasm pandoc-wasm/COPYING.md pandoc-wasm/COPYRIGHT -d $@

# Harper's slim wasm, from the harper.js npm package. The package's JavaScript
# glue only works with the wasm of the same release, so LibrePaper pins both
# to the same version.
build/harper: $(DOWNLOADS)/harper-js
	rm -rf $@ && mkdir -p $@
	tar -xzf $< -C $@ --strip-components=1 package/LICENSE package/dist/harper_wasm_slim_bg.wasm

$(DIST)/pandoc.wasm: build/pandoc
	mkdir -p $(@D) && cp $</pandoc.wasm $@
$(DIST)/pandoc-COPYING.md: build/pandoc
	mkdir -p $(@D) && cp $</COPYING.md $@
$(DIST)/pandoc-COPYRIGHT: build/pandoc
	mkdir -p $(@D) && cp $</COPYRIGHT $@
$(DIST)/harper.wasm: build/harper
	mkdir -p $(@D) && cp $</dist/harper_wasm_slim_bg.wasm $@
$(DIST)/harper-LICENSE: build/harper
	mkdir -p $(@D) && cp $</LICENSE $@

$(DIST)/SHA256SUMS: $(addprefix $(DIST)/,$(MODULES))
	cd $(DIST) && sha256sum $(MODULES) > SHA256SUMS

# Usage: make release TAG=vX.Y.Z. Bump the version whenever any upstream changes.
release: all
	@test -n "$(TAG)" || { echo "usage: make release TAG=vX.Y.Z" >&2; exit 1; }
	gh release create $(TAG) --repo LibrePaper/wasm-upstream --title $(TAG) \
		--notes "Upstream WebAssembly builds, unmodified. pandoc.wasm is Pandoc 3.12.1, GPL-2.0-or-later (pandoc-COPYING.md, pandoc-COPYRIGHT), source https://github.com/jgm/pandoc/releases/tag/3.12.1. harper.wasm is the slim wasm of harper.js 2.13.0, Apache-2.0 (harper-LICENSE), source https://github.com/Automattic/harper. See sources.lock for the pinned archives." \
		$(addprefix $(DIST)/,$(FILES)) $(DIST)/SHA256SUMS

clean:
	rm -rf build $(DIST)
