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

open Effect
type _ eff += Peek : char eff
   | Accept : unit eff

exception Abort

let peek : unit -> char
  = fun () -> perform Peek

let accept : unit -> unit
  = fun () -> perform Accept

let abort : unit -> 'a
  = fun () -> raise Abort

type 'a log = Start of (unit, 'a) Multicont.Shallow.resumption
            | Inched of 'a log * (char, 'a) Multicont.Shallow.resumption
            | Ouched of 'a log


let identity : ('a, 'a) Shallow.handler
  = { retc = (fun x -> x)
    ; exnc = (fun e -> raise e)
    ; effc = (fun (type a) (_ : a eff) -> None) }

let rec input : 'a log -> char option -> ('a, 'a) Shallow.handler
  = fun l buf ->
  let open Shallow in
  { retc = (fun x -> x)
  ; exnc = (function Abort -> rollback l | e -> raise e)
  ; effc = (fun (type a) (eff : a eff) ->
    match eff with
    | Peek -> Some (fun (k : (a, _) continuation) ->
                  let open Multicont.Shallow in
                  let r = promote k in
                  match buf with
                  | Some c -> resume_with r c (input l buf)
                  | None -> match IO.get_char () with
                            | '\b' -> rollback l
                            | c -> resume_with r c (input (Inched (l, r)) (Some c)))
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
                IO.put_char ' ';
                IO.put_char '\b';
                rollback l
  | Inched (l, r) ->
     let open Multicont.Shallow in
     (* Memory leak *)
     let f = promote (Shallow.fiber (fun () ->
                          resume_with r (peek ()) identity))
     in
     resume_with f () (input l None)
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

let t1 () =
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
  let cs = parse (promote (fiber (fun () -> nest [] 0))) in
  Printf.printf "%s\n" (String.init (List.length cs) (fun i -> List.nth cs i))

let _ = t2 ()
