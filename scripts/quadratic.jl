using Metatheory
using Metatheory.Rewriters
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
    local_biterrors

# FIXME: figure out why we can get Inf errors
# FIXME: figure out why we can get DomainError in error with logsample(..., eval_exact=false)

T = Float16
orig_expr = :((-b - sqrt(b^2 - 4 * c)) / (2 * c))
kws = (;
    binary_operators=[-, ^, /, *, +],
    unary_operators=[-, sqrt],
    node_type=Node{T},
    variable_names=["b", "c"],
)
dexpr = parse_expression(orig_expr; kws...)
points = sample_bitpattern(dexpr, T, 2, 8000)
# points = logsample(dexpr, T, 2, 8000)
candidates = [Candidate(dexpr, dexpr, points)]
optifloat!(candidates, points)
