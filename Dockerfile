# syntax=docker/dockerfile:1

FROM ubuntu:24.10 AS base

FROM base AS opam

RUN apt-get update \
    && apt-get upgrade -y

RUN apt-get install -y opam

# --disable-sandboxing is needed due to bwrap: No permissions to creating new namespace error
RUN opam init --bare -a -y --disable-sandboxing && opam update

RUN opam switch create default ocaml-base-compiler.5.2.0

FROM opam AS builder

WORKDIR /app

COPY dune-project dune-workspace dune  *.opam ./

RUN opam install . --depext-only --yes --confirm-level=unsafe-yes

RUN opam install . --deps-only --assume-depexts --yes

COPY *.ml ./

RUN opam exec dune build

CMD [ "opam" "exec" "dune" "exec" "load_test" ]

FROM base AS runner

WORKDIR /app

COPY --from=builder /app/_build/default/main.exe /app

CMD [ "/app/main.exe" ]

FROM opam AS dev

RUN opam install utop dune --yes

WORKDIR /app