(** Example adapted from Campbell et al. (2024) "Effectful Assembly
   Programming with AsmFX" at HOPE@ICFP'24 *)

type _ Effect.t += Guess : bool Effect.t

let guess () = Effect.perform Guess

(* (A && B) || not A || not B *)
let prop () =
  let a = guess () in
  let b = guess () in
  (a && b) || not a || not b

let tautology p =
  match p () with
  | ans -> ans
  | effect Guess, k ->
     let open Multicont.Deep in
     let r = promote k in
     resume r true && resume r false

let _ = if tautology prop
        then print_endline "true"
        else print_endline "false"
