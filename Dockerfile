FROM alpine:3.20 AS base

FROM base AS builder

RUN apk update && \
    apk upgrade && \
    apk add -i linux-headers build-base opam

RUN opam init --bare -a -y --disable-sandboxing \
    && opam update

RUN opam switch create default ocaml-base-compiler.5.2.0

RUN opam install -y dune

WORKDIR /app

COPY dune-project dune  *.opam ./

RUN opam install . --deps-only -y

COPY main.ml ./

# eval $(opam config env) applies dune to PATH but it only persists in a single RUN layer
RUN eval $(opam config env) \
    && dune build main.exe

FROM base AS runner

WORKDIR /app

COPY --from=builder /app/_build/default/main.exe /app

CMD [ "/app/main.exe" ]