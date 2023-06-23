module C = Configurator.V1

let byte_flags = ref []
let native_flags = ref ["-DNATIVE_CODE"]

let add_native_flag flag =
  native_flags := flag :: !native_flags

let add_flag flag =
  byte_flags := flag :: !byte_flags;
  add_native_flag flag

let () =
  let open Arg in
  let usage = "configure [-UNIQUE_FIBER | -MMAP_STACK]" in
  let speclist =
    [ ("-UNIQUE_FIBERS", Unit (fun () -> add_flag "-DUNIQUE_FIBERS"), "Preserve fiber uniqueness")
    ; ("-MMAP_STACK", Unit (fun () -> add_flag "-DUSE_MMAP_MAP_STACK"), "Use mmap mapped stacks for fiber clones") ]
  in
  parse speclist (fun s -> raise (Invalid_argument s)) usage;
  C.Flags.write_sexp "c_byte_flags.sexp" !byte_flags;
  C.Flags.write_sexp "c_native_flags.sexp" !native_flags
