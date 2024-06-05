using Plots
using OptiFloat: all_subexpressions, local_error, evaluate_exact, accuracy, sample_bitpattern
using Statistics: mean

f(a,b,c) = (-b - sqrt(b^2 - 4*a*c)) / (2*a)

stop = 1e3
step = stop/100
start = -stop
T = Float16

as = map(start:step:stop) do a
    batch = (;
        a = T[a for _ in 1:256],
        b = sample_bitpattern(T, 256),
        c = sample_bitpattern(T, 256),
    )
    mean(mean.(accuracy.(f, values(batch)...)))
end
