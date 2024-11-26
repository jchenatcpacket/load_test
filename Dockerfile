# syntax=docker/dockerfile:1

FROM ubuntu:24.10 AS base

RUN apt-get update \
    && apt-get upgrade -y

# install system dependencies
RUN apt-get install -y \
    libcurl4-gnutls-dev 

FROM base AS builder

# --disable-sandboxing is needed due to bwrap: No permissions to creating new namespace error
RUN apt-get install -y \
    opam \
    && opam init --bare -a -y --disable-sandboxing \
    && opam update

RUN opam switch create default ocaml-base-compiler.5.2.0

RUN opam install -y dune

WORKDIR /app

COPY dune-project dune  *.opam ./

RUN opam install . --deps-only -y

COPY *.ml ./

# eval $(opam config env) applies dune to PATH but it only persists in a single RUN layer
RUN eval $(opam config env) \
    && dune build main.exe

FROM base AS runner

WORKDIR /app

COPY --from=builder /app/_build/default/main.exe /app

CMD [ "/app/main.exe" ]