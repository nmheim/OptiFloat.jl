# Usage

OptiFloat.jl defines a macro [`@optifloat`](@ref) which kicks of the floating point expression optimization
and defines a new, potentially more accurrate function:

```@example Usage
using OptiFloat

# original
f(b, c) = (-b - sqrt(b^2 - 4c)) / (2c)

# improved
g = @optifloat (-b - sqrt(b^2 - 4c)) / (2c) batchsize=1000 T=Float16
```

The original function `f` is inaccurate for large, negative `b`:
```@repl Usage
f(Float16(-200), Float16(-0.1))  # low-precision, inaccurate
f(-200.0, -0.1)                  # high-precision, accurate
```

The improved function `g` gives almost the same result as `f`:
```@repl Usage
g(Float16(-200), Float16(-0.1))  # low-precision, accurate
```

If we are interested in the underlying expression of `g`, we can use the
function [`optifloat`](@ref) (as opposed to the macro `@optifloat`) which
returns an [`OptiFloatResult`](@ref) that is pretty printed as a informative
report:
```@ansi Usage
expr = :((-b - sqrt(b^2 - 4c)) / (2c));
result = optifloat(expr; batchsize=1000, T=Float16)
```

The `result` holds e.g. the expression of the final, improved function:
```@repl Usage
result.improved
```

## Verbose output / debug logs

For more verbose outputs of OptiFloats optimization process you can enable debug
logging for the package:
```julia
# enable debug logging for OptiFloat only
ENV["JULIA_DEBUG"] = OptiFloat

# calls to optifloat/@optifloat will print debug information
optifloat(expr; batchsize=1000, T=Float16)
```
