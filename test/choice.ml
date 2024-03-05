(**
  * McCarthy's locally angelic choice
  *)

open Effect.Deep

type 'a Effect.t += Choose : (unit -> 'a) list -> 'a Effect.t

let amb : (unit -> 'a) list -> 'a
  = fun xs -> Effect.perform (Choose xs)

let first_success (type b) : ('a -> b) -> (unit -> 'a) list -> b
  = fun f gs ->
  let exception Success of b in
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
  (* McCarthy's locally angelic choice operator (angelic modulo
     nontermination). *)
  let hamb =
    { retc = (fun x -> x)
    ; exnc = (fun e -> raise e)
    ; effc = (fun (type b) (eff : b Effect.t) ->
      match eff with
      | Choose xs ->
         Some
           (fun (k : (b, _) continuation) ->
             let open Multicont.Deep in
             let r = promote k in
             first_success (resume r) xs)
      | _ -> None) }
  in
  match_with m () hamb

(* The following example is adapted from Oleg Kiselyov
   "Non-deterministic choice amb"
   (c.f. https://okmij.org/ftp/ML/ML.html#amb) *)

let pyth : int list -> (int * int * int)
  = fun numbers ->
  let numbers' = List.map (fun n -> (fun () -> n)) numbers in
  handle (fun () ->
      let i = amb numbers' in
      let j = amb numbers' in
      let k = amb numbers' in
      if i*i + j*j = k*k
      then (i, j, k)
      else failwith "no solution")

let pyth_example () = pyth [1;2;3;4;5]

let _ =
  let tests =
    let open OUnit2 in
    "test suite for choice" >::: [
        "pyth_example" >:: (fun _ -> OUnit2.assert_equal (pyth_example ()) (3, 4, 5)) ]
  in
  OUnit2.run_test_tt_main tests

