module C = Configurator.V1

let common_flags = ["-Wall"; "-Wextra"; "-Wconversion"; "-Wno-sign-conversion"]
let byte_flags = ref common_flags
let native_flags = ref ("-DNATIVE_CODE" :: common_flags)

let add_native_flag flag =
  native_flags := flag :: !native_flags

let add_flag flag =
  byte_flags := flag :: !byte_flags;
  add_native_flag flag

let () =
  let options = [ "USE_MMAP_MAP_STACK"
                ; "UNIQUE_FIBERS"]
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
