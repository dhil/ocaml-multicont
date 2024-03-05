open Effect.Deep

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

let generic_count : (bool, int) handler =
  { retc = (fun x -> if x then 1 else 0)
  ; exnc = (fun e -> raise e)
  ; effc = (fun (type a) (eff : a Effect.t) ->
    match eff with
    | Branch ->
       Some (fun (k : (a, _) continuation) ->
           let open Multicont.Deep in
           let r = promote k in
           let tt = resume r true in
           let ff = resume r false in
           tt + ff)
    | _ -> None) }

let _ =
  let tests =
    let open OUnit2 in
    "test suite for generic count" >::: [
        "xor_predicate" >:: (fun _ -> OUnit2.assert_equal (match_with (xor_predicate 8) (fun _ -> Effect.perform Branch) generic_count) 128) ]
  in
  OUnit2.run_test_tt_main tests
