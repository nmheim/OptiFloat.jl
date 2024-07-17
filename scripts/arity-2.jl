using DynamicExpressions
using OptiFloat
using OptiFloat:
    all_subexpressions,
    evaluate_exact,
    sample_bitpattern,
    ulpdistance,
    biterror,
    biterrorscore,
    logsample,
    evaluate_approx,
    recursive_rewrite,
    simplify,
    Candidate,
    local_biterrors,
    optifloat!, infer_regimes, biterror,regimes

# FIXME: sort vector of candidates by mean error

T = Float16
kws = (; binary_operators=[-, ^, /, *, +], unary_operators=[-, sqrt, cbrt, log, exp], variable_names=["b", "c"], node_type=Node{T})
dexpr = parse_expression(:((b*(-1) - sqrt(b^2 - 4c)) / (2c)); kws...)
batchsize = 10000
points = logsample(dexpr, batchsize; eval_exact=false)
candidates = [Candidate(dexpr, dexpr, points)]
optifloat!(candidates, points)


splits = T[-100, -10, -1, 0, 1, 10, 100]
feature = 2
rs = infer_regimes(candidates, splits, feature, points)
feature = 2

map(rs.regs) do r
    rs_ = regimes(candidates, points, r.low, r.high, r.feature)
    feature = 2
    r = infer_regimes(rs_, splits, 2, points[:,r.error_mask])
    r => biterror(r)
end
rs = infer_regimes(rs, splits, feature, points)
display(rs)

biterror(rs, points)
biterror(dexpr, points)
