# Compiling and running the legacy examples

The legacy examples do not make use of the effect handler syntax added
in OCaml 5.3. To compile and run the examples suite you must first
have installed the library via OPAM. In order to build the suite
simply invoke `dune`, i.e.

```shell
$ dune build
```

After successfully building the suite you can run each example via
`dune`, which will run either the native or bytecode version of an
example depending on which suffix you supply, e.g. to run the native
version type

```shell
$ dune exec ./nqueens.exe
```

and for the bytecode version type

```shell
$ dune exec ./nqueens.bc.exe
```