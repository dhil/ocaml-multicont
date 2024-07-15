(* Generic counting example based on Hillerström et al. (2020) https://arxiv.org/abs/2007.00605 *)

type _ Effect.t += Branch : bool Effect.t

type point = int -> bool
type predicate = point -> bool

let xor : bool -> bool -> bool
  = fun p q -> (p || q) && not (p && q)

let xor_predicate : int -> predicate
  = fun n p ->
  match List.init n p with
  | [] -> false
  | v :: vs -> List.fold_left xor v vs

let generic_count : ((int -> bool) -> bool) -> int
  = fun f ->
  match f (fun _ -> Effect.perform Branch) with
  | ans -> if ans then 1 else 0
  | effect Branch, k ->
     let open Multicont.Deep in
     let r = promote k in
     let tt = resume r true in
     let ff = resume r false in
     tt + ff

let _ =
  let n = try int_of_string Sys.argv.(1) with _ -> 8 in
  let solutions = generic_count (xor_predicate n) in
  Printf.printf "%d\n" solutions
