# OptiFloat.jl


::: tip TL;DR

OptiFloat.jl rewrites floating point expressions to more accurate alternatives.
OptiFloat.jl is a pure **Julia implementation of [Herbie](https://herbie.uwplse.org/)**.

:::

For example, the expression

```@example sqrtexample
f(x) = sqrt(x+1) - sqrt(x)
nothing # hide
```

is inaccurate for `x>1`, because it subtracts two floating point values
that are close together:

```@repl sqrtexample
f(Float16(3730))
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




## Workflow

::: warning This package is a work in progress

This package only contains a proof of concept of a few simple examples.
The following section shows how OptiFloat.jl currently works.

:::


OptiFloat.jl implements the Herbie approach to floating point expression optimization:

1. Given an initial expression `expr`, compute the _local error_ of every subexpression and pick the subexpression `sub_expr` with the worst error for further analysis.
2. Recursively rewrite the `sub_expr` based on a _set of rewrite rules_, generating a number of new _candidates_.
3. Simplify the candidates via equality saturation (implemented in [Metatheory.jl](https://github.com/JuliaSymbolics/Metatheory.jl))
4. Rewrite `expr` with the candidates to generate alternatives to `expr`.
5. Keep track of all alternatives to `expr` (and their errors) in a table. Pick the next unused expression from that table and start from step 1. Finish after a number of steps or when all alternatives have been tested.
6. Finally, infer good _regimes_: There might not be one expression that performs well for all inputs. OptiFloat.jl (like Herbie) infers good intervals for the different alternative expression and produces one compound expression.


### Local biterror

OptiFloat.jl computes the _biterror_ of an expression by comparing the _exact
result_ of an expression (computed via
[IntervalArithmetic.jl](https://github.com/JuliaIntervals/IntervalArithmetic.jl))
with the 'normal'/'approximate' result (further called floating point evaluation).

For example, we can compute The `biterror` defined as the logarithm of the
ULP-distance (unit at the last place) `biterror(x,y) = log2(ulpdistance(x,y))`
for the example above to approximately 11 bits:

```@repl sqrtexample
using OptiFloat: biterror

x = Float16(3730)
biterror(f(x), g(x))
```

The _local_ biterror is computed by exactly evaluating the input arguments to a
given function/operator `f`, and computing the biterror between the floating point and exact evaluations of `f`. Below you can see how this is done with [DynamicExpressions.jl](https://github.com/SymbolicML/DynamicExpressions.jl) to avoid frequent calls to `eval` for subexpression evaluation.

```@example sqrtexample
using DynamicExpressions
using DynamicExpressions: Node
using OptiFloat: local_biterrors, logsample

T = Float16
orig_expr = :(sqrt(x + 1) - sqrt(x))
arity = 1
dexpr = parse_expression(orig_expr;
    binary_operators=[-, ^, /, *, +],
    unary_operators=[-, sqrt],
    node_type=Node{T},
    variable_names=["x"],
)
points = logsample(dexpr, T, arity, 8000)
local_biterrors(dexpr, points)
```


## Documentation

```@autodocs
Modules=[OptiFloat]
```
