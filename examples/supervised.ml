(* Restartable processes *)

module Pid = struct
  type t = Zero
         | NonZero of int

  let is_zero : t -> bool = function
    | Zero -> true
    | _ -> false

  let zero : t = Zero

  let make : int -> t
    = fun ident -> NonZero ident
end

type _ Effect.t += Fork : Pid.t Effect.t
                 | Join : Pid.t -> unit Effect.t

exception Fail


let fork : unit -> Pid.t
  = fun () -> Effect.perform Fork

let join : Pid.t -> unit
  = fun pid -> Effect.perform (Join pid)

let fail : unit -> 'a
  = fun () -> raise Fail


(* Supervisor state *)
type sstate = { mutable suspended: (Pid.t * (unit -> unit)) list
              ; mutable blocked: (Pid.t * (Pid.t * (unit -> unit)) list) list
              ; mutable finished: Pid.t list
              ; mutable active: Pid.t * (unit -> unit)
              ; mutable nextpid: int }

let supervise : (unit -> unit) -> unit
  = fun f ->
  let state =
    { suspended = []
    ; blocked = []
    ; finished = []
    ; active = (Pid.zero, (fun () -> assert false))
    ; nextpid = 2 }
  in
  let supervisor =
    let open Effect.Deep in
    { retc = (fun _ ->
        let (pid, _) = state.active in
        state.finished <- pid :: state.finished;
        let rs, blocked =
          match List.assoc_opt pid state.blocked with
          | None -> [], state.blocked
          | Some rs -> rs, List.remove_assoc pid state.blocked
        in
        match state.suspended @ rs with
        | [] -> ()
        | (pid, r) :: rs ->
           state.suspended <- rs;
           state.blocked <- blocked;
           state.active <- (pid, r);
           r ())
    ; exnc = (fun e ->
      match e with
      | Fail ->
         begin match state.suspended @ [state.active] with
         | [] -> assert false
         | (pid, r) :: rs ->
            state.active <- (pid, r);
            state.suspended <- rs;
            r ()
         end
      | _ -> raise e)
    ; effc = (fun (type a) (eff : a Effect.t) ->
      match eff with
      | Fork ->
         Some (fun (k : (a, _) continuation) ->
           let open Multicont.Deep in
           let r = promote k in
           let pid =
             let i = state.nextpid in
             state.nextpid <- i + 1;
             Pid.make i
           in
           state.suspended <- state.suspended @ [pid, (fun () -> resume r Pid.zero)];
           resume r pid)
      | Join (pid : Pid.t) ->
         Some (fun (k : (a, _) continuation) ->
           let open Multicont.Deep in
           let r = promote k in
           if List.mem pid state.finished
           then resume r ()
           else let blocked =
                  match List.assoc_opt pid state.blocked with
                  | None -> (pid, [fst state.active, (fun () -> resume r ())]) :: state.blocked
                  | Some _ -> state.blocked
                in
                state.blocked <- blocked;
                match state.suspended with
                | [] -> assert false
                | (pid', r) :: rs ->
                   state.active <- (pid', r);
                   state.suspended <- rs;
                   r ())
      | _ -> None) }
  in
  state.active <- (Pid.make 1, (fun () -> Effect.Deep.match_with f () supervisor));
  Effect.Deep.match_with f () supervisor

let child : int -> int -> int ref -> unit
  = fun i n st ->
  if !st < n
  then (incr st
       ; Printf.printf "Child %d failed!\n%!" i
       ; fail ())
  else Printf.printf "Child %d succeeded!\n%!" i

let example () =
  let s = ref 0 in
  let pid = fork () in
  if Pid.is_zero pid
  then let pid = fork () in
       if Pid.is_zero pid
       then child 2 5 s
       else (child 1 3 s
            ; Printf.printf "Child 1 joining with Child 2\n%!"
            ; join pid
            ; Printf.printf "Child 1 joined with Child 2\n%!")
  else (print_endline "Parent joining with Child 1"
       ; join pid
       ; print_endline "Parent joined with Child 1")

let _ = supervise example

