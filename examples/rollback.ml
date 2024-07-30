(* Modular rollback parsing. Adapted from Lindley et al. (2017),
   c.f. https://arxiv.org/pdf/1611.09259.pdf *)

module IO = struct
  let attrs = Unix.(tcgetattr stdin)
  let buf = Bytes.create 1
  (* Restore terminal defaults at exit. *)
  let _ = at_exit (fun _ -> Unix.(tcsetattr stdin TCSAFLUSH attrs))

  let get_char () =
    (* Disable canonical processing and echoing of input
       characters. *)
    Unix.(tcsetattr stdin TCSAFLUSH
            { attrs with c_icanon = false; c_echo = false; c_vmin = 1; c_vtime = 0 });
    let len = Unix.(read stdin) buf 0 1 in
    if len = 0 then raise End_of_file
    else Bytes.get buf 0

  let put_char ch =
    Bytes.set buf 0 ch;
    let len = Unix.(write stdout buf 0 1) in
    if len = 0 then raise (Failure "write failed")

  let backspace () =
    put_char '\b'; put_char ' '; put_char '\b'
end

type _ Effect.t += Peek : (unit -> char) Effect.t (* Returning a thunk is necessary to avoid a memory leak. See below. *)
                 | Accept : unit Effect.t

exception Abort

let peek : unit -> char
  = fun () -> (Effect.perform Peek) ()

let accept : unit -> unit
  = fun () -> Effect.perform Accept

let abort : unit -> 'a
  = fun () -> raise Abort

type 'a log = Start of (unit -> 'a)
            | Inched of 'a state * ((unit -> char), ('a state -> 'a)) Multicont.Deep.resumption
            | Ouched of 'a state
and 'a state = { log: 'a log; buf: char option }

let rec input : (unit -> 'a) -> 'a state -> 'a
  = fun f ->
  match f () with
    | ans -> (fun _ -> ans)
    | exception Abort -> (fun st -> rollback st)
    | effect Peek, k -> (fun st ->
       let open Multicont.Deep in
       let r = promote k in
       match st.buf with
       | Some c -> resume r (fun () -> c) st
       | None -> match IO.get_char () with
                 | '\b' -> IO.backspace (); rollback st
                 | c -> let st' = { log = Inched (st, r); buf = Some c } in
                        resume r (fun () -> c) st')
    | effect Accept, k -> (fun st ->
      let open Multicont.Deep in
      let r = promote k in
      match st.buf with
      | Some c -> IO.put_char c;
                  let st' = { log = Ouched st; buf = None } in
                  resume r () st'
      | None -> let st' = { st with buf = None } in
                resume r () st')
and rollback : 'a state -> 'a
  = fun st ->
  match st.log with
  | Start f -> parse f
  | Ouched st' -> rollback st'
  | Inched (st', r) ->
     (* Here we want to inject a computation into the
        continuation. Specifically, we want to run the `peek`
        computation at the suspension point. For this reason the
        operation `Peek` returns a thunk of type `unit ->
        char`. Alternatively, we could wrap the composition `peek ();
        resume_with r (Input l None)` in an identity handler. Though,
        this introduces to a memory leak.*)
     let open Multicont.Deep in
     resume r peek { st' with buf = None }
and parse : (unit -> 'a) -> 'a
  = fun f ->
  input f { log = Start f; buf = None }

let rec zeros : int -> int
  = fun n ->
  match peek () with
  | '0' -> accept (); zeros (n+1)
  | ' ' -> accept (); n
  | _   -> abort ()

let _t1 () =
  let i = parse (fun () -> zeros 0) in
  Printf.printf "%d\n%!" i

let rec nest : char list -> int -> char list
  = fun cs n ->
  if n = 0
  then match peek () with
       | '('  -> accept (); nest cs 1
       | '\n' -> accept (); cs
       | _    -> abort ()
  else match peek () with
       | '(' -> accept (); nest cs (n + 1)
       | ')' -> accept (); nest cs (n - 1)
       | c   -> accept (); nest (c :: cs) n

let t2 () =
  let cs = List.rev (parse (fun () -> nest [] 0)) in
  Printf.printf "%s\n" (String.init (List.length cs) (fun i -> List.nth cs i))

let _ = t2 ()
