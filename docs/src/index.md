# OptiFloat.jl

::: tip TL;DR

OptiFloat.jl rewrites floating point expressions to more accurate alternatives.
OptiFloat.jl is a pure **Julia implementation of [Herbie](https://herbie.uwplse.org/)**.

```@example report
using DynamicExpressions
using OptiFloat
using OptiFloat: logsample, Candidate, optifloat!, infer_regimes, print_report
using Random

# FIXME: sometimes getting NaI in logsample
Random.seed!(1)

# Define expression
T = Float16
kws = (;
    binary_operators=[-, ^, /, *, +],
    unary_operators=[-, sqrt, cbrt, log, exp, abs],
    variable_names=["b", "c"],
    node_type=Node{T},
)
dexpr = parse_expression(:((b * (-1) - sqrt(b^2 - 4c)) / (2c)); kws...)

# Sample points to test expression
batchsize = 1000
points = logsample(dexpr, batchsize; eval_exact=false)

# Create first candidate and kick of optifloat main function
original = Candidate(dexpr, dexpr, points)
candidates = [original]
optifloat!(candidates, points)

splits = T[-100, -10, -1, 0, 1, 10, 100]
feature = 1
rs = infer_regimes(candidates, splits, feature, points)

print_report(original, rs; rmansi=true)
```

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

The steps above are roughly what `OptiFloat.optifloat!` is doing.


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
dexpr = parse_expression(orig_expr;
    binary_operators=[-, ^, /, *, +],
    unary_operators=[-, sqrt],
    node_type=Node{T},
    variable_names=["x"],
)
points = logsample(dexpr, 8000)
local_errs = local_biterrors(dexpr, points)
```

### Recursive rewrites

From the local biterror breakdown above, OptiFloat picks the expression with the
highest error, in this case the top level `-` in `sqrt(x1 + 1.0) - sqrt(x1)` and
tries to apply a set of rewrites defined in `OptiFloat.REWRITE_THEORY`. OptiFloat
also maintains a list of candidates to track which expression have been tried
already.

```@example sqrtexample
using OptiFloat: REWRITE_THEORY, Candidate, recursive_rewrite

candidate = Candidate(dexpr, dexpr, points)
candidates = [candidate]
(err, worst_expr) = findmax(local_errs)
# we should avoid this conversion by using TermInterface.jl on Expression
expr = candidate.toexpr(worst_expr)
# picking only first 3 rewrites for demo
new_candidates = unique(recursive_rewrite(expr, REWRITE_THEORY))[1:3]
```

### Simplify via Metatheory.jl

```julia
using OptiFloat: SIMPLIFY_THEORY, simplify

all_improved = unique(map(new_candidates) do newc
    display(newc)
    simplified = simplify(newc, SIMPLIFY_THEORY; steps=1)
end)

2-element Vector{Expr}:
 :(sqrt(x + 1) - sqrt(x))
 :(1 / (sqrt(x + 1.0) + sqrt(x)))
```

### Update list of candidates

```julia
for simpl in all_simplified
    new_candidate = Candidate(parse_expression(simpl), candidate.orig_expr, points)
    if any([any(new_candidate.errors .< c.errors) for c in candidates])
        push!(candidates, new_candidate)
    end
end
```

### Infer regimes

In this case very simple, because `1/(sqrt(x+1)+sqrt(x))` is better everywhere. See `scripts/infer-regimes.jl` for more interesting example.


## TODOs

- [ ] Use `DynamicExpressions.Expression` throughout the code base so that we don't have to switch to Julia's `Expr` for the EGraph rewrites and back again.
- [x] Include all of herbie's rewrite rules
- [ ] *series expansion rewrites!*
- [ ] Is there a way to do the error computation in the EGraph?

## Documentation

```@autodocs
Modules=[OptiFloat]
```
