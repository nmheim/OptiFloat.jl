# `OptiFloat.jl`

::: warning This package is a work in progress

This package only contains a proof of concept of a few simple examples.
The following section shows how OptiFloat.jl currently works.

:::


## What is OptiFloat?

OptiFloat.jl rewrites floating point expressions to more accurate alternatives.
It is a pure **Julia implementation of [Herbie](https://herbie.uwplse.org/)**.
For example, the function `f`

```@example sqrtexample
f(x) = sqrt(x+1) - sqrt(x)
nothing # hide
```

is inaccurate for `x>1`, because it subtracts two floating point values
that are close together. Called with e.g. `Float16` we get an inaccurate result:

```@repl sqrtexample
f(Float16(3730))
```

Compare to the (more but not totally) correct `Float64` result:
```@repl sqrtexample
f(3730)
```

OptiFloat.jl rewrites this expression to a more accurate equivalent:
```julia
using OptiFloat

g(x) = @optifloat sqrt(x+1)-sqrt(x) x=0:1.79e308
> 1 / (sqrt(x+1) + sqrt(x))
```

```@repl sqrtexample
g(x) = 1 / (sqrt(x+1) + sqrt(x)) # hide
g(Float16(3730))
```
