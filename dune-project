(lang dune 3.4)

(package
 (name load_test)
 (depends ocaml dune eio_main ezcurl cohttp-eio piaf mirage-crypto-rng-eio ca-certs tls-eio))

(generate_opam_files true)
