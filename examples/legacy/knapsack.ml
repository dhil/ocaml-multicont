(* Solving the knapsack problem with continuations *)

type response = Skip
              | Take

type _ Effect.t += Pick : int * int -> response Effect.t

let pick i c = Effect.perform (Pick (i, c))

let hmemo ps ws cap =
  let open Effect.Deep in
  let recall =
    Array.make_matrix (Array.length ps) (cap+1) (-1)
  in
  { retc = (fun ans -> ans)
  ; exnc = raise
  ; effc = (fun (type a) (eff : a Effect.t) ->
    match eff with
    | Pick (i, c) ->
       Some (fun (k : (a, _) continuation) ->
           let open Multicont.Deep in
           let r = promote k in
           let payoff = recall.(i).(c) in
           if payoff < 0
           then if ws.(i) <= c
                then let tt = ps.(i) + resume r Take in
                     let ff = resume r Skip in
                     let ans = max tt ff in
                     recall.(i).(c) <- ans;
                     ans
                else let ans = resume r Skip in
                     recall.(i).(c) <- ans;
                     ans
           else payoff)
    | _ -> None) }

(** A fast implementation of knapsack that uses an oracle to pick
    elements. The time complexity is pseudo-quadratic O(|ps| * c) *)
let knapsack : int array -> int array -> int -> int
  = fun ps ws cap ->
  assert (Array.length ps = Array.length ws);
  assert (cap >= 0);
  let rec solver i n c =
    if i >= n || c <= 0 then 0
    else match pick i c with
         | Take -> solver (i + 1) n (c - ws.(i))
         | Skip -> solver (i + 1) n c
  in
  Effect.Deep.match_with (fun () -> solver 0 (Array.length ps) cap) () (hmemo ps ws cap)

let _ =
  let inputs =
    [ ([|4;5;6|], [|1;3;2|], 4)
    ; ([|4;5;6|], [|1;3;2|], 6)
    ; ([|1;2;3|], [|4;5;1|], 4)
    ; ([|10;15;40|], [|1;2;3|], 6)
    ; ([|60;100;120|], [|10;20;30|], 50)
    ; ([|135;139;149;150;156;163;173;184;192;201;210;214;221;229;240|], [|70;73;77;80;82;87;90;94;98;106;110;113;115;118;120|], 750)
    ; ([| 360; 83; 59; 130; 431; 67; 230; 52; 93; 125; 670; 892; 600; 38; 48; 147; 78; 256; 63; 17; 120; 164; 432; 35; 92; 110; 22; 42; 50; 323; 514; 28; 87; 73; 78; 15; 26; 78; 210; 36; 85; 189; 274; 43; 33; 10; 19; 389; 276; 312|], [|7; 0; 30; 22; 80; 94; 11; 81; 70; 64; 59; 18; 0; 36; 3; 8; 15; 42; 9; 0; 42; 47; 52; 32; 26; 48; 55; 6; 29; 84; 2; 4; 18; 56; 7; 29; 93; 44; 71; 3; 86; 66; 31; 65; 0; 79; 20; 65; 52; 13|], 850) ]
  in
  List.iter (fun (ps, ws, c) -> print_endline (string_of_int (knapsack ps ws c))) inputs
