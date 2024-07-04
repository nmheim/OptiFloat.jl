using BenchmarkTools
using OptiFloat:
    all_subexpressions,
    evaluate_exact,
    accuracy,
    sample_bitpattern,
    ulpdistance,
    biterror,
    lambdify,
    biterrorscore,
    local_biterror,
    @dynexpr,
    evaluate_approx

dexpr, ops, syms = @dynexpr Float16 x + 1 - x
T = Float16
X = reshape(T[5e3 for _ in 1:100], 1, :)
local_biterror(dexpr, ops, X)
d = Dict(e => local_biterror(e, ops, X) for e in all_subexpressions(dexpr))

dexpr, ops, syms = @dynexpr Float16 (b - sqrt(b^2 - 4 * a * c)) / (2 * a)
T = Float16
X = sample_bitpattern(dexpr, ops, T, 3, 1000)
evaluate_exact(dexpr, ops, X)
isnan.(dexpr(X, ops)) |> sum
local_biterror(dexpr, ops, X)
d = Dict(e => local_biterror(e, ops, X) for e in all_subexpressions(dexpr))

#include("plots.jl")
#f(a,b,c) = (-b - sqrt(b^2 - 4*a*c)) / (2*a)
#
#expr = :((-b - sqrt(b^2 - 4*a*c)) / (2*a))
#
## y = accuracy(f, -1.0, 1.0, 1.0)
#@code_warntype evaluate_exact(f, -1.0, 1.0, 1.0)
#@btime evaluate_exact(f, -1.0, 1.0, 1.0)
#
#point = (; a=-1.0, b=1.0, c=1.0)
#@code_warntype lambdify(expr, keys(point)...)(values(point)...)
#@btime lambdify(expr, keys(point)...)(values(point)...)
#@btime evaluate_exact(expr, point)

# dexpr, ops, syms = @dynexpr Interval{BigFloat} (b - sqrt(b^2 - 4*a*c)) / (2*a)
# T = Interval{BigFloat}
# 
# X = reshape(Float16[1.0, -1.0, 1.0], 3, 1)
# evaluate_exact(dexpr, ops, X)
# 
# using DynamicExpressions
# operators = OperatorEnum(; binary_operators=[+, -, *, ^, /], unary_operators=[sqrt])
# a = Node{T}(feature=1)
# b = Node{T}(feature=2)
# c = Node{T}(feature=3)
# expression = (b - sqrt(b^2 - 4*a*c)) #/ (2*a)
# expression = a + 1 - a
# x = reshape(T[5e3 for _ in 1:100], 1, :)
# x = -ones(T, 1, 100) .* 100
# y = ones(T, 1, 100)
# z = ones(T, 1, 100)
# X = cat(x,y,z,dims=1)
# expression(X, operators)
# @btime expression($X, $operators)
# local_biterror(expression, operators, X)
# 
# f() = Dict(e => local_biterror(e,operators,X) for e in all_subexpressions(expression))
# @btime f()
# 
# @code_warntype evaluate_exact(expr, point)
# @code_warntype biterror(f, -1.0, 1.0, 1.0)
# @code_warntype biterror.(f, -ones(2), ones(2), ones(2))
# 
# @code_warntype biterror(expr)
# 
# T = Float64
# batchsize = 100
# 
# as = sort(sample_bitpattern(T, 300))
# ys = map(as) do a
#     batch = (;
#         a = sample_bitpattern(T, batchsize),
#         b = T[a for _ in 1:batchsize],
#         c = sample_bitpattern(T, batchsize),
#     )
#     biterrorscore.(f, values(batch)...)
#     #median(filter(isfinite, accs))
# end
# 
# plot_accuracy(as, ys)
