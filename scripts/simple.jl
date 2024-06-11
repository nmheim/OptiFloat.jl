using OptiFloat: all_subexpressions, local_error, evaluate_exact, accuracy, sample_bitpattern, errorscore, ulpdistance

include("plots.jl")

f(x) = x+1-x
#f(x) = sqrt(x+1)-sqrt(x)
#g(x) = 1/(sqrt(x+1)+sqrt(x))

T = Float16
x = T(4e2)
y_app = f(x)
y_exa = evaluate_exact(f, x)

ulpdistance(convert(T,y_exa), y_app)
ulpdistance(y_app, y_exa)


batchsize = 50
xs = sort(sample_bitpattern(T,300))
ys = map(xs) do x
    batch = (;
        x = T[x for _ in 1:batchsize],
    )
    errorscore.(f, values(batch)...)
end

plot_accuracy(xs, ys)


let
    fig = Figure()
    ax = Axis(fig[1, 1])
    xs = 0:1e3
    lines!(ax, xs, f.(xs))
    lines!(ax, xs, g.(xs))
    fig
end
