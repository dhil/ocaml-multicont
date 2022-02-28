(**
  * Basic Bayesian modelling. Adapted from Scibior, Kammar, and Guarani (2018).
  *)

open Effect

type _ eff += Random : float eff
            | Score : float -> unit eff

let random : unit -> float
  = fun () -> perform Random

let score : float -> unit
  = fun r -> perform (Score r)

let bernoulli : float -> bool
  = fun p -> random () < p

let lawn_wet_model : unit -> float
  = fun () ->
  let rain = bernoulli 0.2 in
  let sprinkler = bernoulli 0.1 in
  let prob_lawn_wet =
    match rain, sprinkler with
    | (true, true)   -> 0.99
    | (true, false)  -> 0.7
    | (false, true)  -> 0.9
    | (false, false) -> 0.01
  in
  score prob_lawn_wet; rain
