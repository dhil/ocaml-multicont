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
The signature file [multicont.mli](https://github.com/dhil/ocaml-multicont/blob/master/multicont.mli) contains the interface for this library, which I have inlined below:

```ocaml
exception Resumption_already_dropped

module Deep: sig

  type ('a, 'b) resumption

  val promote : ('a, 'b) EffectHandlers.Deep.continuation -> ('a, 'b) resumption
  (** [promote k] converts a regular linear deep continuation to a multi-shot deep
      resumption. This function fully consumes the supplied the continuation [k]. *)

  val demote : ('a, 'b) resumption -> ('a, 'b) EffectHandlers.Deep.continuation
  (** [demote r] converts a deep multi-shot resumption into a linear
      deep continuation. The argument [r] is fully consumed, making
      further invocations of [r] impossible. *)

  val resume : ('a, 'b) resumption -> 'a -> 'b
  (** [resume r v] reinstates the context captured by the multi-shot
      deep resumption [r] with value [v].
      @raises Resumption_already_dropped if the resumption has been dropped. *)

  val abort  : ('a, 'b) resumption -> exn -> 'b
  (** [abort r e] injects the exception [e] into the context captured
      by the multi-shot deep resumption [r].
      @raises Resumption_already_dropped if the resumption has been dropped. *)

  val drop : ('a, 'b) resumption -> unit
  (** [drop r] fully consumes the multi-shot deep resumption [r],
      making further invocations of [r] impossible. *)

  (* Primitives *)
  val clone_continuation : ('a, 'b) EffectHandlers.Deep.continuation -> ('a, 'b) EffectHandlers.Deep.continuation
  (** [clone_continuation k] clones the linear deep continuation [k]. The
      supplied continuation is *not* consumed. *)

  val drop_continuation : ('a, 'b) EffectHandlers.Deep.continuation -> unit
  (** [drop_continuation k] deallocates the memory occupied by the
      continuation [k]. Note, however, that this function does not clean
      up acquired resources captured by the continuation. In order to
      delete the continuation and free up the resources the programmer
      should instead use `discontinue` from the [EffectHandlers.Deep]
      module. *)
end

module Shallow: sig

  type ('a, 'b) resumption

  val promote : ('a, 'b) EffectHandlers.Shallow.continuation -> ('a, 'b) resumption
 (** [promote k] converts a regular linear shallow continuation to a multi-shot shallow
     resumption. This function fully consumes the supplied the continuation [k]. *)

  val demote : ('a, 'b) resumption -> ('a, 'b) EffectHandlers.Shallow.continuation
 (** [demote r] converts a shallow multi-shot resumption into a linear
     shallow continuation. The argument [r] is fully consumed, making
     further invocations of [r] impossible. *)

  val resume_with : ('a, 'b) resumption -> 'a -> ('b, 'c) EffectHandlers.Shallow.handler -> 'c
  (** [resume r v h] reinstates the context captured by the multi-shot
      shallow resumption [r] with value [v] under the handler [h].
      @raises Resumption_already_dropped if the resumption has been dropped. *)

  val abort_with  : ('c, 'a) resumption -> exn -> ('a, 'b) EffectHandlers.Shallow.handler -> 'b
  (** [abort r e h] injects the exception [e] into the context captured
      by the multi-shot shallow resumption [r] under the handler [h].
      @raises Resumption_already_dropped if the resumption has been dropped. *)

  val drop : ('a, 'b) resumption -> unit
  (** [drop r] fully consumes the multi-shot shallow resumption [r],
      making further invocations of [r] impossible. *)

  (* Primitives *)
  val clone_continuation : ('a, 'b) EffectHandlers.Shallow.continuation -> ('a, 'b) EffectHandlers.Shallow.continuation
  (** [clone_continuation k] clones the linear shallow continuation [k]. The
      supplied continuation is *not* consumed. *)

  val drop_continuation : ('a, 'b) EffectHandlers.Shallow.continuation -> unit
  (** [drop_continuation k] deallocates the memory occupied by the
      continuation [k]. Note, however, that this function does not clean
      up acquired resources captured by the continuation. In order to
      delete the continuation and free up the resources the programmer
      should instead use [discontinue_with] from the
      [EffectHandlers.Shallow] module. *)
end
```

It is worth stressing that supplying a `resumption` object to `abort`/`abort_with` only injects an exception into a single copy of the resumption, meaning it is possible to subsequently supply same `resumption` object to `resume`/`resume_with`. In order to destroy all copies, one must explicitly use `drop` on the `resumption` object. If you know in advance that how many invocations of the resumption you are going to do, then it is more efficient to use `demote` on the `resumption` object prior to the last invocation and use the regular OCaml API on the resulting `continuation`.

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

This library includes snippets of code that are originally written by
KC Sivaramakrishnan, Tom Kelly, and Stephen Dolan. See the file
[fiber_primitives.c](https://github.com/dhil/ocaml-multicont/blob/master/fiber_primitives.c)
for the details.
