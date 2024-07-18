using DynamicExpressions
using Metatheory
using Metatheory.Rewriters
using OptiFloat
using OptiFloat:
    sample_bitpattern, logsample, Candidate, optifloat!, infer_regimes, regimes_to_expr_1d

T = Float16
# orig_expr = :(sqrt(x + 1) - sqrt(x))
orig_expr = :(x * (-1) - sqrt(x^2 - 1))
kws = (;
    binary_operators=[-, ^, /, *, +],
    unary_operators=[-, sqrt, abs, exp, log, cbrt],
    node_type=Node{T},
    variable_names=["x"],
)
dexpr = parse_expression(orig_expr; kws...)
#points = logsample(dexpr, 8000, eval_exact=false)
points = logsample(dexpr, 8000; eval_exact=false)
candidates = [Candidate(dexpr, dexpr, points)]
optifloat!(candidates, points)

splits = T[-100, -10, -1, 0, 1, 10, 100]
feature = 1
rs = infer_regimes(candidates, splits, feature, points)
better = regimes_to_expr_1d(rs)
b = eval(Expr(:->, :x, better))
b(100.0)
