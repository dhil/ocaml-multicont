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
	dune-release tag v1.0.1 --build-dir=$(BUILD_DIR)
	dune-release distrib --build-dir=$(BUILD_DIR)
	dune-release publish distrib --build-dir=$(BUILD_DIR)
	dune-release opam pkg --build-dir=$(BUILD_DIR)
	dune-release opam submit --build-dir=$(BUILD_DIR)

.PHONY: test
test:
	dune runtest

# Clean up rule
.PHONY: clean
clean:
	dune clean --build-dir=$(BUILD_DIR)
