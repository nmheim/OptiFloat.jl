[![Documentation](https://github.com/nmheim/OptiFloat.jl/actions/workflows/documenter.yml/badge.svg)](https://github.com/nmheim/OptiFloat.jl/actions/workflows/documenter.yml)
[![Run tests](https://github.com/nmheim/OptiFloat.jl/actions/workflows/runtests.yml/badge.svg)](https://github.com/nmheim/OptiFloat.jl/actions/workflows/runtests.yml)

# OptiFloat.jl

OptiFloat.jl rewrites floating point expressions to more accurate alternatives.
It is a pure **Julia implementation of [Herbie](https://herbie.uwplse.org/)**.
To learn more about what OptiFloat does, how to use it, and how it works check out the [**documentation**](https://nmheim.github.io/OptiFloat.jl/).

## Install

> [!IMPORTANT]
> OptiFloat.jl currently requires Julia 1.11.

To install OptiFloat.jl, start `julia`, enter the package REPL via `]` and type
```julia
pkg> add https://github.com/nmheim/OptiFloat.jl
```


## Acknowledgements

`OptiFloat.jl` is built on top of a number of great Julia packages. Most notably:

- [`Metatheory.jl`](https://github.com/JuliaSymbolics/Metatheory.jl) for everything related to expression rewriting & simplification.
- [`DynamicExpressions.jl`](https://github.com/SymbolicML/DynamicExpressions.jl) for computing local errors of floating point expressions.
- [`IntervalArithmetic.jl`](https://github.com/JuliaIntervals/IntervalArithmetic.jl) to evaluate expressions on `Interval{BigFloat}` with arbitrary precision.
