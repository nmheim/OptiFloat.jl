using DynamicExpressions
using OptiFloat
using OptiFloat: logsample, Candidate, optifloat!, infer_regimes, print_report
using Random

# FIXME: sometimes getting NaI in logsample
Random.seed!(1)

T = Float16
kws = (;
    binary_operators=[-, ^, /, *, +],
    unary_operators=[-, sqrt, cbrt, log, exp],
    variable_names=["b", "c"],
    node_type=Node{T},
)
dexpr = parse_expression(:((b * (-1) - sqrt(b^2 - 4c)) / (2c)); kws...)
batchsize = 10000
points = logsample(dexpr, batchsize; eval_exact=false)
original = Candidate(dexpr, dexpr, points)
candidates = [original]
optifloat!(candidates, points)

splits = T[-100, -10, -1, 0, 1, 10, 100]
feature = 1
rs = infer_regimes(candidates, splits, feature, points)

print_report(rs)
