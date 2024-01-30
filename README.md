# Multicont: Continuations with multi-shot semantics in OCaml

[![Multicont build, install, and running examples](https://github.com/dhil/ocaml-multicont/actions/workflows/default.yml/badge.svg)](https://github.com/dhil/ocaml-multicont/actions/workflows/default.yml)

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

### Building and installing from source

It is straightforward to build and install this library from source as
its only dependencies are an [OCaml
5.0+](https://github.com/ocaml/ocaml) compiler,
[dune](https://github.com/ocaml/dune), and
[dune-configurator](https://github.com/ocaml/dune). To build the whole
library simply invoke the `all` rule, i.e.

```shell
$ make all
```

The Makefile also gives you more fine-grained control over what is
being built. For example, you may only want to build either the byte
code or native code compatible version of the library.

To install the library built from source simply invoke the `install`
rule:

```shell
$ make install
```

Similarly to uninstall the library again invoke the `uninstall` rule:

```shell
$ make uninstall
```

## Configurable options

The primary reason to build from source is to toggle configurable
options of this library, which are not readily available via OPAM
install. Currently, the following options are supported:

* `UNIQUE_FIBERS` (default: disabled): Since commit
[ocaml/ocaml#e12b508](https://github.com/ocaml/ocaml/commit/e12b508876065723ed5fc35c0945030c9b7cd100)
stock OCaml fibers have been equipped with unique identifiers. Enable
this option to preserve unique identities amongst fibers as without
this option a fiber clone is an exact copy of the original fiber,
including its identity. By enabling this option, a cloned fiber will
be assigned a new unique identity.
* `USE_MMAP_MAP_STACK` (default: disabled): Enable to use [virtual
memory mapped
stacks](https://man7.org/linux/man-pages/man2/mmap.2.html) rather than
stacks allocated by malloc.

Configurable options are toggled directly on the command line as a
prefix to the `make` command. For instance, the following enables
unique fiber identities and mmap stacks:

```shell
$ UNIQUE_FIBERS=1 USE_MMAP_MAP_STACK=1 make all
```

Setting an option to `1` enables it, whereas any other possible
assignment disables it.

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

One must exercise caution when programming with multi-shot
continuations in OCaml, as the programming model for continuations was
designed with single-shot continuations in mind. Consequently, there
are a couple of hazards that one should be aware of. Broadly, speaking
we can classify these hazards into two categories: compiler
optimisations and effect ordering.

### Compiler optimisation: Heap to stack conversion

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

### Effect ordering: Array initialisation

We can use multi-shot continuations to inadvertently observe
implementation details, which would otherwise be unobservable (inside
the language). Lets illustrate this phenomenon with a concrete
example.

```ocaml
(* An illustration of how effect ordering is observable with
 * multi-shot continuations (OCaml 5.1.1).
 * file: efford.ml
 * compile: ocamlopt -I $(opam var lib)/multicont multicont.cmxa efford.ml
 * run: ./a.out  *)

(* We first require a little bit of setup. The following declares an
   operation `Twice' which we use to implement multiple returns. *)
type _ Effect.t += Twice : bool Effect.t

(* The handler `htwice' interprets `Twice' by enumerating the possible
   outcomes of its continuation. *)
let htwice : 'a. ('a, 'a list) Effect.Deep.handler
  = { retc = (fun x -> [x])
    ; exnc = (fun e -> raise e)
    ; effc = (fun (type a) (eff : a Effect.t) ->
      let open Effect.Deep in
      match eff with
      | Twice -> Some (fun (k : (a, _) continuation) ->
          let xs = continue (Multicont.Deep.clone_continuation k) true in
          let ys = continue k false in
          xs @ ys)
      | _ -> None) }

(* This function uses the `Twice` operation to initialise a bit vector
   of length `n`. *)
let init_vec : int -> bool array
  = fun n ->
  Array.init n (fun _ -> Effect.perform Twice)

(* The array backing the bit vector is imperative, thus one might
   expect the interpreting `init_vec 1` with `htwice` to evaluate to
   `[[|false|];[|false|]]`, where the two arrays have the same
   identity. Lets see what it evaluates to... *)
let _ =
  match Effect.Deep.match_with init_vec 1 htwice with
  | [[|true|]; [|false|]] -> ()
  | _ -> assert false
(* We get two distinct arrays. Lets see what happens if we initialise
   a vector of length 2: *)
let _ =
  match Effect.Deep.match_with init_vec 2 htwice with
  | [[|true; false|]; [|true; false|]; [|false; false|]; [|false; false|]] -> ()
  | _ -> assert false
(* We have four arrays, but only two of them are distinct (both
   structurally and nominally). What about vectors of length 3? *)
let _ =
  match Effect.Deep.match_with init_vec 3 htwice with
  | [[|true; false; false|] ; [|true; false; false|] ; [|true; false; false|] ; [|true; false; false|];
     [|false; false; false|]; [|false; false; false|]; [|false; false; false|]; [|false; false; false|]] -> ()
  | _ -> assert false
(* We have eight arrays, but again only two of them are distinct. This
   pattern continues as we increase `n`. So what's going on? It turns
   out that we are observing an implementation detail of
   `Array.init`. Its definition is:

     let init l f =
       if l = 0 then [||] else
       if l < 0 then invalid_arg "Array.init" else
       let res = create l (f 0) in (* !! *)
       for i = 1 to pred l do
         unsafe_set res i (f i)
       done;
       res

  The line with the code responsible for the behaviour is highlighted
  by the (* !! *) comment. Here we evaluate `f 0`, i.e. `perform
  Twice`, _before_ we allocate the array, meaning the second
  invocation of the continuation of the first `Twice` causes another
  array to be allocated, explaining why we always have two distinct
  arrays and why the first cell is not set to `false` in the first
  `n/2` arrays of the list.

  Essentially, we are witnessing the ordering between the user-defined
  operation `Twice` and the native operation for array creation. If we
  were to swap them, then we get the behaviour we may have expected
  initially.  *)

let init' : int -> (int -> bool) -> bool array
  = fun l f ->
  if l = 0 then [||] else
  if l < 0 then invalid_arg "Array.init" else
  let res = Array.make l true in
  Array.set res 0 (f 0);
  for i = 1 to pred l do
    Array.unsafe_set res i (f i)
  done;
  res

(* Similar to `init_vec`, except we initialise the bit vector with
   our modified `init'`. *)
let init_vec' : int -> bool array
  = fun n ->
  init' n (fun _ -> Effect.perform Twice)

(* Lets rerun the examples from before. *)
let _ =
  match Effect.Deep.match_with init_vec' 1 htwice with
  | [[|false|]; [|false|]] -> ()
  | _ -> assert false
(* Here the two arrays are nominally (i.e. they have the same identity)
   equivalent. *)
let _ =
  match Effect.Deep.match_with init_vec' 2 htwice with
  | [[|false; false|]; [|false; false|]; [|false; false|]; [|false; false|]] -> ()
  | _ -> assert false
let _ =
  match Effect.Deep.match_with init_vec' 3 htwice with
  | [[|false; false; false|]; [|false; false; false|]; [|false; false; false|]; [|false; false; false|];
     [|false; false; false|]; [|false; false; false|]; [|false; false; false|]; [|false; false; false|]] -> ()
  | _ -> assert false
(* Evidently, the contents of the first cell are overridden by the
   second invocation of the initial continuation of `Twice`. *)
```

These behaviours are instances of the behaviour of composing
nondeterminism and state to yield either backtrackable or
non-backtrackable state. Either behaviour can be desirable. The word
of caution here is that certain implementation details of higher-order
functions may be observed to a greater extent than is possible with
single-shot continuations or exceptions.

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
