(** This module provides multi-shot semantics on top of OCaml's
    regular linear continuations. *)

module Deep: sig
  open Effect.Deep

  type ('a, 'b) resumption
  (** a [resumption] is a managed variation of
     [Effect.Deep.continuation] that can be used multiple times. *)

  val promote : ('a, 'b) continuation -> ('a, 'b) resumption
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
  val clone_continuation : ('a, 'b) continuation -> ('a, 'b) continuation
  (** [clone_continuation k] clones the linear deep continuation [k]. The
      supplied continuation is *not* consumed. *)

  val drop_continuation : ('a, 'b) continuation -> unit
  (** [drop_continuation k] deallocates the memory occupied by the
      continuation [k]. Note, however, that this function does not clean
      up acquired resources captured by the continuation. In order to
      delete the continuation and free up the resources the programmer
      should instead use `discontinue` from the [Effect.Deep] module. *)
end

module Shallow: sig
  open Effect.Shallow

  type ('a, 'b) resumption
  (** a [resumption] is a managed variation of
     [Effect.Shallow.continuation] that can be used multiple times. *)

  val promote : ('a, 'b) continuation -> ('a, 'b) resumption
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
  val clone_continuation : ('a, 'b) continuation -> ('a, 'b) continuation
  (** [clone_continuation k] clones the linear shallow continuation [k]. The
      supplied continuation is *not* consumed. *)

  val drop_continuation : ('a, 'b) continuation -> unit
  (** [drop_continuation k] deallocates the memory occupied by the
      continuation [k]. Note, however, that this function does not clean
      up acquired resources captured by the continuation. In order to
      delete the continuation and free up the resources the programmer
      should instead use [discontinue_with] from the [Effect.Shallow] module. *)
end
