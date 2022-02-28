(**
 * Simulation of multihandlers in terms of unary handlers.
 *)

open Effect
open Shallow

(* Binary handler *)
type ('c, 'd) binaryhandler =
  { retc' : (
let resume_with : (unit, 'c) continuation -> (unit, 'c) continuation -> ('c, 'd) binaryhandler -> 'd
  = fun k k' h -> assert false
