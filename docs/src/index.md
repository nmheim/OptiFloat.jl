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

is inaccurate for `x>1`, because it subtracts two floating point values that are
close to each other. Calling `f` with e.g. a `Float16` we get an inaccurate result:

```@repl sqrtexample
f(Float16(3730))
```

Compare to the more accurate `Float64` result:
```@repl sqrtexample
f(3730.0)
```

OptiFloat.jl rewrites this expression to a more accurate equivalent (*using the original, low precision `Float16`!*):
```@example sqrtexample
using OptiFloat

result = @optifloat sqrt(x+1)-sqrt(x) T=Float16 batchsize=100
g = eval(result.improved)
result.improved
```

```@repl sqrtexample
g(Float16(3730))
```

If we plot `g` we can see that it matches the more costly, higher precision
evaluation of `f`:

```@example sqrtexample
using CairoMakie

fig = Figure()
a1 = Axis(fig[1, 1]; xscale=log10, xlabel="x", ylabel="f(x)")
xs = Float16.(logrange(1, 4000, length=100))
lines!(
    a1, xs, f.(xs);
    color=1, colorrange=(1, 10), colormap=:tab10, linewidth=3,
    label="f(x) = sqrt(x+1) - sqrt(x) (Float16)"
)
lines!(
    a1, xs, f.(Float64.(xs));
    color=2, colorrange=(1, 10), colormap=:tab10, linewidth=3,
    label="f(x) = sqrt(x+1) - sqrt(x) (Float64)"
)
lines!(
    a1, xs, g.(xs);
    color=3, colorrange=(1, 10), colormap=:tab10, linestyle=:dash,
    label="g(x) = 1/(sqrt(x+1) + sqrt(x)) (Float16)", linewidth=3
)
axislegend(a1)
fig
```

::: info

For more details on how `OptiFloat.jl` works and how to customize it to your
needs, check out OptiFloat [under the hood](internals.md).

:::


## Acknowledgements

`OptiFloat.jl` is built on top of a number of great Julia packages. Most notably:

- [`Metatheory.jl`](https://github.com/JuliaSymbolics/Metatheory.jl) for everything related to expression rewriting & simplification.
- [`DynamicExpressions.jl`](https://github.com/SymbolicML/DynamicExpressions.jl) for computing local errors of floating point expressions.
- [`IntervalArithmetic.jl`](https://github.com/JuliaIntervals/IntervalArithmetic.jl) to evaluate expressions on `Interval{BigFloat}` with arbitrary precision.
