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

# Clean up rule
.PHONY: clean
clean:
	dune clean --build-dir=$(BUILD_DIR)
