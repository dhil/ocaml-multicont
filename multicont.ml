(* The modules [Deep] and [Shallow] provide a multi-shot semantics for
   OCaml's regular deep and shallow continuations, respectively. This
   semantics is achieved by performing a shallow copy of linear
   continuations on demand (i.e. prior to invocation). *)

module Deep = struct
  open Effect.Deep

  type ('a, 'b) resumption = ('a, 'b) continuation

  (* Primitives *)
  external clone_continuation : ('a, 'b) continuation -> ('a, 'b) continuation = "multicont_clone_continuation"
  external drop_continuation : ('a, 'b) continuation -> unit = "multicont_drop_continuation"
  external promote : ('a, 'b) continuation -> ('a, 'b) resumption = "multicont_promote"

  let promote : ('a, 'b) continuation -> ('a, 'b) resumption
    = fun k ->
    let r = promote k in
    Gc.finalise drop_continuation r; r

  let resume : ('a, 'b) resumption -> 'a -> 'b
    = fun r v -> continue (clone_continuation r) v

  let abort : ('a, 'b) resumption -> exn -> 'b
    = fun r exn -> discontinue (clone_continuation r) exn
end


module Shallow = struct open Effect.Shallow

  type ('a, 'b) resumption = ('a, 'b) continuation

  (* Primitives *)
  external clone_continuation : ('a, 'b) continuation -> ('a, 'b) continuation = "multicont_clone_continuation"
  external drop_continuation : ('a, 'b) continuation -> unit = "multicont_drop_continuation"
  external promote : ('a, 'b) continuation -> ('a, 'b) resumption = "multicont_promote"

  let promote : ('a, 'b) continuation -> ('a, 'b) resumption
    = fun k ->
    let r = promote k in
    Gc.finalise drop_continuation r; r

  let resume_with : ('c, 'a) resumption -> 'c -> ('a, 'b) handler -> 'b
    = fun r v h -> continue_with (clone_continuation r) v h

  let abort_with : ('c, 'a) resumption -> exn -> ('a, 'b) handler -> 'b
    = fun r exn h -> discontinue_with (clone_continuation r) exn h
end
