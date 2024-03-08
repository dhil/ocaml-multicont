module C = Configurator.V1

let detect_native_compiler ocamlc =
  let input_lines ic =
    let ans = ref [] in
    let rec next_line ic =
      ans := input_line ic :: !ans;
      next_line ic
    in
    (try next_line ic with _ -> ());
    !ans
  in
  try
    let ic = Unix.open_process_in (Filename.quote_command ocamlc ["-config"]) in
    let lines = input_lines ic in
    ignore (Unix.close_process_in ic);
    List.exists (fun s -> String.equal s "native_compiler: true") lines
  with _ -> false

let make_stanzas native testname =
  let stanzas exe_prefix =
    let output =
      Printf.sprintf
        "(rule\n\
         \ (with-stdout-to %s.output\n\
         \ (setenv \"LD_LIBRARY_PATH\" \".\"\n\
         \ (run %s/examples/%s.exe))))"
        exe_prefix "%{workspace_root}" exe_prefix
    in
    let runtest =
      Printf.sprintf
        "(rule\n\
         \ (alias runtest)\n\
         \ (action (diff %s.expected %s.output)))"
        testname exe_prefix
    in
    [output; ""; runtest; ""]
  in
  let bc = stanzas (Printf.sprintf "%s.bc" testname) in
  let nc = if native then stanzas testname else [] in
  (Printf.sprintf "; %s tests" testname) :: (nc @ bc)

let write_content filename stanzas =
  let stanzas =
    List.concat (List.map (String.split_on_char '\n') stanzas)
  in
  C.Flags.write_lines filename stanzas

let _ =
  let testnames =
    ["async"; "choice"; "generic_count"; "nqueens"; "supervised"]
  in
  let incfile = ref "tests.inc" in
  let is_native_available = ref false in
  C.main ~name:"tests"
    ~args:[
      "-ocamlc", Arg.String (fun ocamlc ->
                     is_native_available := detect_native_compiler ocamlc),
      "Name of the ocamlc executable";
      "-output", Arg.String (fun s -> incfile := s),
      "Name for the tests sexp output (default tests.inc)"
    ]
    (fun _ ->
      write_content !incfile (List.concat (List.map (make_stanzas !is_native_available) testnames)))
