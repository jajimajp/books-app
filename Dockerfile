FROM ocaml/opam:debian-12-ocaml-4.14 as build
WORKDIR /build

# Install dependencies.
RUN sudo apt-get update
RUN sudo apt-get install -y libev-dev libpq-dev libgmp-dev pkg-config
ADD . .
RUN opam install --deps-only .

# Build project.
RUN sudo chown -R opam:opam /build
RUN opam exec -- dune build


FROM debian:stable-20250203-slim as run

RUN apt-get update
RUN apt-get install -y libev4 libpq5 libssl3

COPY --from=build /build/_build/default/src/books.exe /bin/books

ENTRYPOINT /bin/books


