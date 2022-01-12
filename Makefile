# Project root and build directory
ROOT:=$(shell dirname $(firstword $(MAKEFILE_LIST)))
BUILD_DIR:=$(ROOT)/_build

# Common compilation flags
DLLPATH=.
NATIVE_CFLAGS=-ccopt -DNATIVE_CODE
OCFLAGS=-strict-formats -strict-sequence -safe-string -bin-annot -warn-error -a

# Installation configuration
STUBLIBS=$(shell opam var stublibs)
LIB=$(shell opam var lib)
INSTDIR=$(LIB)/multicont
VERSION=

.DEFAULT_GOAL: all
.PHONY: all
all: byte native

# Build byte code compatible library
.PHONY: byte
byte: multicont.cmo libmulticont.a
	ocamlmklib -o multicont -oc multicont -dllpath $(DLLPATH) multicont.cmo

libmulticont.a: fiber_primitives.o-byte multicont_stubs.o-byte
	ocamlmklib -oc multicont -dllpath $(DLLPATH) fiber_primitives.o multicont_stubs.o

multicont.cmo: multicont.mli multicont.ml
	ocamlc -c $(OCFLAGS) multicont.mli multicont.ml

.PHONY: fiber_primitives.o-byte
fiber_primitives.o-byte: fiber_primitives.h fiber_primitives.c
	ocamlc -c fiber_primitives.c

.PHONY: multicont_stubs.o-byte
multicont_stubs.o-byte: fiber_primitives.o multicont_stubs.c
	ocamlc -c multicont_stubs.c

# Build native code compatible library
.PHONY: native
native: multicont.cmx libmulticontopt.a
	ocamlmklib -o multicont -oc multicontopt -dllpath $(DLLPATH) multicont.cmx

libmulticontopt.a: fiber_primitives.o-native multicont_stubs.o-native
	ocamlmklib -oc multicontopt -dllpath $(DLLPATH) fiber_primitives.o multicont_stubs.o

multicont.cmx: multicont.mli multicont.ml
	ocamlopt -c $(OCFLAGS) multicont.mli multicont.ml

.PHONY: fiber_primitives.o-native
fiber_primitives.o-native: fiber_primitives.h fiber_primitives.c
	ocamlopt -c $(NATIVE_CFLAGS) fiber_primitives.c

.PHONY: multicont_stubs.o-native
multicont_stubs.o-native: fiber_primitives.o multicont_stubs.c
	ocamlopt -c $(NATIVE_CFLAGS) multicont_stubs.c

# Install the library into OPAM
install:
	if test -d $(LIB); then \
		mkdir -p $(INSTDIR); \
		cp multicont.mli $(INSTDIR); \
		if test -f multicont.cmi; then cp multicont.cmi $(INSTDIR); fi; \
		if test -f dllmulticont.so \
	        && test -f libmulticont.a \
	        && test -f multicont.cma; then \
			cp dllmulticont.so $(STUBLIBS); \
			cp libmulticont.a multicont.cma $(INSTDIR); fi; \
		if test -f dllmulticontopt.so \
	        && test -f libmulticontopt.a \
                && test -f multicont.a \
                && test -f multicont.cmx \
	        && test -f multicont.cmxa; then \
			cp dllmulticontopt.so $(STUBLIBS); \
			cp libmulticontopt.a multicont.a multicont.cmx multicont.cmxa $(INSTDIR); fi; \
		if test -f multicont.cmt; then cp multicont.cmt $(INSTDIR); fi; \
		if test -f multicont.cmti; then cp multicont.cmti $(INSTDIR); fi; fi
	if test -f $(INSTDIR)/libmulticont.a; then cd $(INSTDIR) && ranlib libmulticont.a; fi
	if test -f $(INSTDIR)/libmulticontopt.a; then cd $(INSTDIR) && ranlib libmulticontopt.a; fi

.PHONY: META
META:
	echo "version = \"$(VERSION)\"\n\
description = \"\"\n\
requires = \"\"\n\
archive(byte) = \"multicont.cma\"\n\
archive(native) = \"multicont.cmxa\"" > $(INSTDIR)/META

.PHONY: dune-package
dune-package:
	echo "(lang dune 2.9)\n\
(name multicont)\n\
(version $(VERSION))\n\
(library\n\
 (name multicont)\n\
 (kind normal)\n\
 (archives (byte multicont.cma) (native multicont.cmxa))\n\
 (native_archives multicont.a)\n\
 (main_module_name Multicont)\n\
 (modes byte native)\n\
 (modules\n\
  (singleton (name Multicont) (obj_name multicont) (visibility public) (impl))))" > $(INSTDIR)/dune-package

uninstall:
	rm -rf $(INSTDIR)
	rm -f $(STUBLIBS)/dllmulticontopt.so $(STUBLIBS)/dllmulticont.so

.PHONY: clean
clean:
	rm -f *.so *.o *.a
	rm -f *.cmo *.cmx *.cma *.cmxa *.cmi *.cmt *.cmti
