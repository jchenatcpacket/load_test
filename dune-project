(lang dune 3.4)

(package
 (name load_test)
 (depends ocaml dune eio_main ezcurl cohttp-eio)
 (allow_empty))

(generate_opam_files true)

