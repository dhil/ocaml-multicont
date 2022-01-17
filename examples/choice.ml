(**
  * McCarthy's locally angelic choice
  *)

open Effect

module type NONDET = sig
  type elem

  val amb : (unit -> elem) list -> elem
  val handle : (unit -> 'a) -> 'a
end

module MakeAmb(N : sig type elem end):
sig
  include NONDET with type elem = N.elem
end = struct
  type elem = N.elem

  type _ eff += Choose : (unit -> elem) list -> elem eff

  let amb : (unit -> elem) list -> elem
  = fun xs -> perform (Choose xs)

  let first_success (type a) : (elem -> a) -> (unit -> elem) list -> a
    = fun f gs ->
    let exception Success of a in
    try
      List.iter
        (fun g ->
          try
            let x = g () in
            raise (Success (f x))
          with (Success _) as e -> raise e
             | _ -> ())
        gs; raise (Failure "no success")
    with Success r -> r

  let handle : (unit -> 'a) -> 'a
    = fun m ->
    let open Deep in
    (* McCarthy's locally angelic choice operator (angelic modulo
       nontermination). *)
    let hamb =
      let open Deep in
      { retc = (fun x -> x)
      ; exnc = (fun e -> raise e)
      ; effc = (fun (type a) (eff : a eff) ->
        match eff with
        | Choose xs ->
           Some
             (fun (k : (a, _) continuation) ->
               let open Multicont.Deep in
               let r = promote k in
               first_success (resume r) xs)
        | _ -> None) }
    in
    match_with m () hamb
end

(* The following examples are adapted from Oleg Kiselyov
   "Non-deterministic choice amb"
   (c.f. https://okmij.org/ftp/ML/ML.html#amb) *)

(* An angelic choice *always* picks the successful branch. *)
let branch_example : unit -> int
  = fun () ->
  let module BoolAmb = MakeAmb(struct type elem = bool end) in
  BoolAmb.handle
    (fun () ->
      if BoolAmb.amb [(fun () -> true); (fun () -> false)]
      then failwith "Fail"
      else 42)


(* More involved example, requiring `amb` to three right choices. *)
let pyth : int list -> (int * int * int)
  = fun numbers ->
  let numbers' = List.map (fun n -> (fun () -> n)) numbers in
  let module IntAmb = MakeAmb(struct type elem = int end) in
  IntAmb.handle (fun () ->
      let i = IntAmb.amb numbers' in
      let j = IntAmb.amb numbers' in
      let k = IntAmb.amb numbers' in
      if i*i + j*j = k*k
      then (i, j, k)
      else failwith "no solution")

let pyth_example () = pyth [1;2;3;4;5]


let _ =
  let (x, y, z) = pyth_example () in
  Printf.printf "(%d, %d, %d)\n%!" x y z
