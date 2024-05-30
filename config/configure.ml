module C = Configurator.V1

let byte_flags = ref []
let native_flags = ref ["-DNATIVE_CODE"]

let add_native_flag flag =
  native_flags := flag :: !native_flags

let add_flag flag =
  byte_flags := flag :: !byte_flags;
  add_native_flag flag

let () =
  let is_dev_profile =
    try
      let arg = Array.get Sys.argv 1 in
      String.equal arg "dev"
    with
    | Invalid_argument _ -> false
  in
  let () =
    if is_dev_profile then
      let debug_options =
        [ "-Wall"; "-Wextra"; "-Wpedantic"
        ; "-Wformat=2"; "-Wno-unused-parameter"; "-Wshadow"
        ; "-Wwrite-strings"; "-Wstrict-prototypes"; "-Wold-style-definition"
        ; "-Wredundant-decls"; "-Wnested-externs"; "-Wmissing-include-dirs" ]
      in
      List.iter add_flag debug_options
  in
  let options =
    [ "UNIQUE_FIBERS" ]
  in
  let toggle option =
    match Sys.getenv_opt option with
    | Some "1" ->
       add_flag (Printf.sprintf "-D%s" option)
    | _ -> ()
  in
  List.iter toggle options;
  C.Flags.write_sexp "c_byte_flags.sexp" !byte_flags;
  C.Flags.write_sexp "c_native_flags.sexp" !native_flags
