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

let make_diff_stanzas is_version_53 native testname =
  let stanzas exe_prefix =
    let output legacy =
      Printf.sprintf
        "(rule\n\
         \ (with-stdout-to %s%s.output\n\
         \ (setenv \"LD_LIBRARY_PATH\" \".\"\n\
         \   (run %s/examples/%s%s.exe))))"
        exe_prefix (if legacy then "-legacy" else "")
        "%{workspace_root}" (if legacy then "legacy/" else "") exe_prefix
    in
    let runtest legacy =
      Printf.sprintf
        "(rule\n\
         \ (alias runtest)\n\
         \ (action (diff %s.expected %s%s.output)))"
        testname exe_prefix (if legacy then "-legacy" else "")
    in
    let _53_tests =
      if is_version_53
      then [output false; ""; runtest false; ""]
      else []
    in
    _53_tests @ [output true; ""; runtest true; ""]
  in
  let bc = stanzas (Printf.sprintf "%s.bc" testname) in
  let nc = if native then stanzas testname else [] in
  (Printf.sprintf "; %s tests" testname) :: (nc @ bc)

let write_content filename stanzas =
  let stanzas =
    List.concat (List.map (String.split_on_char '\n') stanzas)
  in
  C.Flags.write_lines filename stanzas

(* Currently only for the test/lib/unique_fibers.ml test *)
let make_nondiff_stanzas native testname : string list =
  let stanza exe_prefix =
    Printf.sprintf
      "(rule\n\
       \ (alias runtest)\n\
       \ (action\n\
       \   (setenv \"TEST_UNIQUE_FIBERS\" \"%s\"\n\
       \     (setenv \"LD_LIBRARY_PATH\" \".\"\n\
       \       (run %s/test/lib/%s.exe)))))"
      (match Sys.getenv_opt "UNIQUE_FIBERS" with
       | Some "1" -> "true" | _ -> "false")
      "%{workspace_root}" exe_prefix
  in
  let bc = stanza (Printf.sprintf "%s.bc" testname) in
  let nc = if native then [stanza testname] else [] in
  (Printf.sprintf "; %s tests" testname) :: bc :: "" :: nc

let _ =
  let diff_testnames =
    ["async"; "choice"; "generic_count"; "knapsack"; "nqueens"; "return"; "supervised"; "tautology"]
  in
  let nondiff_testnames =
    ["unique_fibers"]
  in
  let incfile = ref "tests.inc" in
  let is_native_available = ref false in
  let is_version_53 = ref false in
  C.main ~name:"tests"
    ~args:[
      "-ocamlc", Arg.String (fun ocamlc ->
                     is_native_available := detect_native_compiler ocamlc),
      "Name of the ocamlc executable";
      "-ocaml_version", Arg.String (fun version ->
                            is_version_53 := String.length version >= 3
                                             && Char.compare (String.get version 0) '5' >= 0
                                             && Char.compare (String.get version 2) '3' >= 0),
      "OCaml version";
      "-output", Arg.String (fun s -> incfile := s),
      "Name for the tests sexp output (default tests.inc)"
    ]
    (fun _ ->
      let diff_tests = List.map (make_diff_stanzas !is_version_53 !is_native_available) diff_testnames in
      let nondiff_tests = List.map (make_nondiff_stanzas !is_native_available) nondiff_testnames in
      write_content !incfile (List.concat [List.concat diff_tests; List.concat nondiff_tests]))
