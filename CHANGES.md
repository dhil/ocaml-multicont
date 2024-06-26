# Multicont version 1.0.3 (latest)

This release restores compatibility with macOS (14.4.1) when using
clang 15 or greater.

Changes:

* Patch #8: Explicit declaration of `memcpy` to fix compilation error
  when using clang on macOS (thanks to @tmcgilchrist).
* Fixed a regression where enabling feature flag `UNIQUE_FIBERS`
  caused compilation to fail.
* Spring cleaning: Removed unused header imports.
* Added an example illustrating how to use the power of multishot
  continuation to simulate the `return` operator (e.g. as found in
  C/C++/Rust/etc) using a single handler.

# Multicont version 1.0.2

This release adds support for the anticipated release of OCaml 5.2.

Changes:

* Patch #7: OCaml 5.2 support (thanks to kit-ty-kate for the issue
  report #6; thanks to David Allsopp for reviewing the patch).  The
  change accounts for the new continuation representation.
* Added a basic testsuite runnable via `dune runtest`.
* Fixed a memory leak in the rollback parsing example.
* Added an entry about subtle interactions of unrestricted and linear
  effects in the "Cautionary tales" section of the README.

# Multicont version 1.0.1

This release is a purely administrative release which ports the build
infrastructure to [dune](https://github.com/ocaml/dune) in order to
resolve the reported build issues
(e.g. https://github.com/ocaml/opam-repository/pull/23972).

# Multicont version 1.0.0

To celebrate the recent stable release of OCaml 5, we release a stable
version of this library fully compatible with OCaml 5. The only change
between this version and the previous release candidates is that now
we use the stock OCaml 5 primitives to manage runtime stacks
(c.f. [caml/fiber.h](https://github.com/ocaml/ocaml/blob/trunk/runtime/caml/fiber.h)).

# Multicont version 1.0.0~rc.2

Release candidate 2 brings the fiber primitives of multicont in sync
with those in [OCaml trunk @
b4cfe16](https://github.com/ocaml/ocaml/commit/b4cfe1630263961ce0a9411197032b28c3ac1471).

# Multicont version 1.0.0~rc.1

This is release candidate 1 (and initial release) of the multicont
library for OCaml.

This release is compatible with the [OCaml 5.0 trunk @
7f7c0f5](https://github.com/ocaml/ocaml/commit/7f7c0f521b65874f5d102b5a4da14ae116203def)
and x64 architectures.
