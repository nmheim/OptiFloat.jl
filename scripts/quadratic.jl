using BenchmarkTools
using DynamicExpressions
using OptiFloat: all_subexpressions, local_biterror, evaluate_exact, accuracy,
    sample_bitpattern, ulpdistance, biterror, lambdify

include("plots.jl")

f(a,b,c) = (-b - sqrt(b^2 - 4*a*c)) / (2*a)

expr = :((-b - sqrt(b^2 - 4*a*c)) / (2*a))

# y = accuracy(f, -1.0, 1.0, 1.0)
@code_warntype evaluate_exact(f, -1.0, 1.0, 1.0)
@btime evaluate_exact(f, -1.0, 1.0, 1.0)

point = (; a=-1.0, b=1.0, c=1.0)
@code_warntype lambdify(expr, keys(point)...)(values(point)...)
@btime lambdify(expr, keys(point)...)(values(point)...)
@btime evaluate_exact(expr, point)

operators = OperatorEnum(; binary_operators=[+, -, *, ^, /], unary_operators=[sqrt])
a = Node{Float64}(feature=1)
b = Node{Float64}(feature=2)
c = Node{Float64}(feature=3)
expression = (b - sqrt(b^2 - 4*a*c)) / (2*a)
X = reshape([-1.0, 1.0, 1.0], 3, 1)
@btime expression($X, $operators)

@code_warntype evaluate_exact(expr, point)
@code_warntype biterror(f, -1.0, 1.0, 1.0)
@code_warntype biterror.(f, -ones(2), ones(2), ones(2))

@code_warntype biterror(expr)

T = Float64
batchsize = 100

as = sort(sample_bitpattern(T, 300))
ys = map(as) do a
    batch = (;
        a = sample_bitpattern(T, batchsize),
        b = T[a for _ in 1:batchsize],
        c = sample_bitpattern(T, batchsize),
    )
    errorscore.(f, values(batch)...)
    #median(filter(isfinite, accs))
end

plot_accuracy(as, ys)
