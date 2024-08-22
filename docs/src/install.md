# Installation

To install OptiFloat.jl, start `julia`, enter the package REPL via `]` and type
```julia
pkg> add https://github.com/nmheim/OptiFloat.jl
```

# Develop

To work on OptiFloat.jl itself, install the package in development mode.
```julia
pkg> dev https://github.com/nmheim/OptiFloat.jl
```
This should make the source code available in `~/.julia/dev/OptiFloat`.  You can
start julia in the OptiFloat environment with `julia --project=~/.julia/dev/OptiFloat`, and type `]test` to run the tests.


# Building Documentation

OptiFloat's documentation is built with [`DocumenterVitepress.jl`](https://luxdl.github.io/DocumenterVitepress.jl/dev/).

To build the docs, start a julia REPL in the `docs` environment and run `docs/make.jl`:
```julia
julia> include("docs/make.jl")
```

In a *second* terminal in the `docs` directory, run:
```bash
$ npm run docs:dev
```
