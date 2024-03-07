(lang dune 3.8)
(using mode_specific_stubs 0.1)

(name multicont)

(generate_opam_files true)

(source
 (github dhil/ocaml-multicont))

(authors "Daniel Hillerström")
(maintainers "Daniel Hillerström")

(license MIT)

; (documentation https://url/to/documentation)

(package
 (name multicont)
 (synopsis "Multi-shot continuations in OCaml")
 (description "This library provides facilities for programming with multi-shot continuations in OCaml")
 (depends (ocaml (>= 5.0.0))
           dune
          (dune-configurator (>= 3.8)))
 (tags
  ("multi-shot continuations" "effect handlers")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
