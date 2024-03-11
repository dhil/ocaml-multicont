# Project root and build directory
ROOT:=$(shell dirname $(firstword $(MAKEFILE_LIST)))
BUILD_DIR:=$(ROOT)/_build

.PHONY: all
all: dune-project
	dune build --build-dir=$(BUILD_DIR)

.PHONY: install
install:
	dune install --build-dir=$(BUILD_DIR)

.PHONY: uninstall
uninstall:
	dune uninstall --build-dir=$(BUILD_DIR)

.PHONY: release
release:
	dune-release tag v1.0.2
	dune-release distrib
	dune-release publish
	dune-release opam pkg
	dune-release opam submit

.PHONY: test
test:
	dune build @runtest

# Clean up rule
.PHONY: clean
clean:
	dune clean --build-dir=$(BUILD_DIR)
	echo -n "; intentionally left empty" > test/tests.inc
