# Multicont: Continuations with multi-shot semantics in OCaml

[![Multicont build, install, & running examples suite](https://github.com/dhil/ocaml-multicont/actions/workflows/default.yml/badge.svg)](https://github.com/dhil/ocaml-multicont/actions/workflows/default.yml)

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

This library is designed to be used in tandem with the `Effect`
module, which provides the API for regular linear continuations. The
structure of this library mirrors that of `Effect` as it provides
submodules for the `Deep` and `Shallow` variations of
continuations. This library intentionally uses a slightly different
terminology than `Effect` in order to allow both libraries to be
opened in the same scope. For example, this library uses the
terminology `resumption` in place of `continuation`. A resumption
essentially amounts to a GC managed variation of a regular OCaml
continuation, which in addition can be continued multiple times.  The
signature file
[multicont.mli](https://github.com/dhil/ocaml-multicont/blob/master/multicont.mli)
contains the interface for this library, which I have inlined below:

```ocaml
module Deep: sig
  type ('a, 'b) resumption
  (** a [resumption] is a managed variation of
     [Effect.Deep.continuation] that can be used multiple times. *)

  val promote : ('a, 'b) Effect.Deep.continuation -> ('a, 'b) resumption
  (** [promote k] converts a regular linear deep continuation to a
      multi-shot deep resumption. This function fully consumes the
      supplied the continuation [k]. *)

  val resume : ('a, 'b) resumption -> 'a -> 'b
  (** [resume r v] reinstates the context captured by the multi-shot
      deep resumption [r] with value [v]. *)

  val abort : ('a, 'b) resumption -> exn -> 'b
  (** [abort r e] injects the exception [e] into the context captured
      by the multi-shot deep resumption [r]. *)

  val abort_with_backtrace : ('a, 'b) resumption -> exn ->
                             Printexc.raw_backtrace -> 'b
  (** [abort_with_backtrace k e bt] aborts the deep multi-shot
      resumption [r] by raising the exception [e] in [k] using [bt] as
      the origin for the exception. *)

  (* Primitives *)
  val clone_continuation : ('a, 'b) Effect.Deep.continuation -> ('a, 'b) Effect.Deep.continuation
  (** [clone_continuation k] clones the linear deep continuation [k]. The
      supplied continuation is *not* consumed. *)

  val drop_continuation : ('a, 'b) Effect.Deep.continuation -> unit
  (** [drop_continuation k] deallocates the memory occupied by the
      continuation [k]. Note, however, that this function does not clean
      up acquired resources captured by the continuation. In order to
      delete the continuation and free up the resources the programmer
      should instead use `discontinue` from the [Effect.Deep] module. *)
end

module Shallow: sig
  type ('a, 'b) resumption
  (** a [resumption] is a managed variation of
     [Effect.Shallow.continuation] that can be used multiple times. *)

  val promote : ('a, 'b) Effect.Shallow.continuation -> ('a, 'b) resumption
 (** [promote k] converts a regular linear shallow continuation to a
     multi-shot shallow resumption. This function fully consumes the
     supplied the continuation [k]. *)

  val resume_with : ('c, 'a) resumption -> 'c -> ('a, 'b) handler -> 'b
  (** [resume r v h] reinstates the context captured by the multi-shot
      shallow resumption [r] with value [v] under the handler [h]. *)

  val abort_with  : ('c, 'a) resumption -> exn -> ('a, 'b) handler -> 'b
  (** [abort r e h] injects the exception [e] into the context captured
      by the multi-shot shallow resumption [r] under the handler [h]. *)

  val abort_with_backtrace : ('c, 'a) resumption -> exn ->
                             Printexc.raw_backtrace -> ('a, 'b) handler -> 'b
  (** [abort_with_backtrace k e bt] aborts the shallow multi-shot
      resumption [r] by raising the exception [e] in [k] using [bt] as
      the origin for the exception. *)

  (* Primitives *)
  val clone_continuation : ('a, 'b) Effect.Shallow.continuation -> ('a, 'b) Effect.Shallow.continuation
  (** [clone_continuation k] clones the linear shallow continuation [k]. The
      supplied continuation is *not* consumed. *)

  val drop_continuation : ('a, 'b) Effect.Shallow.continuation -> unit
  (** [drop_continuation k] deallocates the memory occupied by the
      continuation [k]. Note, however, that this function does not clean
      up acquired resources captured by the continuation. In order to
      delete the continuation and free up the resources the programmer
      should instead use [discontinue_with] from the [Effect.Shallow] module. *)
end
```

It is worth stressing that both `resume`/`resume_with` and
`abort`/`abort_with` exhibit multi-shot semantics, meaning in the
latter case that it is possible to abort a given `resumption` multiple
times.

## Programming with multi-shot continuations

TODO

## Notes on the implementation

Under the hood the library uses regular linear OCaml continuation and
a variation of `clone_continuation` that used to reside in the `Obj`
module of earlier versions of Multicore OCaml. Internally, the
`resumption` types are aliases of the respective `continuation` types
from the `Effect` module. The ability to resume a continuation more
than once is achieved by cloning the original continuation on
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
