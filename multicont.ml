(* The modules [Deep] and [Shallow] provide a multi-shot semantics for
   OCaml's regular deep and shallow continuations, respectively. This
   semantics is achieved by performing a shallow copy of linear
   continuations on demand (i.e. prior to invocation). *)

exception Resumption_already_dropped

module Deep = struct open EffectHandlers.Deep

  type ('a, 'b) resumption = ('a, 'b) continuation

  (** Primitives **) external clone_continuation : ('a, 'b)
   continuation -> ('a, 'b) continuation =
   "multicont_clone_continuation" external drop_continuation : ('a,
   'b) continuation -> unit = "multicont_drop_continuation" external
   is_null_continuation : ('a, 'b) continuation -> bool =
   "multicont_is_null_continuation" [@@noalloc] external promote :
   ('a, 'b) continuation -> ('a, 'b) resumption = "multicont_promote"
   external demote : ('a, 'b) resumption -> ('a, 'b) continuation =
   "multicont_demote"

  let resume : ('a, 'b) resumption -> 'a -> 'b = fun r v -> if
   is_null_continuation r then raise Resumption_already_dropped else
   continue (clone_continuation r) v

  let abort : ('a, 'b) resumption -> exn -> 'b = fun r exn ->
   discontinue (clone_continuation r) exn

  let drop : ('a, 'b) resumption -> unit = fun r -> drop_continuation
   r end

module Shallow = struct open EffectHandlers.Shallow

  type ('a, 'b) resumption = ('a, 'b) continuation

  (** Primitives **) external clone_continuation : ('a, 'b)
   continuation -> ('a, 'b) continuation =
   "multicont_clone_continuation" external drop_continuation : ('a,
   'b) continuation -> unit = "multicont_drop_continuation" external
   is_null_continuation : ('a, 'b) continuation -> bool =
   "multicont_is_null_continuation" [@@noalloc] external promote :
   ('a, 'b) continuation -> ('a, 'b) resumption = "multicont_promote"
   external demote : ('a, 'b) resumption -> ('a, 'b) continuation =
   "multicont_demote"

  let resume_with : ('c, 'a) resumption -> 'c -> ('a, 'b) handler ->
   'b = fun r v h -> if is_null_continuation r then raise
   Resumption_already_dropped else continue_with (clone_continuation
   r) v h

  let abort_with : ('c, 'a) resumption -> exn -> ('a, 'b) handler ->
   'b = fun r exn h -> if is_null_continuation r then raise
   Resumption_already_dropped else discontinue_with
   (clone_continuation r) exn h

  let drop : ('a, 'b) resumption -> unit = fun r -> drop_continuation
   r end
