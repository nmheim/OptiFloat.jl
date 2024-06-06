using OptiFloat: all_subexpressions, local_error, evaluate_exact, accuracy, sample_bitpattern
using Statistics: mean, median

include("plots.jl")

f(a,b,c) = (-b - sqrt(b^2 - 4*a*c)) / (2*a)

# y = accuracy(f, -1.0, 1.0, 1.0)
# @code_warntype evaluate_exact(f, -1.0, 1.0, 1.0)
# @code_warntype accuracy(f, -1.0, 1.0, 1.0)
# @code_warntype accuracy.(f, -ones(2), ones(2), ones(2))

T = Float64
batchsize = 200

as = sort(sample_bitpattern(T, 300))
ys = map(as) do a
    batch = (;
        a = sample_bitpattern(T, batchsize),
        b = T[a for _ in 1:batchsize],
        c = sample_bitpattern(T, batchsize),
    )
    accs = accuracy.(f, values(batch)...)
    #median(filter(isfinite, accs))
end

plot_accuracy(as, ys)
