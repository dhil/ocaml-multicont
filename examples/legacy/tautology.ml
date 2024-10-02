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
  let h =
    let open Effect.Deep in
    { retc = (fun ans -> ans)
    ; exnc = raise
    ; effc = (fun (type a) (eff : a Effect.t) ->
      match eff with
      | Guess ->
         Some (fun (k : (a, _) continuation) ->
             let open Multicont.Deep in
             let r = promote k in
             resume r true && resume r false)
      | _ -> None) }
  in
  Effect.Deep.match_with p () h

let _ = if tautology prop
        then print_endline "true"
        else print_endline "false"
