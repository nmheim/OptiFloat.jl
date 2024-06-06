using OptiFloat: all_subexpressions, local_error, evaluate_exact, accuracy, sample_bitpattern
using Statistics: mean

include("plots.jl")

f(x) = x+1-x

T = Float16
batchsize = 200
xs = sort(sample_bitpattern(T,300))
ys = map(xs) do x
    batch = (;
        x = T[x for _ in 1:batchsize],
    )
    accuracy.(f, values(batch)...)
end

plot_accuracy(xs, ys)
