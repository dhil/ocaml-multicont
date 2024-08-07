(* An algebraically well-behaved implementation of async/await with
   multi-shot continuations. *)

module Async: sig
  module Promise: sig
    type 'a t
    exception Circular_await
  end

  val await : 'a Promise.t -> 'a
  val async : (unit -> 'a) -> 'a Promise.t
  val yield : unit -> unit
  val run : (unit -> 'a) -> 'a
end = struct

  module Promise = struct
    type 'a promise = Done of 'a
                    | Pending of ('a -> unit) list
    type 'a t = 'a promise ref

    exception Circular_await

    let is_done : 'a t -> bool
      = fun pr -> match !pr with
                  | Done _ -> true
                  | _ -> false

    let wait : 'a t -> ('a -> unit) -> unit
      = fun pr r -> match !pr with
                    | Done _ -> assert false
                    | Pending rs -> pr := Pending (r :: rs)

    let value : 'a t -> 'a
      = fun pr -> match !pr with
                  | Done v -> v
                  | Pending _ -> assert false

    let make_empty : unit -> 'a t
      = fun () -> ref (Pending [])
  end

  type _ Effect.t += Await : 'a Promise.t -> 'a Effect.t
                   | Fork : bool Effect.t
                   | Yield : unit Effect.t


  exception End_of_strand

  let await : 'a Promise.t -> 'a
    = fun pr -> Effect.perform (Await pr)

  let fork : unit -> bool
    = fun () -> Effect.perform Fork

  let yield : unit -> unit
    = fun () -> Effect.perform Yield

  let async : (unit -> 'a) -> 'a Promise.t
    = fun f ->
    let pr = Promise.make_empty () in
    if fork () (* returns twice *)
    then pr
    else let v = f () in
         (match !pr with
          | Done _ -> assert false
          | Pending rs ->
             pr := Done v;
             List.iter (fun r -> r v) rs);
         raise End_of_strand

  module Scheduler = struct

    type state = { suspended: (unit -> unit) Queue.t }

    let enqueue :  state -> (unit -> unit) -> unit
      = fun st r ->
      Queue.add r st.suspended

    let run_next : state -> unit
      = fun st ->
      if Queue.is_empty st.suspended then ()
      else Queue.take st.suspended ()

    let run : (unit -> unit) -> unit
      = fun f ->
      let state = { suspended = Queue.create () } in
      match f () with
      | () -> ()
      | exception End_of_strand -> run_next state
      | effect Await pr, k ->
         let open Effect.Deep in
         (if Promise.is_done pr
          then continue k (Promise.value pr)
          else Promise.wait pr (fun v -> continue k v));
         run_next state
      | effect Fork, k ->
         let open Multicont.Deep in
         let r = promote k in
         enqueue state (fun () -> resume r false);
         resume r true
      | effect Yield, k ->
         let open Effect.Deep in
         enqueue state (fun () -> continue k ());
         run_next state
  end

  let run : (unit -> 'a) -> 'a
    = fun f ->
    let result = ref (fun () -> raise Promise.Circular_await) in
    let f' () =
      let v = f () in
      result := (fun () -> v)
    in
    Scheduler.run f';
    !result ()
end

(* Another effect: dynamic binding *)
module Env = struct
  type _ Effect.t += Ask : int Effect.t

  let ask : unit -> int
    = fun () -> Effect.perform Ask

  let bind : int -> (unit -> 'b) -> 'b
    = fun v f ->
    match f () with
    | ans -> ans
    | effect Ask, k -> Effect.Deep.continue k v
end

(* The `well-behaveness' of this implementation can be illustrated by
   using it in conjunction with another effect. In each async strand
   any occurrence of `Ask' is correctly bound by an ambient
   `Env.bind'. *)
let main () =
  let task name () =
    Printf.printf "starting %s\n%!" name;
    let v = Env.ask () in
    Printf.printf "yielding %s\n%!" name;
    Async.yield ();
    Printf.printf "ending %s with %d\n%!" name v;
    v
  in
  let pa =
    Env.bind 40
      (fun () -> Async.async (task "a"))
  in
  let pb =
    Env.bind 2
      (fun () -> Async.async (task "b"))
  in
  let pc =
    Async.async
      (fun () -> Async.await pa + Async.await pb)
  in
  Printf.printf "Sum is %d\n" (Async.await pc);
  assert Async.(await pa + await pb = await pc)

let _ = Async.run main

(* The following program would deadlock if cyclic
   promise resolution was allowed *)
(* let try_deadlock () =
 *   let pr = ref (fun () -> assert false) in
 *   let task () =
 *     Async.await (!pr ())
 *   in
 *   print_endline "Fork task";
 *   let pr' = Async.async task in
 *   pr := (fun () -> pr');
 *   print_endline "Await";
 *   Async.await (!pr ())
 *
 * let _ = Async.run try_deadlock *)
