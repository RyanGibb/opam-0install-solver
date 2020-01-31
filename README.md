# Introduction

Opam's default solver is designed to maintain a set of packages over time,
minimising disruption when installing new programs and finding a compromise
solution across all packages (e.g. avoiding upgrading some library to prevent
uninstalling another program).

In many situations (e.g. a CI system building in a clean environment, a
project-local opam root, or a duniverse build) this is not necessary, and we
can get a solution much faster by using a different algorithm.

This package uses 0install's (pure OCaml) solver with opam packages.

# Usage

Run the `opam-zi` binary with the packages you want to install:

```bash
$ dune exec -- opam-zi utop
[NOTE] Opam library initialised in 0.16 s
base-bigarray.base base-bytes.base base-threads.base base-unix.base camomile.1.0.2 charInfo_width.1.1.0 conf-m4.1 cppo.1.6.6 dune.2.1.3 dune-configurator.2.1.3 dune-private-libs.2.1.3 lambda-term.2.0.3 lwt.5.1.1 lwt_log.1.1.1 lwt_react.1.1.3 mmap.1.1.0 ocaml.4.09.0 ocaml-base-compiler.4.09.0 ocaml-config.1 ocamlbuild.0.14.0 ocamlfind.1.8.1 ocplib-endian.1.0 react.1.2.1 result.1.4 seq.base topkg.1.0.1 utop.2.4.3 zed.2.0.4
[NOTE] Solve took 0.25 s
```

It outputs the set of packages that should be installed (but doesn't install them itself).
The output is in a format suitable for use as input to `opam`. e.g.

```bash
opam install $(opam-zi utop)
```

Note that it does not look at the current switch's OCaml version and may therefore choose a newer (or older) one.
You can pass the version explicitly to constrain it. e.g.

```bash
opam-zi utop ocaml.4.08.1
```

or

```bash
opam-zi utop 'ocaml<4.09'
```

You can also pass other packages and constraints here too, as with opam itself.
`opam-zi` will optimise the packages in order, so `opam-zi foo bar` will always pick the
newest possible version of `foo`, even if that means choosing an older version of `bar`
(but it will choose an older version of `foo` if there is no other way to get `bar` at all).

# Tests

Running `make test` will run various tests (some fixed and some random) using
both opam-zi and opam's solver and compare the results.

When testing changes to the code, you may want to run `dune exec -- ./test/dump.exe NN`
before and afterwards (`NN` is the number of processes to use to speed it up;
use the number of cores your machine has). This takes each package name in
opam-repository and solves for it individually, generating a CSV file with the
solutions. Depending on the speed of your computer, this is likely to take
several minutes.

# Internals

The core 0install solver does not depend on the rest of 0install and just
provides a functor that can be instantiated with whatever package system you
like (see [Simplifying the Solver With Functors][]).

- The `zi-solver` directory contains a copy of 0install's `solver` directory.
- The `lib` directory applies this to opam.

`zi-solver/s.ml` describes the interface required by `zi-solver`.
`lib/model.ml` maps opam concepts onto 0install ones. It's a little
complicated because 0install doesn't support alternatives in dependencies (e.g.
`ocaml-config` depends on `"ocaml-base-compiler" | "ocaml-variants" |
"ocaml-system"`). The mapping introduces a "virtual" package in these cases
(so `ocaml-config` depends on a virtual package that has three available versions,
with dependencies on the real packages).

A virtual package is also created if you specify multiple packages on the command-line.

# License

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA

[Simplifying the Solver With Functors]: https://roscidus.com/blog/blog/2014/09/17/simplifying-the-solver-with-functors/
