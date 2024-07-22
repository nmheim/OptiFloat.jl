using DynamicExpressions: parse_expression
using OptiFloat:
    evaluate_exact, evaluate_approx, sample_bitpattern, logsample, ulpdistance, biterror

T = Float16
f(x) = sqrt(x + 1) - sqrt(x)
(e1, _) = parse_expression(T, :(sqrt(x + 1) - sqrt(x)))
(e2, _) = parse_expression(T, :(1 / (sqrt(x + 1) + sqrt(x))))

xs = sort(logsample(e1, 5000; eval_exact=true); dims=2)
ys =
    let
        using Makie, CairoMakie
        fig = Figure()
        a1 = Axis(fig[1, 1]; xscale=log10)
        a2 = Axis(fig[2, 1]; xscale=log10)
        lines!(a1, vec(xs), evaluate_approx(e1, xs); label="sqrt(x+1)-sqrt(x)")
        #lines!(a1, vec(xs), evaluate_exact.(T, f, vec(xs)), label="exact")
        lines!(a1, vec(xs), evaluate_exact(e1, xs); label="exact")
        lines!(a1, vec(xs), evaluate_approx(e2, xs); label="1/(sqrt(x+1)+sqrt(x))")
        axislegend(a1)
        lines!(a2, vec(xs), biterror(e1, e1, xs; accum=identity))
        lines!(a2, vec(xs), biterror(e2, e1, xs; accum=identity))
        fig
    end
