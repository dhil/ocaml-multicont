open Effect.Deep
open Multicont.Deep

type _ Effect.t += Clone : unit Effect.t

let test unique_fibers_enabled =
  let result = ref [] in
  match_with Effect.perform Clone
    { retc = (fun _ -> ())
    ; exnc = raise
    ; effc = (fun (type a) (eff : a Effect.t) ->
      match eff with
      | Clone -> Some (fun (k : (a, _) continuation) ->
                     let open Multicont_testlib.Inspect_fiber in
                     let k' = clone_continuation k in
                     (* NOTE(dhil): The fiber and continuation
                        representation is the same for deep and
                        shallow continuations. *)
                     result := [ fiber_id (Obj.magic k)
                               ; fiber_id (Obj.magic k')])
      | _ -> None ) };
  match !result with
  | [original_id; clone_id] when unique_fibers_enabled ->
     assert (not (Int64.equal original_id clone_id))
  | [original_id; clone_id] when not unique_fibers_enabled ->
     assert (Int64.equal original_id clone_id)
  | _ -> assert false

let _ =
  match Sys.getenv_opt "TEST_UNIQUE_FIBERS" with
  | Some "true" -> test true
  | _ -> test false
