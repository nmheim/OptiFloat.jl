using DynamicExpressions
using Metatheory
using Metatheory.Rewriters
using OptiFloat
using OptiFloat:
    sample_bitpattern,
    logsample,
    Candidate,
    optifloat!,
    infer_regimes, regimes_to_expr_1d


T = Float16
# orig_expr = :(sqrt(x + 1) - sqrt(x))
orig_expr = :(x*(-1) - sqrt(x^2 - 1))
kws = (;
    binary_operators=[-, ^, /, *, +],
    unary_operators=[-, sqrt, abs, exp, log, cbrt],
    node_type=Node{T},
    variable_names=["x"],
)
dexpr = parse_expression(orig_expr; kws...)
points = logsample(dexpr, T, arity(dexpr), 8000, eval_exact=false)
candidates = [Candidate(dexpr, dexpr, points)]
optifloat!(candidates, points)

splits = [
    T[-100],
    T[-10],
    T[-1],
    T[0],
    T[1],
    T[10],
    T[100],
]
rs = infer_regimes(dexpr, candidates, splits, points)
better = regimes_to_expr_1d(rs)
b = eval(Expr(:->, :x, better))


cs = [candidates[1], candidates[8]]
#OptiFloat.best_candidate(candidates[1:20], points, T[-Inf], T[0])
OptiFloat.best_candidate(cs, points, T[-Inf], T[0])
@btime OptiFloat.best_candidate($cs, $points, T[-Inf], T[0])
@profview OptiFloat.best_candidate(candidates[1:20], points, T[-Inf], T[0])
