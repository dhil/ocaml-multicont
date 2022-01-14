(* Generic counting example based on Hillerström et al. (2020) https://arxiv.org/abs/2007.00605 *)

open Effect
open Deep

type _ eff += Branch : bool eff

type point = int -> bool
type predicate = point -> bool

let xor : bool -> bool -> bool
  = fun p q -> (p || q) && not (p && q)

let xor_predicate : int -> predicate
  = fun n p ->
  match List.init n p with
  | [] -> false
  | v :: vs -> List.fold_left xor v vs

let generic_count : (bool, int) handler =
  { retc = (fun x -> if x then 1 else 0)
  ; exnc = (fun e -> raise e)
  ; effc = (fun (type a) (eff : a eff) ->
    match eff with
    | Branch ->
       Some (fun (k : (a, _) continuation) ->
           let open Multicont.Deep in
           let r = promote k in
           let tt = resume r true in
           let k = demote r in
           let ff = continue k false in
           tt + ff)
    | _ -> None) }

let _ =
  let n = try int_of_string Sys.argv.(1) with _ -> 8 in
  let solutions = match_with (xor_predicate n) (fun _ -> perform Branch) generic_count in
  Printf.printf "%d\n" solutions
