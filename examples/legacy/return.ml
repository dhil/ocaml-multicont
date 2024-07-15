(* Illustrating the `return' operator as an effect.
 *
 * This encoding utilises only a single handler by leveraging the
 * power of multi-shot continuations to fork two strands of
 * computations. We use the first strand as the context wherein we
 * evaluate the function, whilst we use the second strand as a sort of
 * identity context wherein we return the value of the function
 * application without applying the function. In terms of effects,
 * exceptions, and handlers, we are going to use one operations: Fork
 * : () => [|Apply|Done:a|] which forks the current context, the
 * return value signals which strand of computation to execute; and
 * one exception Return of a. Concretely the idea is to invoke Fork
 * before a function application to capture the current continuation
 * of the application (i.e. the return point). Inside the handler for
 * Fork and Return we maintain a stack of continuations arising from
 * invocations of Fork.
 *)

module type ALG = sig
  type t
  val apply : (t -> t) -> t -> t
  val return : t -> 'a
  val toplevel : (unit -> t) -> t
end

module Alg(D : sig type t end) : ALG with type t := D.t = struct
  type t = D.t

  type cmd = Apply
           | Done of t
  exception Return of t
  type _ Effect.t += Fork : cmd Effect.t

  let return x = raise (Return x)

  let apply f x =
    match Effect.perform Fork with
    | Apply -> return (f x)
    | Done ans -> ans

  let htoplevel : unit -> (t, t) Effect.Deep.handler
    = fun () ->
    let open Effect.Deep in
    let open Multicont.Deep in
    let conts = ref [] in
    let backup ans =
      match !conts with
      | r :: conts' ->
         conts := conts';
         resume r (Done ans)
      | _ -> ans
    in
    let push r =
      conts := r :: !conts
    in
    { retc = (fun ans -> ans)
    ; exnc =
        (function
           Return ans -> backup ans
         | e -> raise e)
    ; effc = (fun (type a) (eff : a Effect.t) ->
      match eff with
      | Fork ->
         Some (fun (k : (a, _) continuation) ->
             let r = promote k in
             push r;
             resume r Apply)
      | _ -> None) }

  let toplevel f =
    Effect.Deep.match_with f () (htoplevel ())
end

let fac n =
  let module I = Alg(struct type t = int end) in
  let rec fac n =
    if n = 0 then 1
    else n * (I.apply fac (n - 1))
  in
  let negate x =
    I.apply ((-) 0) x
  in
  I.toplevel
    (fun () ->
      I.apply negate (I.apply fac n))

let fac' n =
  let module I = Alg(struct type t = int end) in
  let rec fac n =
    if n = 0 then I.return 1;
    n * (I.apply fac (n - 1))
  in
  let negate x =
    I.apply ((-) 0) x
  in
  I.toplevel
    (fun () ->
      I.apply negate (I.apply fac n))

let _ =
  Printf.printf "%d\n%!" (fac 7);
  Printf.printf "%d\n%!" (fac' 7);
