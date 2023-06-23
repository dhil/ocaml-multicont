# Multicont version 1.0.1 (latest)

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
