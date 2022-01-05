(** This module provides multi-shot semantics on top of OCaml's
    regular linear continuations. *)

exception Resumption_already_dropped

module Deep: sig
  open EffectHandlers.Deep

  type ('a, 'b) resumption

  val promote : ('a, 'b) continuation -> ('a, 'b) resumption
  (** [promote k] converts a regular linear deep continuation to a multi-shot deep
      resumption. This function fully consumes the supplied the continuation [k]. *)

  val demote : ('a, 'b) resumption -> ('a, 'b) continuation
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
  val clone_continuation : ('a, 'b) continuation -> ('a, 'b) continuation
  (** [clone_continuation k] clones the linear deep continuation [k]. The
      supplied continuation is *not* consumed. *)

  val drop_continuation : ('a, 'b) continuation -> unit
  (** [drop_continuation k] deallocates the memory occupied by the
      continuation [k]. Note, however, that this function does not clean
      up acquired resources captured by the continuation. In order to
      delete the continuation and free up the resources the programmer
      should instead use `discontinue` from the [EffectHandlers.Deep]
      module. *)
end

module Shallow: sig
  open EffectHandlers.Shallow

  type ('a, 'b) resumption

  val promote : ('a, 'b) continuation -> ('a, 'b) resumption
 (** [promote k] converts a regular linear shallow continuation to a multi-shot shallow
     resumption. This function fully consumes the supplied the continuation [k]. *)

  val demote : ('a, 'b) resumption -> ('a, 'b) continuation
 (** [demote r] converts a shallow multi-shot resumption into a linear
     shallow continuation. The argument [r] is fully consumed, making
     further invocations of [r] impossible. *)

  val resume_with : ('c, 'a) resumption -> 'c -> ('a, 'b) handler -> 'b
  (** [resume r v h] reinstates the context captured by the multi-shot
      shallow resumption [r] with value [v] under the handler [h].

      @raises Resumption_already_dropped if the resumption has been dropped. *)

  val abort_with  : ('c, 'a) resumption -> exn -> ('a, 'b) handler -> 'b
  (** [abort r e h] injects the exception [e] into the context captured
      by the multi-shot shallow resumption [r] under the handler [h].

      @raises Resumption_already_dropped if the resumption has been dropped. *)

  val drop : ('a, 'b) resumption -> unit
  (** [drop r] fully consumes the multi-shot shallow resumption [r],
      making further invocations of [r] impossible. *)

  (* Primitives *)
  val clone_continuation : ('a, 'b) continuation -> ('a, 'b) continuation
  (** [clone_continuation k] clones the linear shallow continuation [k]. The
      supplied continuation is *not* consumed. *)

  val drop_continuation : ('a, 'b) continuation -> unit
  (** [drop_continuation k] deallocates the memory occupied by the
      continuation [k]. Note, however, that this function does not clean
      up acquired resources captured by the continuation. In order to
      delete the continuation and free up the resources the programmer
      should instead use [discontinue_with] from the
      [EffectHandlers.Shallow] module. *)
end
