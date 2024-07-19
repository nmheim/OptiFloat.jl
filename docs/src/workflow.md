# Workflow

::: details Load packages
```@example report
using DynamicExpressions: parse_expression
using OptiFloat: Candidate, logsample, optifloat!, infer_regimes, print_report
using Random

# FIXME: sometimes getting NaI in logsample
Random.seed!(1);
```
:::

Define expression.
```@example report
T = Float16
expr = :((b * (-1) - sqrt(b^2 - 4c)) / (2c))
dexpr, features = parse_expression(T, expr)
features
```
The `features` contain a mapping from variable name to the index in a sample.
Points can be sampled such that only valid inputs to the expression are generated:
```@example report
batchsize = 1000
points = logsample(dexpr, batchsize; eval_exact=false)
```

The `logsample` function generates logarithmic samples to better cover the space of floating point numbers (which are more dense close to zero). We can plot the samples on a logscale which shows that
`b` (x-axis) and `c` (y-axis) are not sampled where `b^2 - 4c < 0`, because that would result in a `DomainError` in `sqrt`.

![](samples.png)


Create first candidate and kick of `optifloat!`:
```@example report
original = Candidate(dexpr, dexpr, points)
candidates = [original]
optifloat!(candidates, points)
```

::: details Inspect created candidates and average error on all `points`.
```@repl report
candidates
```
:::

Now we have a few candidates, some of which perform much better on some inputs than the original expression. If we were to pick the best expression for every point, we would end up with a lot of costly if statements, and overfit on the `points` that we evaluated the expression with.
For example, the two best expressions in this case are:
- The original: `(-b - sqrt(b^2 - 4c)) / (2c)`
- A new candidate: `((4c) / (sqrt(b ^ 2 - 4c) - b)) / (2c)`

We can plot the samples again, now with different colors for the expression that performs better:

![](samples-compare.png)

To avoid excessive branching/overfitting we try to infer better regimes to split the domain.
```@example report
regimes = infer_regimes(candidates, features["b"], points)
print_report(original, regimes; rm_ansi=true)
```

As we can see, OptiFloat splits the domain close to zero, which is exactly what we want.
