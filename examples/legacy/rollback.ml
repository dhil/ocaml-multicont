(* Modular rollback parsing. Adapted from Lindley et al. (2017),
   c.f. https://arxiv.org/pdf/1611.09259.pdf *)

module IO = struct
  let term_io = Unix.(tcgetattr stdin)

  let get_char () =
    (* Disable canonical processing and echoing of input
       characters. *)
    Unix.(tcsetattr
            stdin
            TCSADRAIN
            { term_io with c_icanon = false; c_echo = false });
    let ch = input_char stdin in
    (* Restore terminal defaults. *)
    Unix.(tcsetattr stdin TCSADRAIN term_io);
    ch

  let put_char ch =
    output_char stdout ch; flush stdout
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

type 'a log = Start of (unit, 'a) Multicont.Shallow.resumption
            | Inched of 'a log * ((unit -> char), 'a) Multicont.Shallow.resumption
            | Ouched of 'a log


(* let identity : ('a, 'a) Effect.Shallow.handler
 *   = { retc = (fun x -> x)
 *     ; exnc = (fun e -> raise e)
 *     ; effc = (fun (type a) (_ : a Effect.t) -> None) } *)

let rec input : 'a log -> char option -> ('a, 'a) Effect.Shallow.handler
  = fun l buf ->
  let open Effect.Shallow in
  { retc = (fun x -> x)
  ; exnc = (function Abort -> rollback l | e -> raise e)
  ; effc = (fun (type a) (eff : a Effect.t) ->
    match eff with
    | Peek -> Some (fun (k : (a, _) continuation) ->
                  let open Multicont.Shallow in
                  let r = promote k in
                  match buf with
                  | Some c -> resume_with r (fun () -> c) (input l buf)
                  | None -> match IO.get_char () with
                            | '\b' -> rollback l
                            | c -> resume_with r (fun () -> c) (input (Inched (l, r)) (Some c)))
    | Accept -> Some (fun (k : (a, _) continuation) ->
                    let open Multicont.Shallow in
                    let r = promote k in
                    match buf with
                    | Some c -> IO.put_char c;
                                resume_with r () (input (Ouched l) None)
                    | None -> resume_with r () (input l None))
    | _ -> None) }
and rollback : 'a log -> 'a = function
  | Start p -> parse p
  | Ouched l -> IO.put_char '\b';
                rollback l
  | Inched (l, r) ->
     (* Here we want to inject a computation into the
        continuation. Specifically, we want to run the `peek`
        computation at the suspension point. For this reason the
        operation `Peek` returns a thunk of type `unit ->
        char`. Alternatively, we could wrap the composition `peek ();
        resume_with r (Input l None)` in an identity handler. Though,
        this introduces to a memory leak.*)
     let open Multicont.Shallow in
     resume_with r peek (input l None)
and parse : (unit, 'a) Multicont.Shallow.resumption -> 'a
  = fun r ->
  let open Multicont.Shallow in
  resume_with r () (input (Start r) None)

let rec zeros : int -> int
  = fun n ->
  match peek () with
  | '0' -> accept (); zeros (n+1)
  | ' ' -> accept (); n
  | _   -> abort ()

let _t1 () =
  let open Effect.Shallow in
  let open Multicont.Shallow in
  let i = parse (promote (fiber (fun () -> zeros 0))) in
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
  let open Effect.Shallow in
  let open Multicont.Shallow in
  let cs = List.rev (parse (promote (fiber (fun () -> nest [] 0)))) in
  Printf.printf "%s\n" (String.init (List.length cs) (fun i -> List.nth cs i))

let _ = t2 ()
