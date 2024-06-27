# OptiFloat.jl

Definition: `local-error(expr, points)`
```
for point ∈ points :
    args := evaluate-exact(expr.children)
    exact-ans := F(expr.operation.apply-exact(args))
    approx-ans := expr.operation.apply-approx(F(args))
    accumulate E(exact-ans, approx-ans)
```

Definition `recursive-rewrite(expr, target)`:
```
table = [expr]
for (subexpr, subpattern) ∈ zip(expr.children, input.children) :
    if ¬matches(subexpr, subpattern) :
        e = recursive-rewrite(subexpr, subpattern)
        push!(table, e)
where matches(expr, input)
expr.rewrite(input output)
append new exprs to table
```
