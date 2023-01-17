# Multicont: Continuations with multi-shot semantics in OCaml

[![Multicont build, install, & running examples suite](https://github.com/dhil/ocaml-multicont/actions/workflows/default.yml/badge.svg)](https://github.com/dhil/ocaml-multicont/actions/workflows/default.yml)

This library provides a thin abstraction on top of OCaml's regular
linear continuations that enables programming with multi-shot
continuations, i.e. continuations that can be applied more than once.

See the
[`examples/`](https://github.com/dhil/ocaml-multicont/tree/master/examples)
directory for concrete uses of this library (or multi-shot
continuations) in practice.

## Installing the library

The library can be installed via [OPAM](https://opam.ocaml.org/). The
latest release can be installed directly from the default OPAM
repository, e.g.

```
$ opam install multicont
```

Alternatively, the latest development version can be installed by
pinning this repository, e.g.

```
$ opam pin multicont git@github.com:dhil/ocaml-multicont.git
```

### Building from source

It is straightforward to build and install this library from source as
its only dependency is an OCaml 5.0+ compiler. To build the whole
library simply invoke the `all` rule, i.e.

```shell
$ make all
```

The Makefile also gives you more fine-grained control over what is
being built. For example, you may only want to build either the byte
code or native code compatible version of the library.

```shell
# Builds the byte code compatible library
$ make byte
# Builds the native code compatible library
$ make native
```

In some cases you may want to build this library from source over,
say, using OPAM to build and install it, because the installation via
OPAM is somewhat inflexible in the sense that it does not readily
allow configurable options to be toggled. Whether to toggle the
configurable options may depend on how your instance of the OCaml
compiler was configured. For example, your OCaml compiler might have
been configured to use [virtual memory mapped
stacks](https://man7.org/linux/man-pages/man2/mmap.2.html) (option
`USE_MMAP_MAP_STACK`). To toggle this option for this library, simply
set the variable on the command line, e.g.

```shell
$ make USE_MMAP_MAP_STACK=1 all
```

Another option one might consider toggling is `UNIQUE_FIBERS` as since
commit
[ocaml/ocaml#e12b508](https://github.com/ocaml/ocaml/commit/e12b508876065723ed5fc35c0945030c9b7cd100)
stock OCaml fibers are uniquely identifiable. Under the hood this
library clones fibers. By default this clone will be an exact copy of
the original fiber, meaning that the clone and original fiber will
share the same identity. If unique identities are important, then
setting `UNIQUE_FIBERS=1` will ensure that each clone gets its own
unique identity.

The Makefile contains an `install` rule, which installs the built
library under your current OPAM switch, i.e.

```shell
$ make install
```

Similarly, the library can easily be uninstalled by invoking the
appropriate rule, i.e.

```shell
$ make uninstall
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
      supplied continuation [k]. *)

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
     supplied continuation [k]. *)

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

## Cautionary tales in programming with multi-shot continuations in OCaml

The OCaml compiler and runtime make some assumptions that are false in
the presence of multi-shot continuations. This phenomenon is perhaps
best illustrated by an example. Concretely, we can consider some
optimisations performed by the compiler which are undesirable (or
outright wrong) when programming with multi-shot continuations. An
instance of a wrong compiler optimisation is *heap to stack*
conversion, e.g.

```ocaml
(* An illustration of how the heap to stack optimisation is broken.
 * This example is adapted from de Vilhena and Pottier (2021).
 * file: heap2stack.ml
 * compile: ocamlopt -I $(opam var lib)/multicont multicont.cmxa heap2stack.ml
 * run: ./a.out *)

(* We first require a little bit of setup. The following declares an
   operation `Twice' which we use to implement multiple returns. *)
type _ Effect.t += Twice : unit Effect.t

(* The handler `htwice' interprets `Twice' by simply invoking its
   continuation twice. *)
let htwice : (unit, unit) Effect.Deep.handler
  = { retc = (fun x -> x)
    ; exnc = (fun e -> raise e)
    ; effc = (fun (type a) (eff : a Effect.t) ->
      let open Effect.Deep in
      match eff with
      | Twice -> Some (fun (k : (a, _) continuation) ->
         continue (Multicont.Deep.clone_continuation k) ();
         continue k ())
      | _ -> None) }

(* Now for the interesting stuff. In the code below, the compiler will
   perform an escape analysis on the reference `i' and deduce that it
   does not escape the local scope, because it is unaware of the
   semantics of `perform Twice', hence the optimiser will transform
   `i' into an immediate on the stack to save a heap allocation. As a
   consequence, the assertion `(!i = 1)' will succeed twice, whereas
   it should fail after the second return of `perform Twice'. *)
let heap2stack () =
  Effect.Deep.match_with
    (fun () ->
      let i = ref 0 in
      Effect.perform Twice;
      i := !i + 1;
      Printf.printf "i = %d\n%!" !i;
      assert (!i = 1))
    () htwice

(* The following does not trigger an assertion failure. *)
let _ = heap2stack ()

(* To fix this issue, we can wrap reference allocations in an instance
   of `Sys.opaque_identity'. However, this is not really a viable fix
   in general, as we may not have access to the client code that
   allocates the reference! *)
let heap2stack' () =
  Effect.Deep.match_with
    (fun () ->
      let i = Sys.opaque_identity (ref 0) in
      Effect.perform Twice;
      i := !i + 1;
      Printf.printf "i = %d\n%!" !i;
      assert (!i = 1))
    () htwice

(* The following triggers an assertion failure. *)
let _ = heap2stack' ()
```

The wrong behaviour of `heap2stack` is only observed when compiling
with `ocamlc` or `ocamlopt`. As of writing, the read-eval-print loop
interpreter does not perform the heap to stack conversion, therefore
running it through `ocaml` will cause `heap2stack` to trigger the
assertion failure as desired.

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

This work was supported by the UKRI Future Leaders Fellowship
"Effect Handler Oriented Programming" (reference number MR/T043830/1).
