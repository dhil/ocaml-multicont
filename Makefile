# Project root and build directory
ROOT:=$(shell dirname $(firstword $(MAKEFILE_LIST)))
BUILD_DIR:=$(ROOT)/_build

# The build command and some standard build system flags
CAML_BUILD=dune build
CAML_SOURCES=multicont
# Note: this relies on lazy expansion of `SOURCES'.
CAML_COMMON_FLAGS=--only-packages $(SOURCES) --build-dir=$(BUILD_DIR)
CAML_DEV_FLAGS=$(COMMON_FLAGS) --profile=dev
CAML_REL_FLAGS=$(COMMON_FLAGS) --profile=release
CAML_CI_FLAGS=$(COMMON_FLAGS) --profile=ci
# List of packages that we currently release
CAML_RELEASE_PKGS:=$(SOURCES)

# The default is to build everything in development mode.
.DEFAULT_GOAL:= all
.PHONY: all
all: build-dev-all

# Invokes `dune' to build everything in continuous integration mode.
.PHONY: build-ci-all
build-ci-all: dune dune-project
	$(CAML_BUILD) $(CAML_CI_FLAGS) @install

# Invokes `dune' to build everything in development mode.
.PHONY: build-dev-all
build-dev-all: dune dune-project
	$(CAML_BUILD) $(CAML_DEV_FLAGS) @install

# Invokes `dune' to build everything in release mode.
.PHONY: build-release-all
build-release-all: dune dune-project
	$(CAML_BUILD) $(CAML_REL_FLAGS) @install

.PHONY: clean
clean:
	dune clean
