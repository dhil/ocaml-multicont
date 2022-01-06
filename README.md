# Multicont: Continuations with multi-shot semantics in OCaml

This library provides a thin abstraction on top of OCaml's regular
linear continuations that enables programming with multi-shot
continuations, i.e. continuations that can be applied more than once.

## Installing the library

The library can be installed via [OPAM](https://opam.ocaml.org/). At
the time of writing the library is not yet available in the stock OPAM
repository, until it is available the best way to install the library
is by pinning it, e.g.

```
$ opam pin multicont git@github.com:dhil/ocaml-multicont.git
```

## The multi-shot continuations interface

This library is designed to be used in tandem with the
`EffectHandlers` module, which provides the API for regular linear
continuations. The structure of this library mirrors that of
`EffectHandlers` as it provides submodules for the `Deep` and
`Shallow` variations of continuations. This library intentionally uses
a slightly different terminology than `EffectHandlers` in order to
allow both libraries to be opened in the same scope. For example, this
library uses the terminology `resumption` in place of `continuation`.

To obtain a multi-shot continuation, one must first have a regular
linear continuation at hand.

```ocaml
val promote : ('a, 'b) continuation -> ('a, 'b) resumption
```

This function converts a linear continuation into a multi-shot
resumption. One can apply a resumption via either

```ocaml
(* Deep application *)
val resume : ('a, 'b) resumption -> 'a -> 'b

(* Shallow application *)
val resume_with : ('a, 'b) resumption -> 'a -> ('b, 'c) EffectHandlers.Shallow.handler -> 'c
```

These functions are analogous to the `continue` and `continue_with`
functions from the `EffectHandlers` module.

Similarly, one can abort a resumption via either

```ocaml
(* Deep abort *)
val abort : ('a, 'b) resumption -> exn -> b

(* Shallow abort *)
val abort_with : ('a, 'b) resumption -> exn -> ('b, 'c) EffectHandlers.Shallow.handler -> 'c
```

Again, these correspond to `discontinue` and `discontinue_with` from
the `EffectHandlers` module. It is worth remarking that it is possible
to resume a resumption after an application of `abort` or `abort_with`
as these functions only destroy a single copy of the
continuation. In order to destroy all copies one must apply

```ocaml
val drop : ('a, 'b) resumption -> unit
```

Although, do note that `drop` will not clean up any acquired resources
that may be captured by the continuation.

One can recover a regular linear continuation by supplying a
resumption to

```ocaml
val demote : ('a, 'b) resumption -> ('a, 'b) continuation
```

This function renders the provided resumption unusable and instead
returns a single use continuation.


## Programming with multi-shot continuations

TODO

## Notes on the implementation

Under the hood the library uses regular linear OCaml continuation and
a variation of `clone_continuation` that used to reside in the `Obj`
module of earlier versions of Multicore OCaml. Internally, the
`resumption` types are aliases of the respective `continuation` types
from the `EffectHandlers` module. The ability to resume a continuation
more than once is achieved by cloning the original continuation on
demand. The key functions `resume`, `resume_with`, `abort`, and
`abort_with` all clone the provided continuation argument and invoke
the resulting clone rather than the original continuation. The library
guarantees that the original continuation remains cloneable as the
call `promote k` deattaches the stack embedded in the continuation
object `k`, meaning that the programmer cannot inadvertently destroy
the stack by a call to `continue`.


## Acknowledgements

This library includes snippets of code that is originally written by
KC Sivaramakrishnan, Tom Kelly, and Stephen Dolan. See the file
[fiber_primitives.c](https://github.com/dhil/ocaml-multicont/blob/master/fiber_primitives.c)
for the details.
