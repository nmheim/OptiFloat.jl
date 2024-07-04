using DynamicExpressions
using OptiFloat: sample_bitpattern, evaluate_exact, logsample

T = Float16
orig_expr = :((-b - sqrt(b^2 - (4 * c))) / (2 * c))
candidate = :(2 / (-b + sqrt((b^2.0) - (4.0 * c))))
kws = (;
    variable_names=["c", "b"],
    binary_operators=[-, *, /, ^, +],
    unary_operators=[-, sqrt],
    node_type=Node{T},
)
e1 = parse_expression(orig_expr; kws...)
e2 = parse_expression(candidate; kws...)

#fmax = fill(floatmax(T), 2)
#points = sample_bitpattern(e1, T, 2, 1000)
points = logsample(e2, T, 2, 1000; eval_exact=true)
#points = _sample(e1, T, 2, 1000)

y1 = e1(points; early_exit=false)
y2 = e2(points; early_exit=false)
labels = Int.(y2 .<= y1)

let
    using CairoMakie
    using Makie
    (xp, yp) = eachrow(points)
    f = Figure()
    ax = Axis(f[1, 1]; yscale=Makie.Symlog10(1), xscale=Makie.Symlog10(1))
    scatter!(ax, xp, yp; color=labels)
    f
end
