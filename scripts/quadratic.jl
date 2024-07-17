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
    local_biterrors,
    optifloat!

# FIXME: sort vector of candidates by mean error

T = Float16
#neg(x) = -x
#Base.sqrt(x::Array) = sqrt.(x)
#Base.:^(x::Array, n) = x .^ n
ops = OperatorEnum(; binary_operators=[-, ^, /, *, +], unary_operators=[-, sqrt, cbrt, log, exp])
#ops = GenericOperatorEnum(; binary_operators=[-, ^, /, *, +], unary_operators=[neg, sqrt])
#@extend_operators ops
kws = (; operators=ops, variable_names=["b", "c"])
b = Node{T}(; feature=1)
c = Node{T}(; feature=2)
dexpr = Expression((-1b - sqrt(b^2 - 4c)) / (2c); kws...)
#dexpr = Expression(neg(b) - sqrt(b - 4 * c); kws...)
#dexpr = Expression(sqrt(b+c)^2; kws...)
#dexpr(rand(2,5))
#kws = (;
#    binary_operators=[-, ^, /, *, +],
#    unary_operators=[-, sqrt],
#    node_type=Node{T},
#    variable_names=["b", "c"],
#)
#dexpr = parse_expression(orig_expr; kws...)
batchsize = 10000
#points = sample_bitpattern(dexpr, T, 2, batchsize)
points = logsample(dexpr, T, 2, batchsize; eval_exact=false)
#points = logsample(dexpr, T, 2, batchsize, eval_exact=true)
candidates = [Candidate(dexpr, dexpr, points)]
optifloat!(candidates, points)
